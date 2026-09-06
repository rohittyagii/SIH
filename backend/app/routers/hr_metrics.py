"""HR Metrics router — unit summary for web dashboard."""
from fastapi import APIRouter
from sqlalchemy import select, func

from app.dependencies import OfficerOrAbove, DbSession
from app.models.user import User, Unit, UserRole
from app.models.hr_metrics import HRMetrics
from app.models.assessment import AIAssessment
from app.models.checkin import RiskLevel
from app.schemas.personnel import UnitSummary

router = APIRouter(prefix="/hr-metrics", tags=["hr-metrics"])


@router.get("/unit-summary", response_model=list[UnitSummary])
async def unit_summary(_: OfficerOrAbove, db: DbSession):
    """
    Aggregated welfare metrics per unit.
    Consumed by the web dashboard /overview page KPI cards and risk distribution chart.
    """
    # Get all units
    units_res = await db.execute(select(Unit))
    units = units_res.scalars().all()

    summaries = []
    for unit in units:
        # Personnel in this unit
        personnel_res = await db.execute(
            select(User).where(
                User.unit_id == unit.id,
                User.role == UserRole.PERSONNEL,
                User.is_active == True,
            )
        )
        personnel = personnel_res.scalars().all()
        total = len(personnel)
        if total == 0:
            continue

        user_ids = [u.id for u in personnel]

        # Latest assessment per user → determine risk tier
        routine = monitor = intervention = unassessed = 0
        for user in personnel:
            latest_a = await db.execute(
                select(AIAssessment)
                .where(AIAssessment.user_id == user.id)
                .order_by(AIAssessment.created_at.desc())
                .limit(1)
            )
            a = latest_a.scalar_one_or_none()
            if not a:
                unassessed += 1
            elif a.risk_level == RiskLevel.INTERVENTION:
                intervention += 1
            elif a.risk_level == RiskLevel.MONITOR:
                monitor += 1
            else:
                routine += 1

        # HR aggregates
        hr_res = await db.execute(
            select(
                func.avg(HRMetrics.avg_weekly_duty_hours),
                func.avg(HRMetrics.days_since_last_leave),
                func.avg(HRMetrics.avg_mood_score),
            ).where(HRMetrics.user_id.in_(user_ids))
        )
        avg_duty, avg_leave, avg_mood = hr_res.one()

        summaries.append(UnitSummary(
            unit_name=unit.name,
            total_personnel=total,
            routine_count=routine,
            monitor_count=monitor,
            intervention_count=intervention,
            unassessed_count=unassessed,
            avg_duty_hours=round(avg_duty or 48.0, 1),
            avg_days_since_leave=round(avg_leave or 0, 1),
            avg_mood_score=round(avg_mood or 5.0, 1),
        ))

    return summaries
