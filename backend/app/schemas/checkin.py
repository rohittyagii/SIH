"""Pydantic schemas for wellness check-ins."""
from datetime import date, datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field, field_validator


class CheckinCreate(BaseModel):
    """POST /wellness/checkin — Flutter app submits this."""
    overall_score: int = Field(..., ge=1, le=5)
    sleep_score: int = Field(..., ge=1, le=5)
    physical_score: int = Field(..., ge=1, le=5)
    focus_score: int = Field(..., ge=1, le=5)
    note: Optional[str] = Field(None, max_length=200)


class CheckinBatchItem(BaseModel):
    """Single item for offline batch sync."""
    overall_score: int = Field(..., ge=1, le=5)
    sleep_score: int = Field(..., ge=1, le=5)
    physical_score: int = Field(..., ge=1, le=5)
    focus_score: int = Field(..., ge=1, le=5)
    note: Optional[str] = Field(None, max_length=200)
    checkin_date: date  # The actual date the offline check-in was for


class CheckinBatchCreate(BaseModel):
    """POST /wellness/batch — sync offline check-ins."""
    checkins: list[CheckinBatchItem]


class CheckinResponse(BaseModel):
    id: str
    checkin_date: date
    overall_score: int
    sleep_score: int
    physical_score: int
    focus_score: int
    average_score: float
    risk_level: str
    note: Optional[str] = None
    created_at: datetime

    model_config = {"from_attributes": True}


class TodayStatusResponse(BaseModel):
    done: bool
    checkin: Optional[CheckinResponse] = None


class WellnessHistoryItem(BaseModel):
    """Single item in dashboard-format wellness history (1-10 scale for display)."""
    timestamp: datetime
    self_reported_mood: float       # overall_score * 2 → 1-10
    sleep_score: float              # sleep_score * 2 → 1-10
    subjective_fatigue_level: float # (6 - physical_score) * 2 → inverted 1-10
    hrv_baseline_deviation: float   # from hr_metrics
