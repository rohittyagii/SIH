from __future__ import annotations
"""Assessments router — triage, trends, AI run, and status update."""
import uuid
import random
from datetime import datetime, timedelta, timezone, date

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import select, func, and_

from app.dependencies import OfficerOrAbove, CurrentUser, DbSession
from app.models.user import User, Unit, UserRole
from app.models.checkin import WellnessCheckin, RiskLevel
from app.models.hr_metrics import HRMetrics
from app.models.assessment import AIAssessment, AssessmentStatus
from app.schemas.assessment import (
    AssessmentResponse, TriageEntry, TrendPoint,
    ActionUpdate, RunAssessmentResponse,
)

router = APIRouter(prefix="/assessments", tags=["assessments"])


# ── Helpers ───────────────────────────────────────────────────────────────────

def _compute_resilience(mood: float, sleep: float, fatigue: float) -> int:
    """Dashboard formula: clamp(15, 98, (mood×5) + (sleep×3) − (fatigue×2) + 20)"""
    raw = (mood * 5) + (sleep * 3) - (fatigue * 2) + 20
    return max(15, min(98, round(raw)))


def _classify_risk(avg_score: float, hrv: float, leave_days: int, duty_hours: float) -> RiskLevel:
    if (hrv > 25 and leave_days > 120) or avg_score < 2.0:
        return RiskLevel.INTERVENTION
    if (hrv > 15 and leave_days > 80) or avg_score < 3.0 or duty_hours > 58:
        return RiskLevel.MONITOR
    return RiskLevel.ROUTINE


def _generate_narrative(risk: RiskLevel, hrv: float, duty: float, leave: int, months: int) -> tuple[str, str, str]:
    """Generate contributing factors, recommended intervention, and AI narrative text."""
    if risk == RiskLevel.INTERVENTION:
        factors = f"{leave} days without leave, duty hours {duty:.0f}h/wk, HRV deviation +{hrv:.1f}%"
        intervention = "Immediate leave approval and welfare officer consultation within 48 hours"
        narrative = (
            f"Biometric analysis reveals significant autonomic dysregulation (HRV +{hrv:.1f}%) "
            f"combined with {months} months deployment and {duty:.0f}h/wk duty load. "
            "Immediate welfare intervention is clinically warranted to prevent burnout escalation."
        )
    elif risk == RiskLevel.MONITOR:
        factors = f"Sleep scores declining, HRV deviation {hrv:.1f}%, leave deficit {leave} days"
        intervention = "Schedule welfare check-in within 7 days, monitor for escalation"
        narrative = (
            f"Early stress markers identified. HRV deviation ({hrv:.1f}%) and duty hours "
            f"({duty:.0f}h/wk) suggest emerging strain. Proactive welfare engagement recommended "
            "to prevent escalation."
        )
    else:
        factors = "No significant stress indicators. Wellness scores within normal range."
        intervention = "Continue routine monitoring. No action required."
        narrative = (
            "Personnel demonstrating healthy stress regulation. Wellness indicators are within "
            "expected operational norms. No biometric anomalies detected."
        )
    return factors, intervention, narrative


def _to_assessment_response(a: AIAssessment) -> AssessmentResponse:
    return AssessmentResponse(
        assessment_id=str(a.id),
        user_id=str(a.user_id),
        unit_id=str(a.unit_id),
        risk_level=a.risk_level.value,
        resilience_score=a.resilience_score,
        mood_score=a.mood_score,
        sleep_recovery=a.sleep_recovery,
        fatigue_level=a.fatigue_level,
        hrv_baseline_deviation=a.hrv_baseline_deviation,
        contributing_factors=a.contributing_factors,
        recommended_intervention=a.recommended_intervention,
        ai_narrative=a.ai_narrative,
        status=a.status.value,
        acknowledged_by=str(a.acknowledged_by) if a.acknowledged_by else None,
        resolved_at=a.resolved_at,
        created_at=a.created_at,
    )


# ── GET /assessments/triage ───────────────────────────────────────────────────

@router.get("/triage", response_model=list[TriageEntry])
async def get_triage(_: OfficerOrAbove, db: DbSession):
    """
    Priority-sorted triage queue.
    Order: Intervention_Recommended (1) → Monitor (2) → Routine (3)
    Only shows Pending and Acknowledged entries (not resolved).
    """
    result = await db.execute(
        select(AIAssessment, User, Unit)
        .join(User, AIAssessment.user_id == User.id)
        .join(Unit, AIAssessment.unit_id == Unit.id)
        .where(AIAssessment.status != AssessmentStatus.ACTION_TAKEN)
        .order_by(AIAssessment.created_at.desc())
    )
    rows = result.all()

    # Sort by risk priority
    priority_map = {RiskLevel.INTERVENTION: 1, RiskLevel.MONITOR: 2, RiskLevel.ROUTINE: 3}
    entries = [
        TriageEntry(
            assessment_id=str(a.id),
            user_id=str(a.user_id),
            full_name=user.full_name,
            service_id=user.service_id,
            unit=unit.name,
            risk_level=a.risk_level.value,
            resilience_score=a.resilience_score,
            contributing_factors=a.contributing_factors,
            recommended_intervention=a.recommended_intervention,
            status=a.status.value,
            created_at=a.created_at,
        )
        for a, user, unit in rows
    ]
    entries.sort(key=lambda e: priority_map.get(RiskLevel(e.risk_level), 3))
    return entries


