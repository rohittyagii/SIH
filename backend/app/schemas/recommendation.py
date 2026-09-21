from __future__ import annotations
"""Pydantic schemas for commander recommendation endpoints."""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class CreateRecommendationRequest(BaseModel):
    """POST /recommendations/ — welfare officer creates a recommendation."""
    soldier_id: str
    assessment_id: Optional[str] = None
    note: str


class UpdateRecommendationRequest(BaseModel):
    """PATCH /recommendations/{id} — commander updates the status."""
    status: str  # "Reviewed" or "Actioned"
    commander_response: Optional[str] = None


class RecommendationResponse(BaseModel):
    """Full recommendation response with resolved names."""
    id: str
    welfare_officer_id: str
    welfare_officer_name: str
    commander_id: str
    commander_name: str
    soldier_id: str
    soldier_name: str
    soldier_service_id: str
    assessment_id: Optional[str] = None
    unit_name: str
    note: str
    risk_level: str
    status: str
    commander_response: Optional[str] = None
    created_at: datetime
    reviewed_at: Optional[datetime] = None
