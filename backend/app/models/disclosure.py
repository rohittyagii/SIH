from __future__ import annotations
"""SQLAlchemy ORM — DisclosureRequest, Notification"""
import uuid
import enum
from typing import Optional
from datetime import datetime, timezone

from sqlalchemy import (
    String, Boolean, DateTime, Text,
    Enum as SAEnum, ForeignKey,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


def utcnow():
    return datetime.now(timezone.utc)


# ── Enums ─────────────────────────────────────────────────────────────────────

class JustificationCategory(str, enum.Enum):
    IMMINENT_RISK = "IMMINENT_RISK"
    INDIVIDUAL_CONSENT = "INDIVIDUAL_CONSENT"
    OPERATIONAL_NECESSITY = "OPERATIONAL_NECESSITY"
    LEGAL_MANDATE = "LEGAL_MANDATE"


class DisclosureStatus(str, enum.Enum):
    PENDING_INITIATOR = "PENDING_INITIATOR"
    PENDING_APPROVER = "PENDING_APPROVER"
    APPROVED = "APPROVED"
    DENIED = "DENIED"
    EXPIRED = "EXPIRED"


# ── DisclosureRequest ─────────────────────────────────────────────────────────

class DisclosureRequest(Base):
    """
    Dual-control disclosure request. A welfare officer initiates; a
    *different* welfare officer approves. Time-boxed to 48 hours.
    """
    __tablename__ = "disclosure_requests"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Initiating welfare officer
    requesting_officer_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False
    )
    # The soldier whose data may be disclosed
    subject_user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False
    )

    justification_category: Mapped[JustificationCategory] = mapped_column(
        SAEnum(JustificationCategory, name="justificationcategory",
               create_constraint=False,
               values_callable=lambda x: [e.value for e in x]),
        nullable=False,
    )
    justification_text: Mapped[str] = mapped_column(Text, nullable=False)

    # Initiator sign-off timestamp
    initiator_approved_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    # Second approver (must be a different welfare officer)
    approver_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=True
    )
    approver_decided_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    status: Mapped[DisclosureStatus] = mapped_column(
        SAEnum(DisclosureStatus, name="disclosurestatus",
               create_constraint=False,
               values_callable=lambda x: [e.value for e in x]),
        nullable=False,
        default=DisclosureStatus.PENDING_INITIATOR,
    )

    # JSON string describing exactly what was revealed
    disclosed_data_scope: Mapped[str] = mapped_column(Text, nullable=False, default="{}")

    # Access window — set on approval, auto-expires
    expires_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

    # Relationships
    requesting_officer: Mapped["User"] = relationship(  # type: ignore[name-defined]
        "User", foreign_keys=[requesting_officer_id]
    )
    subject: Mapped["User"] = relationship(  # type: ignore[name-defined]
        "User", foreign_keys=[subject_user_id]
    )
    approver: Mapped[Optional["User"]] = relationship(  # type: ignore[name-defined]
        "User", foreign_keys=[approver_id]
    )


# ── Notification ──────────────────────────────────────────────────────────────

class Notification(Base):
    """
    In-app notification. All authenticated users (Personnel, Welfare, Commander)
    can view their own notifications. RLS policy enforces user_id scoping.
    """
    __tablename__ = "notifications"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False
    )

    notification_type: Mapped[str] = mapped_column(String(50), nullable=False)
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    message: Mapped[str] = mapped_column(Text, nullable=False)

    # Optional link to a related entity
    related_entity_type: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    related_entity_id: Mapped[Optional[str]] = mapped_column(String(36), nullable=True)

    is_read: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

    # Relationships
    user: Mapped["User"] = relationship("User")  # type: ignore[name-defined]
