from __future__ import annotations
"""Shared FastAPI dependencies — DB session, current user, role guards, RLS."""
from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db, set_rls_context, set_service_context
from app.utils.security import decode_token
from app.models.user import User, UserRole

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


async def get_current_user(
    token: Annotated[str, Depends(oauth2_scheme)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> User:
    credentials_exc = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = decode_token(token)
        user_id: str | None = payload.get("sub")
        if user_id is None:
            raise credentials_exc
    except JWTError:
        raise credentials_exc

    result = await db.execute(select(User).where(User.id == user_id, User.is_active == True))
    user = result.scalar_one_or_none()
    if user is None:
        raise credentials_exc
    return user


def require_role(*roles: UserRole):
    """Dependency factory — raises 403 if the current user doesn't have one of the required roles."""
    async def check(current_user: Annotated[User, Depends(get_current_user)]) -> User:
        if current_user.role not in roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access requires one of: {[r.value for r in roles]}",
            )
        return current_user
    return check


# ── Role-based shorthands ────────────────────────────────────────────────────

# Any officer or admin (for aggregate-safe endpoints like unit-summary, trends)
CurrentUser = Annotated[User, Depends(get_current_user)]
OfficerOrAbove = Annotated[User, Depends(require_role(UserRole.WELFARE_OFFICER, UserRole.COMMANDER, UserRole.ADMIN))]

# Welfare officers and admins ONLY — commanders excluded (for individual-data endpoints)
WelfareOnly = Annotated[User, Depends(require_role(UserRole.WELFARE_OFFICER, UserRole.ADMIN))]

AdminOnly = Annotated[User, Depends(require_role(UserRole.ADMIN))]

# Plain DB session (no RLS — used for auth lookups, aggregate endpoints with service context)
DbSession = Annotated[AsyncSession, Depends(get_db)]


# ── RLS-aware DB session ─────────────────────────────────────────────────────

async def get_rls_session(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> AsyncSession:
    """
    Returns a DB session with RLS context set for the current user.
    The SET LOCAL statements are transaction-scoped and reset automatically.
    """
    await set_rls_context(db, str(current_user.id), current_user.role.value)
    return db


async def get_service_session(
    db: Annotated[AsyncSession, Depends(get_db)],
) -> AsyncSession:
    """
    Returns a DB session running as app_welfare for aggregate-only queries.
    Use ONLY for endpoints that return aggregate data and never expose individual rows.
    """
    await set_service_context(db)
    return db


RlsSession = Annotated[AsyncSession, Depends(get_rls_session)]
ServiceSession = Annotated[AsyncSession, Depends(get_service_session)]
