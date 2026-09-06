from __future__ import annotations
"""Pydantic schemas for personnel and HR metrics endpoints."""
from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel


# ── Sub-schemas (nested in PersonnelDetail) ───────────────────────────────────

class PersonnelUser(BaseModel):
    id: str
    full_name: str
    service_id: str
    unit: str
    role: str


class PersonnelHRMetrics(BaseModel):
    avg_weekly_duty_hours: float
    days_since_last_leave: int
    deployment_history_months: int


class PersonnelWellnessItem(BaseModel):
    """One entry in recent_wellness — dashboard expects 1-10 scale."""
    timestamp: datetime
    self_reported_mood: float           # overall_score * 2
    sleep_score: float                  # sleep_score * 2
    subjective_fatigue_level: float     # (6 - physical_score) * 2
    hrv_baseline_deviation: float


class PersonnelAssessmentItem(BaseModel):
    assessment_id: str
    risk_level: str
    contributing_factors: str
    recommended_intervention: str
    status: str
    created_at: datetime


# ── Main personnel schemas ─────────────────────────────────────────────────────

class PersonnelListItem(BaseModel):
    """Row in the personnel list table."""
    id: str
    full_name: str
    service_id: str
    unit: str
    role: str
    risk_level: Optional[str] = "Routine"  # from latest assessment
    resilience_score: Optional[int] = None
    avg_weekly_duty_hours: float
    days_since_last_leave: int
    last_checkin_date: Optional[str] = None


class PersonnelDetail(BaseModel):
    """
    Full response for GET /personnel/{id}
    Matches the web dashboard's expected contract exactly.
    """
    user: PersonnelUser
    hr_metrics: PersonnelHRMetrics
    recent_wellness: list[PersonnelWellnessItem]
    assessments: list[PersonnelAssessmentItem]


# ── Unit summary (HR Metrics aggregation) ────────────────────────────────────

class UnitSummary(BaseModel):
    """Response item for GET /hr-metrics/unit-summary"""
    unit_name: str
    total_personnel: int
    routine_count: int
    monitor_count: int
    intervention_count: int
    unassessed_count: int
    avg_duty_hours: float
    avg_days_since_leave: float
    avg_mood_score: float