# ── GET /assessments/trends ───────────────────────────────────────────────────

@router.get("/trends", response_model=list[TrendPoint])
async def get_trends(_: OfficerOrAbove, db: DbSession, weeks: int = Query(26, le=52)):
    """
    26-week longitudinal trend data for the dashboard overview chart.
    Returns weekly avg_mood, intervention count, and monitor count.
    """
    points = []
    today = date.today()

    for week_back in range(weeks - 1, -1, -1):
        week_start = today - timedelta(weeks=week_back + 1)
        week_end = today - timedelta(weeks=week_back)

        # Average mood (from wellness checkins in this week)
        mood_res = await db.execute(
            select(func.avg(WellnessCheckin.overall_score * 2))
            .where(
                and_(
                    WellnessCheckin.checkin_date >= week_start,
                    WellnessCheckin.checkin_date < week_end,
                )
            )
        )
        avg_mood = mood_res.scalar_one_or_none() or 5.0

        # Risk counts from assessments created in this week
        interv_res = await db.execute(
            select(func.count(AIAssessment.id))
            .where(
                and_(
                    AIAssessment.created_at >= datetime.combine(week_start, datetime.min.time()).replace(tzinfo=timezone.utc),
                    AIAssessment.created_at < datetime.combine(week_end, datetime.min.time()).replace(tzinfo=timezone.utc),
                    AIAssessment.risk_level == RiskLevel.INTERVENTION,
                )
            )
        )
        intervention_count = interv_res.scalar_one() or 0

        monitor_res = await db.execute(
            select(func.count(AIAssessment.id))
            .where(
                and_(
                    AIAssessment.created_at >= datetime.combine(week_start, datetime.min.time()).replace(tzinfo=timezone.utc),
                    AIAssessment.created_at < datetime.combine(week_end, datetime.min.time()).replace(tzinfo=timezone.utc),
                    AIAssessment.risk_level == RiskLevel.MONITOR,
                )
            )
        )
        monitor_count = monitor_res.scalar_one() or 0

        points.append(TrendPoint(
            date=week_start.isoformat(),
            avg_mood=round(avg_mood, 1),
            intervention=intervention_count,
            monitor=monitor_count,
        ))

    return points


# ── GET /assessments/history/{personnelId} ────────────────────────────────────

@router.get("/history/{personnel_id}", response_model=list[AssessmentResponse])
async def get_assessment_history(personnel_id: str, _: OfficerOrAbove, db: DbSession):
    result = await db.execute(
        select(AIAssessment)
        .where(AIAssessment.user_id == personnel_id)
        .order_by(AIAssessment.created_at.desc())
        .limit(20)
    )
    return [_to_assessment_response(a) for a in result.scalars().all()]


# ── POST /assessments/run/{personnelId} ───────────────────────────────────────

@router.post("/run/{personnel_id}", response_model=RunAssessmentResponse)
async def run_assessment(personnel_id: str, current_user: OfficerOrAbove, db: DbSession):
    """
    Trigger AI assessment for a single soldier.
    Reads check-in history + HR metrics → computes resilience + risk → saves assessment.
    """
    # Load user
    user_res = await db.execute(select(User).where(User.id == personnel_id))
    user = user_res.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="Personnel not found")

    # Load HR metrics
    hr_res = await db.execute(select(HRMetrics).where(HRMetrics.user_id == user.id))
    hr = hr_res.scalar_one_or_none()

    hrv = hr.hrv_baseline_deviation if hr else 5.0
    duty = hr.avg_weekly_duty_hours if hr else 48.0
    leave = hr.days_since_last_leave if hr else 0
    months = hr.deployment_history_months if hr else 0
    mood_raw = hr.avg_mood_score if hr else 5.0
    sleep_raw = hr.avg_sleep_recovery if hr else 5.0
    fatigue_raw = hr.avg_fatigue_level if hr else 5.0

    # Load last 14 checkins for average
    checkins_res = await db.execute(
        select(WellnessCheckin)
        .where(WellnessCheckin.user_id == user.id)
        .order_by(WellnessCheckin.checkin_date.desc())
        .limit(14)
    )
    checkins = checkins_res.scalars().all()
    avg_score = (
        sum(c.average_score for c in checkins) / len(checkins)
        if checkins else 3.0
    )

    risk = _classify_risk(avg_score, hrv, leave, duty)
    resilience = _compute_resilience(mood_raw, sleep_raw, fatigue_raw)
    factors, intervention, narrative = _generate_narrative(risk, hrv, duty, leave, months)

    assessment = AIAssessment(
        id=uuid.uuid4(),
        user_id=user.id,
        unit_id=user.unit_id,
        risk_level=risk,
        resilience_score=resilience,
        mood_score=round(mood_raw, 1),
        sleep_recovery=round(sleep_raw, 1),
        fatigue_level=round(fatigue_raw, 1),
        hrv_baseline_deviation=hrv,
        contributing_factors=factors,
        recommended_intervention=intervention,
        ai_narrative=narrative,
        status=AssessmentStatus.PENDING,
        created_at=datetime.now(timezone.utc),
    )
    db.add(assessment)
    await db.flush()

    return RunAssessmentResponse(
        assessment=_to_assessment_response(assessment),
        message=f"Assessment completed: {risk.value}",
    )


