from __future__ import annotations
"""Personnel router — web dashboard."""
from typing import Optional

from fastapi import APIRouter, Query
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload

from app.dependencies import OfficerOrAbove, DbSession
from app.models.user import User, Unit
from app.models.checkin import WellnessCheckin
from app.models.hr_metrics import HRMetrics
from app.models.assessment import AIAssessment, AssessmentStatus
from app.schemas.personnel import (
    PersonnelListItem, PersonnelDetail,
    PersonnelUser, PersonnelHRMetrics,
    PersonnelWellnessItem, PersonnelAssessmentItem,
)
from app.models.user import UserRole

router = APIRouter(prefix="/personnel", tags=["personnel"])


# ── GET /personnel/ ───────────────────────────────────────────────────────────

@router.get("/", response_model=list[PersonnelListItem])
async def list_personnel(
    _: OfficerOrAbove,
    db: DbSession,
    unit: Optional[str] = Query(None, description="Filter by unit name"),
    limit: int = Query(100, le=500),
    offset: int = Query(0, ge=0),
):
    """List all personnel. Optional unit filter. Officers and above only."""
    q = select(User, Unit, HRMetrics).join(Unit, User.unit_id == Unit.id).outerjoin(
        HRMetrics, HRMetrics.user_id == User.id
    ).where(User.role == UserRole.PERSONNEL, User.is_active == True)

    if unit:
        q = q.where(Unit.name.ilike(f"%{unit}%"))

    q = q.limit(limit).offset(offset)
    result = await db.execute(q)
    rows = result.all()

    items = []
    for user, unit_obj, hr in rows:
        # Get latest assessment risk level
        latest_assessment = await db.execute(
            select(AIAssessment)
            .where(AIAssessment.user_id == user.id)
            .order_by(AIAssessment.created_at.desc())
            .limit(1)
        )
        assessment = latest_assessment.scalar_one_or_none()

        # Get latest checkin date
        latest_checkin = await db.execute(
            select(WellnessCheckin.checkin_date)
            .where(WellnessCheckin.user_id == user.id)
            .order_by(WellnessCheckin.checkin_date.desc())
            .limit(1)
        )
        checkin_date = latest_checkin.scalar_one_or_none()

        items.append(PersonnelListItem(
            id=str(user.id),
            full_name=user.full_name,
            service_id=user.service_id,
            unit=unit_obj.name,
            role=user.role.value,
            risk_level=assessment.risk_level.value if assessment else "Routine",
            resilience_score=assessment.resilience_score if assessment else None,
            avg_weekly_duty_hours=hr.avg_weekly_duty_hours if hr else 48.0,
            days_since_last_leave=hr.days_since_last_leave if hr else 0,
            last_checkin_date=str(checkin_date) if checkin_date else None,
        ))
    return items


# ── GET /personnel/{id} ───────────────────────────────────────────────────────

@router.get("/{personnel_id}", response_model=PersonnelDetail)
async def get_personnel_detail(
    personnel_id: str,
    _: OfficerOrAbove,
    db: DbSession,
):
    """
    Full personnel detail — matches web dashboard expected contract exactly.
    Returns user info, HR metrics, recent wellness history (1-10 scale), and assessments.
    """
    # User + unit
    result = await db.execute(
        select(User, Unit)
        .join(Unit, User.unit_id == Unit.id)
        .where(User.id == personnel_id)
    )
    row = result.first()
    if not row:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Personnel not found")
    user, unit = row

    # HR metrics
    hr_res = await db.execute(select(HRMetrics).where(HRMetrics.user_id == user.id))
    hr = hr_res.scalar_one_or_none()

    # Recent wellness (last 30 checkins → convert to 1-10 scale for dashboard)
    checkins_res = await db.execute(
        select(WellnessCheckin)
        .where(WellnessCheckin.user_id == user.id)
        .order_by(WellnessCheckin.checkin_date.desc())
        .limit(30)
    )
    checkins = checkins_res.scalars().all()

    hrv = hr.hrv_baseline_deviation if hr else 5.0
    recent_wellness = [
        PersonnelWellnessItem(
            timestamp=c.created_at,
            self_reported_mood=round(c.overall_score * 2.0, 1),        # 1-5 → 2-10
            sleep_score=round(c.sleep_score * 2.0, 1),                  # 1-5 → 2-10
            subjective_fatigue_level=round((6 - c.physical_score) * 2.0, 1),  # inverted
            hrv_baseline_deviation=hrv,
        )
        for c in checkins
    ]

    # Assessments (newest first)
    assessments_res = await db.execute(
        select(AIAssessment)
        .where(AIAssessment.user_id == user.id)
        .order_by(AIAssessment.created_at.desc())
        .limit(10)
    )
    assessments = assessments_res.scalars().all()

    return PersonnelDetail(
        user=PersonnelUser(
            id=str(user.id),
            full_name=user.full_name,
            service_id=user.service_id,
            unit=unit.name,
            role=user.role.value,
        ),
        hr_metrics=PersonnelHRMetrics(
            avg_weekly_duty_hours=hr.avg_weekly_duty_hours if hr else 48.0,
            days_since_last_leave=hr.days_since_last_leave if hr else 0,
            deployment_history_months=hr.deployment_history_months if hr else 0,
        ),
        recent_wellness=recent_wellness,
        assessments=[
            PersonnelAssessmentItem(
                assessment_id=str(a.id),
                risk_level=a.risk_level.value,
                contributing_factors=a.contributing_factors,
                recommended_intervention=a.recommended_intervention,
                status=a.status.value,
                created_at=a.created_at,
            )
            for a in assessments
        ],
    )
