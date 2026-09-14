from __future__ import annotations
"""Disclosure request model — dual-control data sharing between welfare officers."""
import enum
from datetime import datetime
from typing import Optional

from sqlalchemy import (
    Column, String, Text, Enum as SAEnum,
    ForeignKey, Boolean, DateTime,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.database import Base


class DisclosureReason(str, enum.Enum):
    IMMINENT_RISK      = "IMMINENT_RISK"
    WELFARE_CONCERN    = "WELFARE_CONCERN"
    INVESTIGATION      = "INVESTIGATION"
    MEDICAL_EMERGENCY  = "MEDICAL_EMERGENCY"


class DisclosureStatus(str, enum.Enum):
    PENDING  = "PENDING"
    APPROVED = "APPROVED"
    DENIED   = "DENIED"
    EXPIRED  = "EXPIRED"


class DisclosureRequest(Base):
    """
    Dual-control mechanism: a welfare officer requests access to a soldier's
    individual data (e.g., wellness check-ins, assessments). A *different*
    welfare officer must approve. Self-approval is rejected at the API layer.
    Access expires automatically 48 hours after approval.
    """
    __tablename__ = "disclosure_requests"

    id                    = Column(UUID(as_uuid=True), primary_key=True)
    requesting_officer_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    approving_officer_id  = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    target_user_id        = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    reason                = Column(SAEnum(DisclosureReason, name="disclosurereason"), nullable=False)
    status                = Column(
        SAEnum(DisclosureStatus, name="disclosurestatus"),
        nullable=False,
        default=DisclosureStatus.PENDING,
    )
    # Comma-separated data scopes: 'wellness', 'assessments', 'support'
    scope                 = Column(String(120), nullable=False, default="wellness,assessments")
    justification         = Column(Text, nullable=True)
    expires_at            = Column(DateTime(timezone=True), nullable=True)
    created_at            = Column(DateTime(timezone=True), nullable=False)
    reviewed_at           = Column(DateTime(timezone=True), nullable=True)

    # Relationships
    requesting_officer = relationship("User", foreign_keys=[requesting_officer_id])
    approving_officer  = relationship("User", foreign_keys=[approving_officer_id])
    target_user        = relationship("User", foreign_keys=[target_user_id])
