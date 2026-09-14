from __future__ import annotations
import uuid
from datetime import datetime, timezone, timedelta
from typing import Optional

from fastapi import APIRouter, HTTPException, Query
from sqlalchemy import select

from app.dependencies import WelfareOnly, RlsSession
from app.models.disclosure import DisclosureRequest, Notification, JustificationCategory, DisclosureStatus
from app.models.assessment import AuditLog, AIAssessment
from app.models.user import User, Unit, UserRole
from app.schemas.disclosure import (
    DisclosureRequestCreate, DisclosureRequestResponse, DisclosureApproval, DisclosedDataResponse
)

router = APIRouter(prefix="/disclosures", tags=["disclosures"])

@router.post("/", response_model=DisclosureRequestResponse, status_code=201)
async def create_disclosure(
    payload: DisclosureRequestCreate,
    current_user: WelfareOnly,
    db: RlsSession,
):
    justification_cat = payload.get_justification_category()
    if justification_cat == JustificationCategory.LEGAL_MANDATE.value:
        raise HTTPException(
            status_code=422,
            detail="LEGAL_MANDATE disclosures require manual review by legal and mental-health professionals. This category is not yet wired to automated processing. Contact your system administrator."
        )

    req = DisclosureRequest(
        requesting_officer_id=current_user.id,
        subject_user_id=uuid.UUID(payload.get_subject_user_id()),
        justification_category=JustificationCategory(justification_cat),
        justification_text=payload.get_justification_text(),
        status=DisclosureStatus.PENDING_INITIATOR,
    )
    db.add(req)
    await db.flush()
    await db.refresh(req)

    return DisclosureRequestResponse(
        id=str(req.id),
        requesting_officer_id=str(req.requesting_officer_id),
        subject_user_id=str(req.subject_user_id),
        justification_category=req.justification_category.value,
        justification_text=req.justification_text,
        initiator_approved_at=req.initiator_approved_at,
        approver_id=str(req.approver_id) if req.approver_id else None,
        approver_decided_at=req.approver_decided_at,
        status=req.status.value,
        expires_at=req.expires_at,
        created_at=req.created_at,
    )

@router.post("/{id}/initiate", response_model=DisclosureRequestResponse)
async def initiate_disclosure(
    id: str,
    current_user: WelfareOnly,
    db: RlsSession,
):
    req_uuid = uuid.UUID(id)
    res = await db.execute(select(DisclosureRequest).where(DisclosureRequest.id == req_uuid))
    req = res.scalar_one_or_none()
    if not req:
        raise HTTPException(status_code=404, detail="Disclosure request not found")
        
    if req.requesting_officer_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the requesting officer can initiate")
        
    req.initiator_approved_at = datetime.now(timezone.utc)
    req.status = DisclosureStatus.PENDING_APPROVER
    
    # Notify other welfare officers
    welfare_officers_res = await db.execute(
        select(User).where(
            User.role == UserRole.WELFARE_OFFICER,
            User.unit_id == current_user.unit_id,
            User.id != current_user.id
        )
    )
    welfare_officers = welfare_officers_res.scalars().all()
    
    for officer in welfare_officers:
        notification = Notification(
            user_id=officer.id,
            notification_type="DISCLOSURE_REVIEW",
            title="Disclosure Request Review",
            message=f"A new disclosure request from {current_user.full_name} needs your review.",
            related_entity_type="disclosure_request",
            related_entity_id=str(req.id)
        )
        db.add(notification)
        
    await db.flush()
    await db.refresh(req)
    
    return DisclosureRequestResponse(
        id=str(req.id),
        requesting_officer_id=str(req.requesting_officer_id),
        subject_user_id=str(req.subject_user_id),
        justification_category=req.justification_category.value,
        justification_text=req.justification_text,
        initiator_approved_at=req.initiator_approved_at,
        approver_id=str(req.approver_id) if req.approver_id else None,
        approver_decided_at=req.approver_decided_at,
        status=req.status.value,
        expires_at=req.expires_at,
        created_at=req.created_at,
    )

@router.patch("/{id}/approve", response_model=DisclosureRequestResponse)
async def approve_disclosure(
    id: str,
    current_user: WelfareOnly,
    db: RlsSession,
):
    req_uuid = uuid.UUID(id)
    res = await db.execute(select(DisclosureRequest).where(DisclosureRequest.id == req_uuid))
    req = res.scalar_one_or_none()
    if not req:
        raise HTTPException(status_code=404, detail="Disclosure request not found")

    if req.requesting_officer_id == current_user.id:
        raise HTTPException(status_code=403, detail="Self-approval is not permitted. A different welfare officer must approve this request.")
        
    req.approver_id = current_user.id
    req.approver_decided_at = datetime.now(timezone.utc)
    req.status = DisclosureStatus.APPROVED
    req.expires_at = datetime.now(timezone.utc) + timedelta(hours=48)
    
    # Audit log
    audit_log = AuditLog(
        actor_id=current_user.id,
        action="DISCLOSURE_APPROVED",
        resource_type="disclosure_request",
        resource_id=str(req.id),
        justification_category=req.justification_category.value,
        initiator_id=req.requesting_officer_id,
        approver_id=current_user.id,
        disclosure_request_id=req.id,
    )
    db.add(audit_log)
    
    # Notify soldier
    subject = await db.get(User, req.subject_user_id)
    initiator = await db.get(User, req.requesting_officer_id)
    
    if subject and initiator:
        notification = Notification(
            user_id=subject.id,
            notification_type="DISCLOSURE_NOTICE",
            title="Data Disclosure Notice",
            message=f"Your data was disclosed for {req.justification_category.value} by {initiator.username}.",
            related_entity_type="disclosure_request",
            related_entity_id=str(req.id)
        )
        db.add(notification)
    
    await db.flush()
    await db.refresh(req)
    
    return DisclosureRequestResponse(
        id=str(req.id),
        requesting_officer_id=str(req.requesting_officer_id),
        subject_user_id=str(req.subject_user_id),
        justification_category=req.justification_category.value,
        justification_text=req.justification_text,
        initiator_approved_at=req.initiator_approved_at,
        approver_id=str(req.approver_id) if req.approver_id else None,
        approver_decided_at=req.approver_decided_at,
        status=req.status.value,
        expires_at=req.expires_at,
        created_at=req.created_at,
    )

