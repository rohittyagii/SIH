from __future__ import annotations
"""Auth router — serves both the web dashboard (OAuth2 form) and Flutter (JSON)."""
from typing import Annotated
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update

from app.database import get_db
from app.models.user import User, ActivationCode, UserRole
from app.schemas.auth import (
    TokenResponse, UserProfile,
    MobileActivateRequest, MobileLoginRequest, MobileLoginResponse,
    ChangePinRequest,
)
from app.utils.security import hash_password, verify_password, create_access_token
from app.dependencies import CurrentUser, DbSession

router = APIRouter(prefix="/auth", tags=["auth"])


# ── Dashboard: POST /auth/login (OAuth2 form-urlencoded) ─────────────────────

@router.post("/login", response_model=TokenResponse)
async def dashboard_login(
    form: Annotated[OAuth2PasswordRequestForm, Depends()],
    db: DbSession,
):
    """
    Web dashboard login. Accepts application/x-www-form-urlencoded with
    username and password fields (OAuth2 password-grant compatible).
    """
    result = await db.execute(
        select(User).where(User.username == form.username, User.is_active == True)
    )
    user = result.scalar_one_or_none()
    if not user or not verify_password(form.password, user.pin_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
        )
    token = create_access_token({"sub": str(user.id), "role": user.role.value})
    return TokenResponse(access_token=token)


# ── Dashboard: GET /auth/me ───────────────────────────────────────────────────

@router.get("/me", response_model=UserProfile)
async def get_me(current_user: CurrentUser, db: DbSession):
    """Return the current authenticated user's profile."""
    # Load unit name
    result = await db.execute(
        select(User).where(User.id == current_user.id)
    )
    user = result.scalar_one()
    # Load unit separately to get name
    from app.models.user import Unit
    unit_res = await db.execute(select(Unit).where(Unit.id == user.unit_id))
    unit = unit_res.scalar_one_or_none()

    return UserProfile(
        id=str(user.id),
        username=user.username,
        role=user.role.value,
        unit=unit.name if unit else "Unknown",
        full_name=user.full_name,
        service_id=user.service_id,
    )


# ── Mobile: POST /auth/mobile/activate ───────────────────────────────────────

@router.post("/mobile/activate", response_model=MobileLoginResponse, status_code=status.HTTP_201_CREATED)
async def mobile_activate(body: MobileActivateRequest, db: DbSession):
    """
    First-time device onboarding for Flutter app.
    Validates 8-char activation code, creates a Personnel user account.
    """
    # Look up activation code
    code_res = await db.execute(
        select(ActivationCode).where(
            ActivationCode.code == body.activation_code,
            ActivationCode.is_used == False,
        )
    )
    activation = code_res.scalar_one_or_none()
    if not activation:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or already used activation code",
        )

    # Derive a callsign from the code (in production, this would be assigned by welfare office)
    # For now: generate from code prefix
    callsign = f"User-{body.activation_code[:4]}"
    service_id = f"SIH-{body.activation_code.replace('-', '')}"

    # Check no existing user with this service_id
    existing = await db.execute(select(User).where(User.service_id == service_id))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Device already activated")

    # Create user
    user = User(
        service_id=service_id,
        username=callsign,
        full_name=body.full_name,
        unit_id=activation.unit_id,
        pin_hash=hash_password(body.pin),
        role=UserRole.PERSONNEL,
        consent_given=False,
    )
    db.add(user)

    # Mark code as used
    activation.is_used = True
    activation.used_at = datetime.now(timezone.utc)

    await db.flush()  # get user.id

    # Create HR metrics record
    from app.models.hr_metrics import HRMetrics
    hr = HRMetrics(user_id=user.id)
    db.add(hr)

    await db.commit()
    await db.refresh(user)

    # Load unit name
    from app.models.user import Unit
    unit_res = await db.execute(select(Unit).where(Unit.id == user.unit_id))
    unit = unit_res.scalar_one()

    token = create_access_token({"sub": str(user.id), "role": user.role.value})
    profile = UserProfile(
        id=str(user.id),
        username=user.username,
        role=user.role.value,
        unit=unit.name,
        full_name=user.full_name,
        service_id=user.service_id,
    )
    return MobileLoginResponse(access_token=token, user=profile)


# ── Mobile: POST /auth/mobile/login ──────────────────────────────────────────

@router.post("/mobile/login", response_model=MobileLoginResponse)
async def mobile_login(body: MobileLoginRequest, db: DbSession):
    """Login with service_id + 6-digit PIN (Flutter app)."""
    result = await db.execute(
        select(User).where(User.service_id == body.service_id, User.is_active == True)
    )
    user = result.scalar_one_or_none()
    if not user or not verify_password(body.pin, user.pin_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    from app.models.user import Unit
    unit_res = await db.execute(select(Unit).where(Unit.id == user.unit_id))
    unit = unit_res.scalar_one()

    token = create_access_token({"sub": str(user.id), "role": user.role.value})
    profile = UserProfile(
        id=str(user.id),
        username=user.username,
        role=user.role.value,
        unit=unit.name,
        full_name=user.full_name,
        service_id=user.service_id,
    )
    return MobileLoginResponse(access_token=token, user=profile)


# ── Mobile: POST /auth/mobile/change-pin ─────────────────────────────────────

@router.post("/mobile/change-pin", status_code=status.HTTP_204_NO_CONTENT)
async def change_pin(body: ChangePinRequest, current_user: CurrentUser, db: DbSession):
    if not verify_password(body.current_pin, current_user.pin_hash):
        raise HTTPException(status_code=400, detail="Current PIN is incorrect")
    await db.execute(
        update(User)
        .where(User.id == current_user.id)
        .values(pin_hash=hash_password(body.new_pin))
    )


# ── POST /auth/logout ─────────────────────────────────────────────────────────

@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(current_user: CurrentUser):
    """
    Stateless JWT — client deletes token locally.
    In production, add token to Redis blacklist here.
    """
    pass
