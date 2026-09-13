from __future__ import annotations
"""Wellness check-in router — Flutter mobile app."""
from datetime import date, datetime, timezone
from typing import Optional

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select, and_

from app.dependencies import CurrentUser, DbSession
from app.models.checkin import WellnessCheckin, RiskLevel
from app.models.hr_metrics import HRMetrics
from app.schemas.checkin import (
    CheckinCreate, CheckinBatchCreate,
    CheckinResponse, TodayStatusResponse,
)
from app.utils.encryption import encrypt_text, decrypt_text
from app.ml.predictor import predictor
from app.ml.feature_engineering import extract_features

router = APIRouter(prefix="/wellness", tags=["wellness"])


def _compute_risk_simple(scores: dict, hr: Optional[HRMetrics]) -> RiskLevel:
    """Simple rule-based risk tier — ML engine replaces this in Phase 3."""
    avg = scores["average_score"]
    hrv = hr.hrv_baseline_deviation if hr else 0.0
    leave = hr.days_since_last_leave if hr else 0
    duty = hr.avg_weekly_duty_hours if hr else 48.0

    if (hrv > 25 and leave > 120) or avg < 2.0:
        return RiskLevel.INTERVENTION
    if (hrv > 15 and leave > 80) or avg < 3.0 or duty > 58:
        return RiskLevel.MONITOR
    return RiskLevel.ROUTINE


def _to_response(checkin: WellnessCheckin, user_id: str) -> CheckinResponse:
    note = decrypt_text(checkin.note_encrypted, user_id) if checkin.note_encrypted else None
    return CheckinResponse(
        id=str(checkin.id),
        checkin_date=checkin.checkin_date,
        overall_score=checkin.overall_score,
        sleep_score=checkin.sleep_score,
        physical_score=checkin.physical_score,
        focus_score=checkin.focus_score,
        average_score=checkin.average_score,
        risk_level=checkin.risk_level.value,
        note=note,
        created_at=checkin.created_at,
    )


# ── POST /wellness/checkin ────────────────────────────────────────────────────

