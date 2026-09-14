from __future__ import annotations
"""Shared FastAPI dependencies — DB session, current user, role guards."""
from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db, get_rls_db
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
        user_id: str = payload.get("sub")
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


async def _get_rls_session(current_user: Annotated[User, Depends(get_current_user)]):
    """
    Yields a DB session with PostgreSQL RLS context injected (SET LOCAL ROLE + session vars).
    Use via the RlsSession type annotation on any endpoint that should respect RLS policies.
    Commanders using RLS-protected sessions will be blocked from individual rows on
    wellness_checkins, ai_assessments, and support_requests.
    """
    async for session in get_rls_db(str(current_user.id), current_user.role.value):
        yield session


# ── Convenience shorthands ────────────────────────────────────────────────────

# Any authenticated user (no role check)
CurrentUser = Annotated[User, Depends(get_current_user)]

# Officers AND Commanders — use for aggregate/read-only views safe for Commanders
OfficerOrAbove = Annotated[User, Depends(require_role(
    UserRole.WELFARE_OFFICER, UserRole.COMMANDER, UserRole.ADMIN
))]

# Welfare Officers and Admins ONLY — use for individual soldier data endpoints
# Commanders hitting these endpoints receive 403 Forbidden
WelfareOnly = Annotated[User, Depends(require_role(
    UserRole.WELFARE_OFFICER, UserRole.ADMIN
))]

# Admin only
AdminOnly = Annotated[User, Depends(require_role(UserRole.ADMIN))]

# Plain DB session — NO RLS (for aggregate queries, migrations, seeding)
DbSession = Annotated[AsyncSession, Depends(get_db)]

# RLS-enforced DB session — activates PostgreSQL row-level policies per user/role
RlsSession = Annotated[AsyncSession, Depends(_get_rls_session)]

