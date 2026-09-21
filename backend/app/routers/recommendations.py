from __future__ import annotations
"""Recommendations router — welfare officer → commanding officer escalation."""
import logging
import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select, and_

from app.dependencies import WelfareOnly, OfficerOrAbove, RlsSession
from app.models.user import User, UserRole, Unit
from app.models.assessment import AIAssessment
from app.models.recommendation import CommanderRecommendation, RecommendationStatus
from app.models.disclosure import Notification
from app.schemas.recommendation import (
    CreateRecommendationRequest,
    UpdateRecommendationRequest,
    RecommendationResponse,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/recommendations", tags=["recommendations"])


def _to_response(rec: CommanderRecommendation, wo: User, co: User, soldier: User, unit: Unit) -> RecommendationResponse:
    return RecommendationResponse(
        id=str(rec.id),
        welfare_officer_id=str(rec.welfare_officer_id),
        welfare_officer_name=wo.full_name,
        commander_id=str(rec.commander_id),
        commander_name=co.full_name,
        soldier_id=str(rec.soldier_id),
        soldier_name=soldier.full_name,
        soldier_service_id=soldier.service_id,
        assessment_id=str(rec.assessment_id) if rec.assessment_id else None,
        unit_name=unit.name,
        note=rec.note,
        risk_level=rec.risk_level.value,
        status=rec.status.value,
        commander_response=rec.commander_response,
        created_at=rec.created_at,
        reviewed_at=rec.reviewed_at,
    )


async def _load_recommendation_with_relations(db, rec_id: uuid.UUID):
    """Load a recommendation along with all related user/unit objects."""
    result = await db.execute(
        select(
            CommanderRecommendation,
            User,  # welfare officer
        )
        .join(User, CommanderRecommendation.welfare_officer_id == User.id)
        .where(CommanderRecommendation.id == rec_id)
    )
    row = result.first()
    if not row:
        return None
    rec, wo = row

    # Load commander, soldier, unit separately
    co_res = await db.execute(select(User).where(User.id == rec.commander_id))
    co = co_res.scalar_one()
    soldier_res = await db.execute(select(User).where(User.id == rec.soldier_id))
    soldier = soldier_res.scalar_one()
    unit_res = await db.execute(select(Unit).where(Unit.id == rec.unit_id))
    unit = unit_res.scalar_one()

    return rec, wo, co, soldier, unit


# ── POST /recommendations/ ───────────────────────────────────────────────────

@router.post("/", response_model=RecommendationResponse, status_code=status.HTTP_201_CREATED)
async def create_recommendation(
    body: CreateRecommendationRequest,
    current_user: WelfareOnly,
    db: RlsSession,
):
    """
    Welfare officer recommends a high-risk soldier to the commanding officer.
    The CO is auto-resolved from the soldier's unit.
    """
    # Load the soldier
    soldier_res = await db.execute(select(User).where(User.id == body.soldier_id))
    soldier = soldier_res.scalar_one_or_none()
    if not soldier:
        raise HTTPException(status_code=404, detail="Soldier not found")

    # Find the commanding officer for the soldier's unit
    co_res = await db.execute(
        select(User).where(
            and_(
                User.unit_id == soldier.unit_id,
                User.role == UserRole.COMMANDER,
                User.is_active == True,
            )
        ).limit(1)
    )
    commander = co_res.scalar_one_or_none()
    if not commander:
        raise HTTPException(
            status_code=404,
            detail="No active commanding officer found for this soldier's unit"
        )

    # Load unit for response
    unit_res = await db.execute(select(Unit).where(Unit.id == soldier.unit_id))
    unit = unit_res.scalar_one()

    # Determine risk level from assessment or latest assessment
    risk_level = None
    assessment_id = None

    if body.assessment_id:
        assessment_res = await db.execute(
            select(AIAssessment).where(AIAssessment.id == body.assessment_id)
        )
        assessment = assessment_res.scalar_one_or_none()
        if assessment:
            risk_level = assessment.risk_level
            assessment_id = assessment.id
    
    if risk_level is None:
        # Get the latest assessment for the soldier
        latest_res = await db.execute(
            select(AIAssessment)
            .where(AIAssessment.user_id == soldier.id)
            .order_by(AIAssessment.created_at.desc())
            .limit(1)
        )
        latest = latest_res.scalar_one_or_none()
        if latest:
            risk_level = latest.risk_level
            if not assessment_id:
                assessment_id = latest.id
    
    if risk_level is None:
        from app.models.checkin import RiskLevel
        risk_level = RiskLevel.MONITOR  # Default if no assessment exists

    # Create the recommendation
    rec = CommanderRecommendation(
        id=uuid.uuid4(),
        welfare_officer_id=current_user.id,
        commander_id=commander.id,
        soldier_id=soldier.id,
        assessment_id=assessment_id,
        unit_id=soldier.unit_id,
        note=body.note,
        risk_level=risk_level,
        status=RecommendationStatus.PENDING,
        created_at=datetime.now(timezone.utc),
    )
    db.add(rec)
    await db.flush()

    # Create notification for the commanding officer
    notification = Notification(
        id=uuid.uuid4(),
        user_id=commander.id,
        notification_type="RECOMMENDATION_RECEIVED",
        title="New Welfare Recommendation",
        message=f"{current_user.full_name} has recommended {soldier.full_name} for your attention: {body.note[:100]}",
        related_entity_type="recommendation",
        related_entity_id=str(rec.id),
        is_read=False,
        created_at=datetime.now(timezone.utc),
    )
    db.add(notification)
    await db.flush()

    logger.info(
        "Recommendation created: WO %s → CO %s for soldier %s",
        current_user.id, commander.id, soldier.id,
    )

    return _to_response(rec, current_user, commander, soldier, unit)


# ── GET /recommendations/outgoing ─────────────────────────────────────────────

@router.get("/outgoing", response_model=list[RecommendationResponse])
async def get_outgoing_recommendations(current_user: WelfareOnly, db: RlsSession):
    """List all recommendations sent by the current welfare officer."""
    result = await db.execute(
        select(CommanderRecommendation, User, Unit)
        .join(User, CommanderRecommendation.soldier_id == User.id)
        .join(Unit, CommanderRecommendation.unit_id == Unit.id)
        .where(CommanderRecommendation.welfare_officer_id == current_user.id)
        .order_by(CommanderRecommendation.created_at.desc())
        .limit(50)
    )
    rows = result.all()

    responses = []
    for rec, soldier, unit in rows:
        co_res = await db.execute(select(User).where(User.id == rec.commander_id))
        co = co_res.scalar_one()
        responses.append(_to_response(rec, current_user, co, soldier, unit))

    return responses


# ── GET /recommendations/incoming ─────────────────────────────────────────────

@router.get("/incoming", response_model=list[RecommendationResponse])
async def get_incoming_recommendations(current_user: OfficerOrAbove, db: RlsSession):
    """List all recommendations targeted at the current commander."""
    if current_user.role not in (UserRole.COMMANDER, UserRole.ADMIN):
        raise HTTPException(status_code=403, detail="Only commanders can view incoming recommendations")

    result = await db.execute(
        select(CommanderRecommendation, User, Unit)
        .join(User, CommanderRecommendation.soldier_id == User.id)
        .join(Unit, CommanderRecommendation.unit_id == Unit.id)
        .where(CommanderRecommendation.commander_id == current_user.id)
        .order_by(CommanderRecommendation.created_at.desc())
        .limit(50)
    )
    rows = result.all()

    responses = []
    for rec, soldier, unit in rows:
        wo_res = await db.execute(select(User).where(User.id == rec.welfare_officer_id))
        wo = wo_res.scalar_one()
        responses.append(_to_response(rec, wo, current_user, soldier, unit))

    return responses


# ── PATCH /recommendations/{id} ──────────────────────────────────────────────

@router.patch("/{recommendation_id}", response_model=RecommendationResponse)
async def update_recommendation(
    recommendation_id: str,
    body: UpdateRecommendationRequest,
    current_user: OfficerOrAbove,
    db: RlsSession,
):
    """Commander updates recommendation status to Reviewed or Actioned."""
    if current_user.role not in (UserRole.COMMANDER, UserRole.ADMIN):
        raise HTTPException(status_code=403, detail="Only commanders can update recommendations")

    result = await db.execute(
        select(CommanderRecommendation).where(CommanderRecommendation.id == recommendation_id)
    )
    rec = result.scalar_one_or_none()
    if not rec:
        raise HTTPException(status_code=404, detail="Recommendation not found")

    if rec.commander_id != current_user.id and current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="This recommendation is not addressed to you")

    valid_statuses = {s.value for s in RecommendationStatus}
    if body.status not in valid_statuses:
        raise HTTPException(status_code=400, detail=f"Invalid status. Must be one of: {valid_statuses}")

    rec.status = RecommendationStatus(body.status)
    if body.commander_response:
        rec.commander_response = body.commander_response
    if body.status in ("Reviewed", "Actioned"):
        rec.reviewed_at = datetime.now(timezone.utc)

    await db.flush()

    # Load related objects for response
    loaded = await _load_recommendation_with_relations(db, rec.id)
    if not loaded:
        raise HTTPException(status_code=500, detail="Failed to reload recommendation")
    rec, wo, co, soldier, unit = loaded

    # Notify the welfare officer about the status change
    notification = Notification(
        id=uuid.uuid4(),
        user_id=wo.id,
        notification_type="RECOMMENDATION_UPDATED",
        title=f"Recommendation {body.status}",
        message=f"CO {current_user.full_name} has {body.status.lower()} your recommendation for {soldier.full_name}.",
        related_entity_type="recommendation",
        related_entity_id=str(rec.id),
        is_read=False,
        created_at=datetime.now(timezone.utc),
    )
    db.add(notification)
    await db.flush()

    return _to_response(rec, wo, co, soldier, unit)


# ── GET /recommendations/{id} ────────────────────────────────────────────────

@router.get("/{recommendation_id}", response_model=RecommendationResponse)
async def get_recommendation(
    recommendation_id: str,
    current_user: OfficerOrAbove,
    db: RlsSession,
):
    """Get a single recommendation detail."""
    loaded = await _load_recommendation_with_relations(db, recommendation_id)
    if not loaded:
        raise HTTPException(status_code=404, detail="Recommendation not found")
    rec, wo, co, soldier, unit = loaded

    # Ensure the current user is either the WO who sent it, the CO who received it, or an admin
    if (
        current_user.id != rec.welfare_officer_id
        and current_user.id != rec.commander_id
        and current_user.role != UserRole.ADMIN
    ):
        raise HTTPException(status_code=403, detail="You don't have access to this recommendation")

    return _to_response(rec, wo, co, soldier, unit)
