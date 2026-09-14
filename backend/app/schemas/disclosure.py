from __future__ import annotations
from datetime import datetime
from typing import Optional, Literal
from pydantic import BaseModel

class DisclosureRequestCreate(BaseModel):
    subject_user_id: str
    justification_category: str
    justification_text: str

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
