from __future__ import annotations
from typing import Optional
"""SQLAlchemy ORM — CommanderRecommendation (welfare officer → CO escalation)"""
import uuid
import enum
from datetime import datetime, timezone

from sqlalchemy import (
    String, Text, DateTime,
    Enum as SAEnum, ForeignKey,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base
from app.models.checkin import RiskLevel


class RecommendationStatus(str, enum.Enum):
    PENDING = "Pending"
    REVIEWED = "Reviewed"
    ACTIONED = "Actioned"


def utcnow():
    return datetime.now(timezone.utc)


class CommanderRecommendation(Base):
    """
    A welfare officer recommends a high-risk soldier to the commanding officer.
    State machine: Pending → Reviewed → Actioned
    """
    __tablename__ = "commander_recommendations"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Who recommended
    welfare_officer_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False
    )
    # Target commanding officer (auto-resolved from the soldier's unit)
    commander_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False
    )
    # The soldier being recommended
    soldier_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False
    )
    # Linked AI assessment (optional)
    assessment_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("ai_assessments.id"), nullable=True
    )
    # Unit context
    unit_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("units.id"), nullable=False
    )

    # Welfare officer's written note / justification
    note: Mapped[str] = mapped_column(Text, nullable=False)

    # Soldier's risk level at the time of recommendation
    risk_level: Mapped[RiskLevel] = mapped_column(
        SAEnum(RiskLevel, name="risklevel", create_constraint=False,
               values_callable=lambda x: [e.value for e in x]),
        nullable=False,
    )

    # Workflow status
    status: Mapped[RecommendationStatus] = mapped_column(
        SAEnum(RecommendationStatus, name="recommendationstatus",
               values_callable=lambda x: [e.value for e in x]),
        nullable=False,
        default=RecommendationStatus.PENDING,
    )

    # Commander's response note (optional)
    commander_response: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    reviewed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)

    # Relationships
    welfare_officer: Mapped["User"] = relationship("User", foreign_keys=[welfare_officer_id])  # type: ignore[name-defined]
    commander: Mapped["User"] = relationship("User", foreign_keys=[commander_id])  # type: ignore[name-defined]
    soldier: Mapped["User"] = relationship("User", foreign_keys=[soldier_id])  # type: ignore[name-defined]
    assessment: Mapped[Optional["AIAssessment"]] = relationship("AIAssessment")  # type: ignore[name-defined]
    unit: Mapped["Unit"] = relationship("Unit")  # type: ignore[name-defined]
