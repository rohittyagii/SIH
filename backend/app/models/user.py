"""SQLAlchemy ORM — User, ActivationCode"""
import uuid
import enum
from datetime import datetime, timezone

from sqlalchemy import (
    String, Boolean, DateTime, Enum as SAEnum,
    ForeignKey, Text, UniqueConstraint,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class UserRole(str, enum.Enum):
    PERSONNEL = "Personnel"
    WELFARE_OFFICER = "Welfare_Officer"
    COMMANDER = "Commander"
    ADMIN = "Admin"


def utcnow():
    return datetime.now(timezone.utc)


class Unit(Base):
    __tablename__ = "units"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(120), nullable=False, unique=True)
    parent_unit_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("units.id"), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

    # relationships
    users: Mapped[list["User"]] = relationship("User", back_populates="unit")
    activation_codes: Mapped[list["ActivationCode"]] = relationship(
        "ActivationCode", back_populates="unit"
    )


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Identity — stored as encrypted ciphertext, but unique constraint on plaintext hash
    service_id: Mapped[str] = mapped_column(String(50), nullable=False, unique=True)
    # Callsign / display name (e.g. "Foxtrot-42", "cmd_sharma")
    username: Mapped[str] = mapped_column(String(80), nullable=False, unique=True)
    full_name: Mapped[str] = mapped_column(String(150), nullable=False)

    unit_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("units.id"), nullable=False)

    # Auth
    pin_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    role: Mapped[UserRole] = mapped_column(SAEnum(UserRole, name="userrole"), nullable=False, default=UserRole.PERSONNEL)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    # Consent
    consent_given: Mapped[bool] = mapped_column(Boolean, default=False)
    consent_given_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    # Preferences
    language_pref: Mapped[str] = mapped_column(String(10), default="en-GB")
    theme_dark: Mapped[bool] = mapped_column(Boolean, default=True)
    notif_daily_reminder: Mapped[bool] = mapped_column(Boolean, default=True)
    notif_sync_alerts: Mapped[bool] = mapped_column(Boolean, default=True)
    notif_weekly_summary: Mapped[bool] = mapped_column(Boolean, default=False)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)

    # relationships
    unit: Mapped["Unit"] = relationship("Unit", back_populates="users")
    checkins: Mapped[list["WellnessCheckin"]] = relationship("WellnessCheckin", back_populates="user")
    hr_metrics: Mapped["HRMetrics | None"] = relationship("HRMetrics", back_populates="user", uselist=False)
    assessments: Mapped[list["AIAssessment"]] = relationship(
        "AIAssessment", back_populates="user", foreign_keys="AIAssessment.user_id"
    )
    support_requests: Mapped[list["SupportRequest"]] = relationship("SupportRequest", back_populates="user")
    audit_logs: Mapped[list["AuditLog"]] = relationship("AuditLog", back_populates="actor")


class ActivationCode(Base):
    """8-char codes (XXXX-XXXX) issued by welfare office to onboard personnel."""
    __tablename__ = "activation_codes"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    code: Mapped[str] = mapped_column(String(9), nullable=False, unique=True)  # "ABCD-1234"
    unit_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("units.id"), nullable=False)
    is_used: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    used_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    unit: Mapped["Unit"] = relationship("Unit", back_populates="activation_codes")
