from __future__ import annotations
"""
Disclosures router — dual-control data access flow.

Flow:
  1. Welfare Officer A  →  POST /disclosures/               (create request)
  2. Welfare Officer B  →  PATCH /disclosures/{id}/approve  (approve; rejects self-approval)
  3. Welfare Officer A  →  GET /disclosures/{id}/data        (access data within 48h window)
  4. Auto-expiry: status flips to EXPIRED after expires_at passes.

All actions are written to audit_logs.
Target soldier receives a DISCLOSURE_REQUESTED / DISCLOSURE_APPROVED notification.
"""
import uuid
from datetime import datetime, timezone, timedelta
from typing import Optional

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import WelfareOnly, DbSession, CurrentUser
from app.models.disclosure import DisclosureRequest, DisclosureReason, DisclosureStatus
from app.models.notification import Notification, NotificationType
from app.models.assessment import AuditLog, AIAssessment
from app.models.checkin import WellnessCheckin
from app.models.user import User
from app.schemas.disclosure import DisclosureCreate, DisclosureReview, DisclosureResponse

router = APIRouter(prefix="/disclosures", tags=["disclosures"])

DISCLOSURE_TTL_HOURS = 48


# ── Internal helpers ───────────────────────────────────────────────────────────

def _to_response(d: DisclosureRequest) -> DisclosureResponse:
    return DisclosureResponse(
        id=str(d.id),
        requesting_officer_id=str(d.requesting_officer_id),
        approving_officer_id=str(d.approving_officer_id) if d.approving_officer_id else None,
        target_user_id=str(d.target_user_id),
        reason=d.reason.value,
        status=d.status.value,
        scope=d.scope,
        justification=d.justification,
        expires_at=d.expires_at,
        created_at=d.created_at,
        reviewed_at=d.reviewed_at,
    )


async def _create_notification(
    db: AsyncSession,
    user_id: uuid.UUID,
    title: str,
    body: str,
    notif_type: NotificationType,
    related_entity_id: str,
) -> None:
    """Insert a notification row without enforcing RLS (called from welfare session)."""
    notif = Notification(
        id=uuid.uuid4(),
        user_id=user_id,
        title=title,
        body=body,
        notification_type=notif_type,
        related_entity_id=related_entity_id,
        is_read=False,
        created_at=datetime.now(timezone.utc),
    )
    db.add(notif)


async def _write_audit(
    db: AsyncSession,
    actor_id: uuid.UUID,
    action: str,
    resource_type: str,
    resource_id: str,
) -> None:
    log = AuditLog(
        id=uuid.uuid4(),
        actor_id=actor_id,
        action=action,
        resource_type=resource_type,
        resource_id=resource_id,
        created_at=datetime.now(timezone.utc),
    )
    db.add(log)


async def _expire_stale(db: AsyncSession) -> None:
    """Mark approved disclosures whose window has passed as EXPIRED."""
    now = datetime.now(timezone.utc)
    res = await db.execute(
        select(DisclosureRequest).where(
            DisclosureRequest.status == DisclosureStatus.APPROVED,
            DisclosureRequest.expires_at <= now,
        )
    )
    for d in res.scalars().all():
        d.status = DisclosureStatus.EXPIRED


# ── POST /disclosures/ ─────────────────────────────────────────────────────────

@router.post("/", response_model=DisclosureResponse, status_code=status.HTTP_201_CREATED)
async def create_disclosure(
    body: DisclosureCreate,
    current_user: WelfareOnly,
    db: DbSession,
):
    """
    Welfare Officer submits a disclosure request for a target soldier.
    The request enters PENDING state until a *different* welfare officer approves it.
    """
    # Verify target exists and is a Personnel
    target_res = await db.execute(select(User).where(User.id == body.target_user_id, User.is_active == True))
    target = target_res.scalar_one_or_none()
    if not target:
        raise HTTPException(status_code=404, detail="Target personnel not found")

    disclosure = DisclosureRequest(
        id=uuid.uuid4(),
        requesting_officer_id=current_user.id,
        approving_officer_id=None,
        target_user_id=target.id,
        reason=body.reason,
        status=DisclosureStatus.PENDING,
        scope=body.scope,
        justification=body.justification,
        expires_at=None,
        created_at=datetime.now(timezone.utc),
        reviewed_at=None,
    )
    db.add(disclosure)
    await db.flush()

    # Audit log
    await _write_audit(db, current_user.id, "DISCLOSURE_REQUESTED", "disclosure_requests", str(disclosure.id))

    # Notify the target soldier their data was requested
    await _create_notification(
        db,
        target.id,
        title="Data Disclosure Requested",
        body=(
            f"A welfare officer has requested access to your wellness data "
            f"(reason: {body.reason.value}). A second officer must approve this request."
        ),
        notif_type=NotificationType.DISCLOSURE_REQUESTED,
        related_entity_id=str(disclosure.id),
    )

    # Notify all welfare officers (excluding requester) that a request needs review
    officers_res = await db.execute(
        select(User).where(
            User.role == User.role,  # will filter below
            User.is_active == True,
            User.id != current_user.id,
        )
    )
    from app.models.user import UserRole
    officers_res = await db.execute(
        select(User).where(
            User.role == UserRole.WELFARE_OFFICER,
            User.is_active == True,
            User.id != current_user.id,
        )
    )
    for officer in officers_res.scalars().all():
        await _create_notification(
            db,
            officer.id,
            title="Disclosure Approval Required",
            body=(
                f"{current_user.full_name} has requested data disclosure for "
                f"{target.full_name} (reason: {body.reason.value}). "
                "Your review is required."
            ),
            notif_type=NotificationType.DISCLOSURE_REQUESTED,
            related_entity_id=str(disclosure.id),
        )

    return _to_response(disclosure)