@router.patch("/{id}/deny", response_model=DisclosureRequestResponse)
async def deny_disclosure(
    id: str,
    current_user: WelfareOnly,
    db: RlsSession,
):
    req_uuid = uuid.UUID(id)
    res = await db.execute(select(DisclosureRequest).where(DisclosureRequest.id == req_uuid))
    req = res.scalar_one_or_none()
    if not req:
        raise HTTPException(status_code=404, detail="Disclosure request not found")

    # 409 Conflict if already decided (DENIED, APPROVED, EXPIRED)
    if req.status in (DisclosureStatus.DENIED, DisclosureStatus.APPROVED, DisclosureStatus.EXPIRED):
        raise HTTPException(
            status_code=409,
            detail=f"Cannot deny a disclosure that is already {req.status.value}",
        )

    # Self-denial is allowed as withdrawal — only third-party denial is blocked for non-initiators.
    # (Initiators may withdraw their own requests; a different officer may deny as a rejection.)
    req.approver_id = current_user.id
    req.approver_decided_at = datetime.now(timezone.utc)
    req.status = DisclosureStatus.DENIED

    audit_log = AuditLog(
        actor_id=current_user.id,
        action="DISCLOSURE_DENIED",
        resource_type="disclosure_request",
        resource_id=str(req.id),
        justification_category=req.justification_category.value,
        initiator_id=req.requesting_officer_id,
        approver_id=current_user.id,
        disclosure_request_id=req.id,
    )
    db.add(audit_log)

    await db.flush()
    await db.refresh(req)

    return DisclosureRequestResponse(
        id=str(req.id),
        requesting_officer_id=str(req.requesting_officer_id),
        subject_user_id=str(req.subject_user_id),
        justification_category=req.justification_category.value,
        justification_text=req.justification_text,
        initiator_approved_at=req.initiator_approved_at,
        approver_id=str(req.approver_id) if req.approver_id else None,
        approver_decided_at=req.approver_decided_at,
        status=req.status.value,
        expires_at=req.expires_at,
        created_at=req.created_at,
    )

@router.get("/{id}/data", response_model=DisclosedDataResponse)
async def get_disclosure_data(
    id: str,
    current_user: WelfareOnly,
    db: RlsSession,
):
    req_uuid = uuid.UUID(id)
    res = await db.execute(select(DisclosureRequest).where(DisclosureRequest.id == req_uuid))
    req = res.scalar_one_or_none()
    if not req:
        raise HTTPException(status_code=404, detail="Disclosure request not found")

    if req.status != DisclosureStatus.APPROVED:
        raise HTTPException(status_code=403, detail="Disclosure is not approved")
        
    if req.expires_at and req.expires_at < datetime.now(timezone.utc):
        req.status = DisclosureStatus.EXPIRED
        await db.flush()
        raise HTTPException(status_code=403, detail="Disclosure has expired")
        
    subject = await db.get(User, req.subject_user_id)
    unit = await db.get(Unit, subject.unit_id) if subject.unit_id else None
    
    latest_assessment_res = await db.execute(
        select(AIAssessment)
        .where(AIAssessment.user_id == subject.id)
        .order_by(AIAssessment.created_at.desc())
        .limit(1)
    )
    assessment = latest_assessment_res.scalar_one_or_none()
    
    audit_log = AuditLog(
        actor_id=current_user.id,
        action="DISCLOSURE_DATA_ACCESSED",
        resource_type="disclosure_request",
        resource_id=str(req.id),
        justification_category=req.justification_category.value,
        initiator_id=req.requesting_officer_id,
        approver_id=req.approver_id,
        disclosure_request_id=req.id,
    )
    db.add(audit_log)
    await db.flush()
    
    return DisclosedDataResponse(
        subject_full_name=subject.full_name,
        subject_service_id=subject.service_id,
        subject_unit=unit.name if unit else "Unknown",
        risk_level=assessment.risk_level.value if assessment else "Routine",
        contributing_factors=assessment.contributing_factors if assessment else "",
        recommended_intervention=assessment.recommended_intervention if assessment else ""
    )

@router.get("/", response_model=list[DisclosureRequestResponse])
async def list_disclosures(
    current_user: WelfareOnly,
    db: RlsSession,
    status: Optional[str] = Query(None),
):
    q = select(DisclosureRequest)
    if status:
        q = q.where(DisclosureRequest.status == DisclosureStatus(status))
    
    res = await db.execute(q)
    requests = res.scalars().all()
    
    return [
        DisclosureRequestResponse(
            id=str(req.id),
            requesting_officer_id=str(req.requesting_officer_id),
            subject_user_id=str(req.subject_user_id),
            justification_category=req.justification_category.value,
            justification_text=req.justification_text,
            initiator_approved_at=req.initiator_approved_at,
            approver_id=str(req.approver_id) if req.approver_id else None,
            approver_decided_at=req.approver_decided_at,
            status=req.status.value,
            expires_at=req.expires_at,
            created_at=req.created_at,
        )
        for req in requests
    ]
