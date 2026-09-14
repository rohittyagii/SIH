from __future__ import annotations
"""
HR Metrics service — aggregate queries that Commanders are permitted to see.

Commanders are blocked from individual rows via PostgreSQL RLS (app_commander role
has no policy on wellness_checkins or ai_assessments). However, they ARE allowed
to see unit-level aggregate summaries, which don't expose any individual's data.

This service runs its aggregate queries using a raw connection that bypasses RLS
(no SET LOCAL ROLE is executed), so the queries run as the superuser/connection
owner who can see everything. The service ONLY returns aggregate/summary data,
never individual rows — this is the security boundary.
"""
from typing import Sequence

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User, Unit, UserRole
from app.models.hr_metrics import HRMetrics
from app.models.assessment import AIAssessment
from app.models.checkin import RiskLevel
from app.schemas.personnel import UnitSummary


async def get_unit_summary(db: AsyncSession) -> list[UnitSummary]:
    """
    Return aggregated welfare metrics per unit.
    Safe for Commanders: only unit-level totals, no individual data exposed.

    Uses the plain DbSession (no RLS role injection), so it bypasses
    any RLS policies — intentional for aggregate access.
    """
    units_res = await db.execute(select(Unit))
    units: Sequence[Unit] = units_res.scalars().all()

    summaries: list[UnitSummary] = []

    for unit in units:
        # Count active personnel in this unit
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

        # Latest assessment risk tier per user
        routine = monitor = intervention = unassessed = 0
        for user in personnel:
            latest_a_res = await db.execute(
                select(AIAssessment)
                .where(AIAssessment.user_id == user.id)
                .order_by(AIAssessment.created_at.desc())
                .limit(1)
            )
            a = latest_a_res.scalar_one_or_none()
            if not a:
                unassessed += 1
            elif a.risk_level == RiskLevel.INTERVENTION:
                intervention += 1
            elif a.risk_level == RiskLevel.MONITOR:
                monitor += 1
            else:
                routine += 1

        # HR metric aggregates (averages across the unit)
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
