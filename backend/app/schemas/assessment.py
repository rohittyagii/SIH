from __future__ import annotations
"""Pydantic schemas for AI assessment endpoints."""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class AssessmentResponse(BaseModel):
    assessment_id: str
    user_id: str
    unit_id: str
    risk_level: str
    resilience_score: int
    mood_score: float
    sleep_recovery: float
    fatigue_level: float
    hrv_baseline_deviation: float
    contributing_factors: str
    recommended_intervention: str
    ai_narrative: str
    status: str
    acknowledged_by: Optional[str] = None
    resolved_at: Optional[datetime] = None
    created_at: datetime


class TriageEntry(BaseModel):
    """
    Entry in the triage queue — includes user info for the dashboard card.
    Priority: Intervention=1, Monitor=2, Routine=3
    """
    assessment_id: str
    user_id: str
    full_name: str
    service_id: str
    unit: str
    risk_level: str
    resilience_score: int
    contributing_factors: str
    recommended_intervention: str
    status: str
    created_at: datetime

    @property
    def priority(self) -> int:
        return {"Intervention_Recommended": 1, "Monitor": 2, "Routine": 3}.get(self.risk_level, 3)


class TrendPoint(BaseModel):
    """One data point for GET /assessments/trends (26-week longitudinal chart)."""
    date: str           # ISO date string
    avg_mood: float     # average mood score (1-10)
    intervention: int   # count of Intervention_Recommended
    monitor: int        # count of Monitor


class ActionUpdate(BaseModel):
    """PATCH /assessments/{id}/action"""
    status: str  # "Acknowledged" or "Action_Taken"


class RunAssessmentResponse(BaseModel):
    """Response for POST /assessments/run/{personnelId}"""
    assessment: AssessmentResponse
    message: str