# ── GET /disclosures/ ──────────────────────────────────────────────────────────

@router.get("/", response_model=list[DisclosureResponse])
async def list_disclosures(
    current_user: WelfareOnly,
    db: DbSession,
    filter_status: Optional[str] = Query(None, alias="status"),
    limit: int = Query(50, le=200),
    offset: int = Query(0, ge=0),
):
    """
    List disclosure requests relevant to the current welfare officer:
    - Requests they initiated
    - PENDING requests awaiting their approval
    """
    await _expire_stale(db)

    from app.models.user import UserRole
    q = select(DisclosureRequest).where(
        (DisclosureRequest.requesting_officer_id == current_user.id) |
        (
            (DisclosureRequest.status == DisclosureStatus.PENDING) &
            (DisclosureRequest.requesting_officer_id != current_user.id)
        )
    )
    if filter_status:
        try:
            q = q.where(DisclosureRequest.status == DisclosureStatus(filter_status.upper()))
        except ValueError:
            raise HTTPException(status_code=400, detail=f"Invalid status: {filter_status}")

    q = q.order_by(DisclosureRequest.created_at.desc()).limit(limit).offset(offset)
    result = await db.execute(q)
    return [_to_response(d) for d in result.scalars().all()]


# ── PATCH /disclosures/{id}/approve ───────────────────────────────────────────

@router.patch("/{disclosure_id}/approve", response_model=DisclosureResponse)
async def approve_disclosure(
    disclosure_id: str,
    body: DisclosureReview,
    current_user: WelfareOnly,
    db: DbSession,
):
    """
    Approve a PENDING disclosure request.
    Self-approval (initiator == approver) is rejected with 403.
    Sets expires_at = now + 48 hours.
    """
    await _expire_stale(db)

    res = await db.execute(select(DisclosureRequest).where(DisclosureRequest.id == disclosure_id))
    disclosure = res.scalar_one_or_none()
    if not disclosure:
        raise HTTPException(status_code=404, detail="Disclosure request not found")
    if disclosure.status != DisclosureStatus.PENDING:
        raise HTTPException(status_code=409, detail=f"Cannot approve a request with status '{disclosure.status.value}'")

    # ── CORE SECURITY CHECK: reject self-approval ─────────────────────────────
    if disclosure.requesting_officer_id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Self-approval is not permitted. A different welfare officer must approve this request.",
        )

    now = datetime.now(timezone.utc)
    disclosure.status = DisclosureStatus.APPROVED
    disclosure.approving_officer_id = current_user.id
    disclosure.expires_at = now + timedelta(hours=DISCLOSURE_TTL_HOURS)
    disclosure.reviewed_at = now

    await _write_audit(db, current_user.id, "DISCLOSURE_APPROVED", "disclosure_requests", disclosure_id)

    # Notify the target soldier that their data was approved for disclosure
    await _create_notification(
        db,
        disclosure.target_user_id,
        title="Data Disclosure Approved",
        body=(
            f"Your wellness data has been approved for disclosure "
            f"(reason: {disclosure.reason.value}). "
            f"Access expires in {DISCLOSURE_TTL_HOURS} hours."
        ),
        notif_type=NotificationType.DISCLOSURE_APPROVED,
        related_entity_id=disclosure_id,
    )

    # Notify the requesting officer that their request was approved
    await _create_notification(
        db,
        disclosure.requesting_officer_id,
        title="Disclosure Request Approved",
        body=(
            f"Your disclosure request has been approved by {current_user.full_name}. "
            f"Access window: {DISCLOSURE_TTL_HOURS} hours."
        ),
        notif_type=NotificationType.DISCLOSURE_APPROVED,
        related_entity_id=disclosure_id,
    )

    return _to_response(disclosure)


# ── PATCH /disclosures/{id}/deny ──────────────────────────────────────────────

