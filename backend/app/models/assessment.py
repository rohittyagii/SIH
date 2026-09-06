"""SQLAlchemy ORM — AIAssessment (triage workflow state machine)"""
import uuid
import enum
from datetime import datetime, timezone

from sqlalchemy import (
    String, Integer, Float, Text, DateTime,
    Enum as SAEnum, ForeignKey, Boolean,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base
from app.models.checkin import RiskLevel


class AssessmentStatus(str, enum.Enum):
    PENDING = "Pending"
    ACKNOWLEDGED = "Acknowledged"
    ACTION_TAKEN = "Action_Taken"


def utcnow():
    return datetime.now(timezone.utc)


class AIAssessment(Base):
    """
    ML-generated welfare assessment for a soldier.
    Drives the triage queue on the web dashboard.
    State machine: Pending → Acknowledged → Action_Taken
    """
    __tablename__ = "ai_assessments"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Subject of the assessment
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    unit_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("units.id"), nullable=False)

    # ML outputs
    risk_level: Mapped[RiskLevel] = mapped_column(
        SAEnum(RiskLevel, name="risklevel", create_constraint=False),
        nullable=False,
    )
    resilience_score: Mapped[int] = mapped_column(Integer, nullable=False)     # 0–100
    mood_score: Mapped[float] = mapped_column(Float, nullable=False)           # 1–10
    sleep_recovery: Mapped[float] = mapped_column(Float, nullable=False)       # 1–10
    fatigue_level: Mapped[float] = mapped_column(Float, nullable=False)        # 1–10
    hrv_baseline_deviation: Mapped[float] = mapped_column(Float, nullable=False)

    # Human-readable AI outputs
    contributing_factors: Mapped[str] = mapped_column(Text, nullable=False)
    recommended_intervention: Mapped[str] = mapped_column(Text, nullable=False)
    ai_narrative: Mapped[str] = mapped_column(Text, nullable=False)

    # Triage workflow
    status: Mapped[AssessmentStatus] = mapped_column(
        SAEnum(AssessmentStatus, name="assessmentstatus"),
        nullable=False,
        default=AssessmentStatus.PENDING,
    )
    acknowledged_by: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=True
    )
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

    # relationships
    user: Mapped["User"] = relationship("User", back_populates="assessments", foreign_keys=[user_id])  # type: ignore[name-defined]
    unit: Mapped["Unit"] = relationship("Unit")  # type: ignore[name-defined]


class SupportRequest(Base):
    __tablename__ = "support_requests"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    request_type: Mapped[str] = mapped_column(String(30), default="Callback")
    status: Mapped[str] = mapped_column(String(20), default="Pending")
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

    user: Mapped["User"] = relationship("User", back_populates="support_requests")  # type: ignore[name-defined]


class AuditLog(Base):
    __tablename__ = "audit_logs"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    actor_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    action: Mapped[str] = mapped_column(String(100), nullable=False)
    resource_type: Mapped[str] = mapped_column(String(50), nullable=False)
    resource_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    ip_address: Mapped[str | None] = mapped_column(String(45), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

    actor: Mapped["User"] = relationship("User", back_populates="audit_logs")  # type: ignore[name-defined]