@router.post("/checkin", response_model=CheckinResponse, status_code=status.HTTP_201_CREATED)
async def submit_checkin(body: CheckinCreate, current_user: CurrentUser, db: DbSession):
    """Submit today's wellness check-in. One per user per day."""
    today = date.today()

    # Enforce once-per-day
    existing = await db.execute(
        select(WellnessCheckin).where(
            and_(WellnessCheckin.user_id == current_user.id,
                 WellnessCheckin.checkin_date == today)
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Check-in already submitted for today",
        )

    avg = round((body.overall_score + body.sleep_score + body.physical_score + body.focus_score) / 4, 2)

    # Load HR metrics for risk computation
    hr_res = await db.execute(select(HRMetrics).where(HRMetrics.user_id == current_user.id))
    hr = hr_res.scalar_one_or_none()

    # Try ML-based risk prediction
    ml_risk = None
    try:
        checkins_for_ml = [{'overall_score': body.overall_score, 'sleep_score': body.sleep_score, 'physical_score': body.physical_score, 'focus_score': body.focus_score}]
        hr_dict = {'avg_weekly_duty_hours': hr.avg_weekly_duty_hours, 'days_since_last_leave': hr.days_since_last_leave, 'deployment_history_months': hr.deployment_history_months, 'hrv_baseline_deviation': hr.hrv_baseline_deviation} if hr else None
        result = predictor.predict(checkins_for_ml, hr_dict)
        if result:
            ml_risk = RiskLevel(result['risk_level'])
    except Exception:
        pass  # fallback to rules

    risk = ml_risk if ml_risk else _compute_risk_simple({"average_score": avg}, hr)

    note_enc = encrypt_text(body.note, str(current_user.id)) if body.note else None

    checkin = WellnessCheckin(
        user_id=current_user.id,
        checkin_date=today,
        overall_score=body.overall_score,
        sleep_score=body.sleep_score,
        physical_score=body.physical_score,
        focus_score=body.focus_score,
        average_score=avg,
        note_encrypted=note_enc,
        risk_level=risk,
        created_at=datetime.now(timezone.utc),
    )
    db.add(checkin)
    await db.flush()

    # Update HR metrics derived scores
    if hr:
        hr.avg_mood_score = round(body.overall_score * 2, 1)
        hr.avg_sleep_recovery = round(body.sleep_score * 2, 1)
        hr.avg_fatigue_level = round((6 - body.physical_score) * 2, 1)
        hr.last_updated = datetime.now(timezone.utc)

    return _to_response(checkin, str(current_user.id))


# ── GET /wellness/today ───────────────────────────────────────────────────────

@router.get("/today", response_model=TodayStatusResponse)
async def today_status(current_user: CurrentUser, db: DbSession):
    """Check if today's check-in has been submitted."""
    today = date.today()
    result = await db.execute(
        select(WellnessCheckin).where(
            and_(WellnessCheckin.user_id == current_user.id,
                 WellnessCheckin.checkin_date == today)
        )
    )
    checkin = result.scalar_one_or_none()
    if checkin:
        return TodayStatusResponse(done=True, checkin=_to_response(checkin, str(current_user.id)))
    return TodayStatusResponse(done=False)


# ── GET /wellness/history ─────────────────────────────────────────────────────

@router.get("/history", response_model=list[CheckinResponse])
async def get_history(current_user: CurrentUser, db: DbSession, limit: int = 30, offset: int = 0):
    """Get own check-in history, newest first."""
    result = await db.execute(
        select(WellnessCheckin)
        .where(WellnessCheckin.user_id == current_user.id)
        .order_by(WellnessCheckin.checkin_date.desc())
        .limit(limit)
        .offset(offset)
    )
    checkins = result.scalars().all()
    return [_to_response(c, str(current_user.id)) for c in checkins]


# ── POST /wellness/batch ──────────────────────────────────────────────────────

@router.post("/batch", response_model=list[CheckinResponse], status_code=status.HTTP_201_CREATED)
async def submit_batch(body: CheckinBatchCreate, current_user: CurrentUser, db: DbSession):
    """Sync offline-queued check-ins. Skips dates already submitted."""
    created = []
    hr_res = await db.execute(select(HRMetrics).where(HRMetrics.user_id == current_user.id))
    hr = hr_res.scalar_one_or_none()

    for item in body.checkins:
        existing = await db.execute(
            select(WellnessCheckin).where(
                and_(WellnessCheckin.user_id == current_user.id,
                     WellnessCheckin.checkin_date == item.checkin_date)
            )
        )
        if existing.scalar_one_or_none():
            continue  # already synced

        avg = round((item.overall_score + item.sleep_score + item.physical_score + item.focus_score) / 4, 2)
        # Try ML-based risk prediction
        ml_risk = None
        try:
            checkins_for_ml = [{'overall_score': item.overall_score, 'sleep_score': item.sleep_score, 'physical_score': item.physical_score, 'focus_score': item.focus_score}]
            hr_dict = {'avg_weekly_duty_hours': hr.avg_weekly_duty_hours, 'days_since_last_leave': hr.days_since_last_leave, 'deployment_history_months': hr.deployment_history_months, 'hrv_baseline_deviation': hr.hrv_baseline_deviation} if hr else None
            result = predictor.predict(checkins_for_ml, hr_dict)
            if result:
                ml_risk = RiskLevel(result['risk_level'])
        except Exception:
            pass  # fallback to rules

        risk = ml_risk if ml_risk else _compute_risk_simple({"average_score": avg}, hr)
        note_enc = encrypt_text(item.note, str(current_user.id)) if item.note else None

        checkin = WellnessCheckin(
            user_id=current_user.id,
            checkin_date=item.checkin_date,
            overall_score=item.overall_score,
            sleep_score=item.sleep_score,
            physical_score=item.physical_score,
            focus_score=item.focus_score,
            average_score=avg,
            note_encrypted=note_enc,
            risk_level=risk,
            created_at=datetime.now(timezone.utc),
        )
        db.add(checkin)
        await db.flush()
        created.append(_to_response(checkin, str(current_user.id)))

    return created
