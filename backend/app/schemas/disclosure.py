from __future__ import annotations
"""Pydantic schemas for the disclosure flow."""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, field_validator

from app.models.disclosure import DisclosureReason, DisclosureStatus


# ── Request bodies ─────────────────────────────────────────────────────────────

class DisclosureCreate(BaseModel):
    target_user_id: str
    reason: DisclosureReason
    scope: str = "wellness,assessments"
    justification: Optional[str] = None

    @field_validator("scope")
    @classmethod
    def validate_scope(cls, v: str) -> str:
        allowed = {"wellness", "assessments", "support"}
        parts = {s.strip() for s in v.split(",")}
        invalid = parts - allowed
        if invalid:
            raise ValueError(f"Invalid scope items: {invalid}. Allowed: {allowed}")
        return ",".join(sorted(parts))


class DisclosureReview(BaseModel):
    """Body for approve/deny actions."""
    notes: Optional[str] = None


# ── Response schemas ───────────────────────────────────────────────────────────

class DisclosureResponse(BaseModel):
    id: str
    requesting_officer_id: str
    approving_officer_id: Optional[str]
    target_user_id: str
    reason: str
    status: str
    scope: str
    justification: Optional[str]
    expires_at: Optional[datetime]
    created_at: datetime
    reviewed_at: Optional[datetime]

    model_config = {"from_attributes": True}
