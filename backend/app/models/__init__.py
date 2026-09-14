from __future__ import annotations
from typing import Optional, List, Dict, Any, Union
"""Models package — import all models so Alembic sees them."""
from app.models.user import User, Unit, ActivationCode, UserRole
from app.models.checkin import WellnessCheckin, RiskLevel
from app.models.hr_metrics import HRMetrics
from app.models.assessment import AIAssessment, AssessmentStatus, SupportRequest, AuditLog
from app.models.disclosure import DisclosureRequest, DisclosureReason, DisclosureStatus
from app.models.notification import Notification, NotificationType

__all__ = [
    "User", "Unit", "ActivationCode", "UserRole",
    "WellnessCheckin", "RiskLevel",
    "HRMetrics",
    "AIAssessment", "AssessmentStatus", "SupportRequest", "AuditLog",
    "DisclosureRequest", "DisclosureReason", "DisclosureStatus",
    "Notification", "NotificationType",
]

