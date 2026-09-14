from __future__ import annotations
"""HR Metrics router — unit summary for web dashboard.

Commanders ARE permitted to see this endpoint (aggregate data only, no individual rows).
The service layer executes queries on a plain DbSession that bypasses RLS intentionally.
"""
from fastapi import APIRouter

from app.dependencies import OfficerOrAbove, DbSession
from app.schemas.personnel import UnitSummary
from app.services import hr_metrics as hr_metrics_service

router = APIRouter(prefix="/hr-metrics", tags=["hr-metrics"])


@router.get("/unit-summary", response_model=list[UnitSummary])
async def unit_summary(_: OfficerOrAbove, db: DbSession):
    """
    Aggregated welfare metrics per unit.
    Safe for Commanders — only totals and averages, never individual soldier rows.
    Delegates to hr_metrics service which uses a plain (non-RLS) session.
    """
    return await hr_metrics_service.get_unit_summary(db)
