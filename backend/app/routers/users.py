from __future__ import annotations
from typing import Optional
"""Users router — preferences, data export, data deletion (Flutter app)."""
import json
from datetime import datetime, timezone

from fastapi import APIRouter, status
from pydantic import BaseModel
from sqlalchemy import select, delete

from app.dependencies import CurrentUser, DbSession
from app.models.user import User
from app.models.checkin import WellnessCheckin
from app.models.hr_metrics import HRMetrics
from app.utils.encryption import decrypt_text

router = APIRouter(prefix="/users", tags=["users"])


class PreferencesUpdate(BaseModel):
    theme_dark: Optional[bool] = None
    language_pref: Optional[str] = None
    notif_daily_reminder: Optional[bool] = None
    notif_sync_alerts: Optional[bool] = None
    notif_weekly_summary: Optional[bool] = None


class ConsentUpdate(BaseModel):
    consent_given: bool


@router.get("/me")
async def get_me(current_user: CurrentUser, db: DbSession):
    from app.models.user import Unit
    unit_res = await db.execute(select(Unit).where(Unit.id == current_user.unit_id))
    unit = unit_res.scalar_one_or_none()
    return {
        "id": str(current_user.id),
        "username": current_user.username,
        "full_name": current_user.full_name,
        "service_id": current_user.service_id,
        "unit": unit.name if unit else "Unknown",
        "role": current_user.role.value,
        "language_pref": current_user.language_pref,
        "theme_dark": current_user.theme_dark,
        "notif_daily_reminder": current_user.notif_daily_reminder,
        "notif_sync_alerts": current_user.notif_sync_alerts,
        "notif_weekly_summary": current_user.notif_weekly_summary,
        "consent_given": current_user.consent_given,
        "consent_given_at": current_user.consent_given_at.isoformat() if current_user.consent_given_at else None,
    }


@router.patch("/me/preferences", status_code=status.HTTP_204_NO_CONTENT)
async def update_preferences(body: PreferencesUpdate, current_user: CurrentUser, db: DbSession):
    user_res = await db.execute(select(User).where(User.id == current_user.id))
    user = user_res.scalar_one()
    if body.theme_dark is not None:
        user.theme_dark = body.theme_dark
    if body.language_pref is not None:
        user.language_pref = body.language_pref
    if body.notif_daily_reminder is not None:
        user.notif_daily_reminder = body.notif_daily_reminder
    if body.notif_sync_alerts is not None:
        user.notif_sync_alerts = body.notif_sync_alerts
    if body.notif_weekly_summary is not None:
        user.notif_weekly_summary = body.notif_weekly_summary
    user.updated_at = datetime.now(timezone.utc)


@router.patch("/me/consent", status_code=status.HTTP_204_NO_CONTENT)
async def update_consent(body: ConsentUpdate, current_user: CurrentUser, db: DbSession):
    user_res = await db.execute(select(User).where(User.id == current_user.id))
    user = user_res.scalar_one()
    user.consent_given = body.consent_given
    if body.consent_given:
        user.consent_given_at = datetime.now(timezone.utc)


@router.post("/me/export")
async def export_my_data(current_user: CurrentUser, db: DbSession):
    """GDPR-style data export — returns all own data as JSON."""
    checkins_res = await db.execute(
        select(WellnessCheckin).where(WellnessCheckin.user_id == current_user.id)
        .order_by(WellnessCheckin.checkin_date.desc())
    )
    checkins = checkins_res.scalars().all()

    return {
        "export_date": datetime.now(timezone.utc).isoformat(),
        "user": {
            "service_id": current_user.service_id,
            "username": current_user.username,
            "created_at": current_user.created_at.isoformat(),
        },
        "checkins": [
            {
                "date": str(c.checkin_date),
                "overall": c.overall_score,
                "sleep": c.sleep_score,
                "physical": c.physical_score,
                "focus": c.focus_score,
                "average": c.average_score,
                "note": decrypt_text(c.note_encrypted, str(current_user.id)) if c.note_encrypted else "",
            }
            for c in checkins
        ],
    }


@router.delete("/me/data", status_code=status.HTTP_204_NO_CONTENT)
async def delete_my_data(current_user: CurrentUser, db: DbSession):
    """
    Cryptographic erasure: delete all check-ins, HR metrics, assessments,
    then deactivate the user account. The AES key derived from the user ID
    is effectively destroyed when the check-ins are deleted.
    """
    from app.models.assessment import AIAssessment, SupportRequest
    await db.execute(delete(WellnessCheckin).where(WellnessCheckin.user_id == current_user.id))
    await db.execute(delete(HRMetrics).where(HRMetrics.user_id == current_user.id))
    await db.execute(delete(AIAssessment).where(AIAssessment.user_id == current_user.id))
    await db.execute(delete(SupportRequest).where(SupportRequest.user_id == current_user.id))

    user_res = await db.execute(select(User).where(User.id == current_user.id))
    user = user_res.scalar_one()
    user.is_active = False
    user.updated_at = datetime.now(timezone.utc)
