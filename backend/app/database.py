from __future__ import annotations
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
from sqlalchemy import text

from app.config import get_settings

settings = get_settings()

# ── Role → PostgreSQL application role mapping ────────────────────────────────
_ROLE_MAP: dict[str, str] = {
    "Welfare_Officer": "app_welfare",
    "Commander":       "app_commander",
    "Personnel":       "app_personnel",
    "Admin":           "app_welfare",   # Admins get full welfare-level access
}

from sqlalchemy.pool import NullPool

engine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.DEBUG,
    poolclass=NullPool,
    connect_args={"statement_cache_size": 0, "prepared_statement_cache_size": 0},
)

AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)


class Base(DeclarativeBase):
    """Shared declarative base for all ORM models."""
    pass


async def get_db():
    """
    FastAPI dependency: yields a plain async database session with NO RLS context.
    Use this for aggregate/admin queries (e.g., hr-metrics unit summary) that
    intentionally bypass row-level security.
    """
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


async def get_rls_db(user_id: str, user_role: str):
    """
    Yields an AsyncSession with PostgreSQL session variables set for RLS:
      - SET LOCAL app.current_user_id  = '<uuid>'
      - SET LOCAL app.current_user_role = '<role>'
      - SET LOCAL ROLE <pg_role>          (activates the row-level policies)

    This function is not used directly as a FastAPI dependency — it is called
    by the RlsSession dependency in dependencies.py which injects the current
    user's id and role.
    """
    pg_role = _ROLE_MAP.get(user_role, "app_personnel")
    async with AsyncSessionLocal() as session:
        try:
            # Set within the transaction so it resets automatically on rollback/commit
            await session.execute(text(f"SET LOCAL app.current_user_id = '{user_id}'"))
            await session.execute(text(f"SET LOCAL app.current_user_role = '{user_role}'"))
            await session.execute(text(f"SET LOCAL ROLE {pg_role}"))
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()