@router.patch("/{disclosure_id}/deny", response_model=DisclosureResponse)
async def deny_disclosure(
    disclosure_id: str,
    body: DisclosureReview,
    current_user: WelfareOnly,
    db: DbSession,
):
    """Deny a PENDING disclosure request."""
    await _expire_stale(db)

    res = await db.execute(select(DisclosureRequest).where(DisclosureRequest.id == disclosure_id))
    disclosure = res.scalar_one_or_none()
    if not disclosure:
        raise HTTPException(status_code=404, detail="Disclosure request not found")
    if disclosure.status != DisclosureStatus.PENDING:
        raise HTTPException(status_code=409, detail=f"Cannot deny a request with status '{disclosure.status.value}'")

    # Requester can withdraw their own request; another officer can formally deny
    # (no self-approval issue here — deny is always safe)
    now = datetime.now(timezone.utc)
    disclosure.status = DisclosureStatus.DENIED
    disclosure.approving_officer_id = current_user.id
    disclosure.reviewed_at = now

    await _write_audit(db, current_user.id, "DISCLOSURE_DENIED", "disclosure_requests", disclosure_id)

    # Notify the target soldier
    await _create_notification(
        db,
        disclosure.target_user_id,
        title="Data Disclosure Denied",
        body=f"A disclosure request for your data (reason: {disclosure.reason.value}) was denied.",
        notif_type=NotificationType.DISCLOSURE_DENIED,
        related_entity_id=disclosure_id,
    )

    # Notify the requester
    await _create_notification(
        db,
        disclosure.requesting_officer_id,
        title="Disclosure Request Denied",
        body=f"Your disclosure request for {disclosure.reason.value} was denied by {current_user.full_name}.",
        notif_type=NotificationType.DISCLOSURE_DENIED,
        related_entity_id=disclosure_id,
    )

    return _to_response(disclosure)


# ── GET /disclosures/{id}/data ─────────────────────────────────────────────────

@router.get("/{disclosure_id}/data")
async def get_disclosed_data(
    disclosure_id: str,
    current_user: WelfareOnly,
    db: DbSession,
):
    """
    Access the scoped data for an APPROVED, non-expired disclosure.
    Only the requesting officer can access the data.
    Returns wellness check-ins and/or assessments based on the approved scope.
    """
    await _expire_stale(db)

    res = await db.execute(select(DisclosureRequest).where(DisclosureRequest.id == disclosure_id))
    disclosure = res.scalar_one_or_none()
    if not disclosure:
        raise HTTPException(status_code=404, detail="Disclosure request not found")

    # Only the officer who requested disclosure can access the data
    if disclosure.requesting_officer_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the requesting officer may access disclosed data")

    if disclosure.status == DisclosureStatus.EXPIRED:
        raise HTTPException(status_code=403, detail="Disclosure access window has expired")
    if disclosure.status != DisclosureStatus.APPROVED:
        raise HTTPException(status_code=403, detail=f"Disclosure is not approved (status: {disclosure.status.value})")
    if disclosure.expires_at and datetime.now(timezone.utc) > disclosure.expires_at:
        disclosure.status = DisclosureStatus.EXPIRED
        raise HTTPException(status_code=403, detail="Disclosure access window has expired")

    await _write_audit(db, current_user.id, "DISCLOSURE_DATA_ACCESSED", "disclosure_requests", disclosure_id)

    # Notify target soldier their data was accessed
    await _create_notification(
        db,
        disclosure.target_user_id,
        title="Your Data Was Accessed",
        body=(
            f"A welfare officer accessed your wellness data under an approved disclosure "
            f"(reason: {disclosure.reason.value})."
        ),
        notif_type=NotificationType.DATA_ACCESSED,
        related_entity_id=disclosure_id,
    )

    scopes = {s.strip() for s in disclosure.scope.split(",")}
    data: dict = {"disclosure_id": disclosure_id, "target_user_id": str(disclosure.target_user_id)}

    if "wellness" in scopes:
        wc_res = await db.execute(
            select(WellnessCheckin)
            .where(WellnessCheckin.user_id == disclosure.target_user_id)
            .order_by(WellnessCheckin.checkin_date.desc())
            .limit(30)
        )
        checkins = wc_res.scalars().all()
        data["wellness_checkins"] = [
            {
                "checkin_date": str(c.checkin_date),
                "overall_score": c.overall_score,
                "sleep_score": c.sleep_score,
                "physical_score": c.physical_score,
                "focus_score": c.focus_score,
                "average_score": c.average_score,
                "risk_level": c.risk_level.value,
                "created_at": c.created_at.isoformat(),
            }
            for c in checkins
        ]

    if "assessments" in scopes:
        aa_res = await db.execute(
            select(AIAssessment)
            .where(AIAssessment.user_id == disclosure.target_user_id)
            .order_by(AIAssessment.created_at.desc())
            .limit(10)
        )
        assessments = aa_res.scalars().all()
        data["assessments"] = [
            {
                "assessment_id": str(a.id),
                "risk_level": a.risk_level.value,
                "resilience_score": a.resilience_score,
                "contributing_factors": a.contributing_factors,
                "recommended_intervention": a.recommended_intervention,
                "ai_narrative": a.ai_narrative,
                "status": a.status.value,
                "created_at": a.created_at.isoformat(),
            }
            for a in assessments
        ]

    return data
