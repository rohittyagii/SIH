from __future__ import annotations
"""Notification model — in-app notifications for soldiers and welfare officers."""
import enum

from sqlalchemy import Column, String, Text, Enum as SAEnum, ForeignKey, Boolean, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.database import Base


class NotificationType(str, enum.Enum):
    DISCLOSURE_REQUESTED = "DISCLOSURE_REQUESTED"
    DISCLOSURE_APPROVED  = "DISCLOSURE_APPROVED"
    DISCLOSURE_DENIED    = "DISCLOSURE_DENIED"
    DISCLOSURE_EXPIRED   = "DISCLOSURE_EXPIRED"
    DATA_ACCESSED        = "DATA_ACCESSED"
    ASSESSMENT_UPDATED   = "ASSESSMENT_UPDATED"
    SYSTEM               = "SYSTEM"


class Notification(Base):
    """
    In-app notification row. RLS ensures each user only sees their own rows.
    Welfare officers can INSERT on behalf of other users (bypass via app_welfare role).
    """
    __tablename__ = "notifications"

    id                = Column(UUID(as_uuid=True), primary_key=True)
    user_id           = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    title             = Column(String(200), nullable=False)
    body              = Column(Text, nullable=False)
    notification_type = Column(
        SAEnum(NotificationType, name="notificationtype"),
        nullable=False,
        default=NotificationType.SYSTEM,
    )
    # ID of the related entity (disclosure request, assessment, etc.)
    related_entity_id = Column(String(36), nullable=True)
    is_read           = Column(Boolean, nullable=False, default=False)
    created_at        = Column(DateTime(timezone=True), nullable=False)

    # Relationship
    user = relationship("User", back_populates="notifications")
