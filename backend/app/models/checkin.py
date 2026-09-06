"""SQLAlchemy ORM — WellnessCheckin"""
import uuid
import enum
from datetime import datetime, date, timezone

from sqlalchemy import (
    String, Integer, Float, Date, DateTime,
    Enum as SAEnum, ForeignKey, LargeBinary, UniqueConstraint,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class RiskLevel(str, enum.Enum):
    ROUTINE = "Routine"
    MONITOR = "Monitor"
    INTERVENTION = "Intervention_Recommended"


def utcnow():
    return datetime.now(timezone.utc)


class WellnessCheckin(Base):
    __tablename__ = "wellness_checkins"
    __table_args__ = (
        UniqueConstraint("user_id", "checkin_date", name="uq_checkin_user_date"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    checkin_date: Mapped[date] = mapped_column(Date, nullable=False)

    # 4 wellness dimensions (1–5 scale matching Flutter DimKey)
    overall_score: Mapped[int] = mapped_column(Integer, nullable=False)   # Overall readiness
    sleep_score: Mapped[int] = mapped_column(Integer, nullable=False)      # Sleep quality
    physical_score: Mapped[int] = mapped_column(Integer, nullable=False)  # Physical status
    focus_score: Mapped[int] = mapped_column(Integer, nullable=False)     # Focus & alertness

    # Computed average of the 4 dimensions
    average_score: Mapped[float] = mapped_column(Float, nullable=False)

    # Free-text note — AES-256-GCM encrypted bytes
    note_encrypted: Mapped[bytes | None] = mapped_column(LargeBinary, nullable=True)

    # ML-computed risk tier
    risk_level: Mapped[RiskLevel] = mapped_column(
        SAEnum(RiskLevel, name="risklevel"),
        nullable=False,
        default=RiskLevel.ROUTINE,
    )

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

    # relationships
    user: Mapped["User"] = relationship("User", back_populates="checkins")  # type: ignore[name-defined]
