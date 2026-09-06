"""SQLAlchemy ORM — HRMetrics (operational data per soldier)"""
import uuid
from datetime import datetime, timezone

from sqlalchemy import Float, Integer, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


def utcnow():
    return datetime.now(timezone.utc)


class HRMetrics(Base):
    """
    Operational / HR data for a soldier.
    Updated by Admin/HR staff, consumed by the ML engine alongside check-in data.
    The web dashboard personnel detail page reads these fields directly.
    """
    __tablename__ = "hr_metrics"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, unique=True
    )

    # Operational metrics
    avg_weekly_duty_hours: Mapped[float] = mapped_column(Float, default=48.0)
    days_since_last_leave: Mapped[int] = mapped_column(Integer, default=0)
    deployment_history_months: Mapped[int] = mapped_column(Integer, default=0)

    # Wearable biometric (simulated HRV data)
    hrv_baseline_deviation: Mapped[float] = mapped_column(Float, default=0.0)  # percent deviation

    # Derived scores (fed from wellness checkins, updated on each checkin)
    avg_mood_score: Mapped[float] = mapped_column(Float, default=5.0)      # 1–10 mapped from checkin
    avg_sleep_recovery: Mapped[float] = mapped_column(Float, default=5.0)  # 1–10
    avg_fatigue_level: Mapped[float] = mapped_column(Float, default=5.0)   # 1–10

    last_updated: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)

    # relationships
    user: Mapped["User"] = relationship("User", back_populates="hr_metrics")  # type: ignore[name-defined]