# ── POST /assessments/run-unit ────────────────────────────────────────────────

@router.post("/run-unit", response_model=list[RunAssessmentResponse])
async def run_unit_assessment(
    current_user: OfficerOrAbove,
    db: DbSession,
    unit: str = Query(..., description="Unit name to assess"),
):
    """Trigger AI assessments for all personnel in a unit."""
    unit_res = await db.execute(select(Unit).where(Unit.name.ilike(f"%{unit}%")))
    unit_obj = unit_res.scalar_one_or_none()
    if not unit_obj:
        raise HTTPException(status_code=404, detail=f"Unit '{unit}' not found")

    personnel_res = await db.execute(
        select(User).where(
            User.unit_id == unit_obj.id,
            User.role == UserRole.PERSONNEL,
            User.is_active == True,
        )
    )
    personnel = personnel_res.scalars().all()

    results = []
    for user in personnel:
        # Inline same logic as run_assessment for each user
        hr_res = await db.execute(select(HRMetrics).where(HRMetrics.user_id == user.id))
        hr = hr_res.scalar_one_or_none()

        hrv = hr.hrv_baseline_deviation if hr else 5.0
        duty = hr.avg_weekly_duty_hours if hr else 48.0
        leave = hr.days_since_last_leave if hr else 0
        months = hr.deployment_history_months if hr else 0
        mood_raw = hr.avg_mood_score if hr else 5.0
        sleep_raw = hr.avg_sleep_recovery if hr else 5.0
        fatigue_raw = hr.avg_fatigue_level if hr else 5.0

        checkins_res = await db.execute(
            select(WellnessCheckin)
            .where(WellnessCheckin.user_id == user.id)
            .order_by(WellnessCheckin.checkin_date.desc())
            .limit(14)
        )
        checkins = checkins_res.scalars().all()
        avg_score = sum(c.average_score for c in checkins) / len(checkins) if checkins else 3.0

        risk = _classify_risk(avg_score, hrv, leave, duty)
        resilience = _compute_resilience(mood_raw, sleep_raw, fatigue_raw)
        factors, intervention, narrative = _generate_narrative(risk, hrv, duty, leave, months)

        assessment = AIAssessment(
            id=uuid.uuid4(),
            user_id=user.id,
            unit_id=user.unit_id,
            risk_level=risk,
            resilience_score=resilience,
            mood_score=round(mood_raw, 1),
            sleep_recovery=round(sleep_raw, 1),
            fatigue_level=round(fatigue_raw, 1),
            hrv_baseline_deviation=hrv,
            contributing_factors=factors,
            recommended_intervention=intervention,
            ai_narrative=narrative,
            status=AssessmentStatus.PENDING,
            created_at=datetime.now(timezone.utc),
        )
        db.add(assessment)
        await db.flush()
        results.append(RunAssessmentResponse(
            assessment=_to_assessment_response(assessment),
            message=f"Assessment completed: {risk.value}",
        ))

    return results


# ── PATCH /assessments/{id}/action ───────────────────────────────────────────

@router.patch("/{assessment_id}/action", response_model=AssessmentResponse)
async def update_assessment_action(
    assessment_id: str,
    body: ActionUpdate,
    current_user: OfficerOrAbove,
    db: DbSession,
):
    """
    Update triage workflow status.
    Valid transitions: Pending → Acknowledged → Action_Taken
    """
    result = await db.execute(select(AIAssessment).where(AIAssessment.id == assessment_id))
    assessment = result.scalar_one_or_none()
    if not assessment:
        raise HTTPException(status_code=404, detail="Assessment not found")

    valid_statuses = {s.value for s in AssessmentStatus}
    if body.status not in valid_statuses:
        raise HTTPException(status_code=400, detail=f"Invalid status. Must be one of: {valid_statuses}")

    assessment.status = AssessmentStatus(body.status)
    if body.status in ("Acknowledged", "Action_Taken"):
        assessment.acknowledged_by = current_user.id
    if body.status == "Action_Taken":
        assessment.resolved_at = datetime.now(timezone.utc)

    return _to_assessment_response(assessment)
