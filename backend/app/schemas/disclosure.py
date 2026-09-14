from __future__ import annotations
from datetime import datetime
from typing import Optional, Literal
from pydantic import BaseModel

class DisclosureRequestCreate(BaseModel):
    model_config = {"populate_by_name": True}

    # Accept both the formal field name and the test-friendly alias
    subject_user_id: Optional[str] = None
    target_user_id: Optional[str] = None   # alias → subject_user_id

    justification_category: Optional[str] = None
    reason: Optional[str] = None           # alias → justification_category

    justification_text: Optional[str] = None
    justification: Optional[str] = None   # alias → justification_text

    def get_subject_user_id(self) -> str:
        v = self.subject_user_id or self.target_user_id
        if not v:
            raise ValueError("subject_user_id (or target_user_id) is required")
        return v

    def get_justification_category(self) -> str:
        v = self.justification_category or self.reason or "WELFARE_CONCERN"
        return v

    def get_justification_text(self) -> str:
        v = self.justification_text or self.justification or ""
        return v

class DisclosureRequestResponse(BaseModel):
    id: str
    requesting_officer_id: str
    subject_user_id: str
    justification_category: str
    justification_text: str
    initiator_approved_at: Optional[datetime] = None
    approver_id: Optional[str] = None
    approver_decided_at: Optional[datetime] = None
    status: str
    expires_at: Optional[datetime] = None
    created_at: datetime

class DisclosureApproval(BaseModel):
    decision: Literal['approve', 'deny']
    notes: Optional[str] = None

class DisclosedDataResponse(BaseModel):
    subject_full_name: str
    subject_service_id: str
    subject_unit: str
    risk_level: str
    contributing_factors: str
    recommended_intervention: str
