from __future__ import annotations
# pyrefly: ignore [missing-import]
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
# pyrefly: ignore [missing-import]
from sqlalchemy.orm import DeclarativeBase
# pyrefly: ignore [missing-import]
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

# pyrefly: ignore [missing-import]
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


# ── RLS-aware session helpers ─────────────────────────────────────────────────

# Map application UserRole → PostgreSQL NOLOGIN role
_ROLE_TO_PG_ROLE = {
    "Personnel": "app_personnel",
    "Welfare_Officer": "app_welfare",
    "Commander": "app_commander",
    "Admin": "app_welfare",  # Admin inherits welfare-level access
}


async def set_rls_context(session: AsyncSession, user_id: str, user_role: str) -> None:
    """
    Inject RLS session variables into the current transaction.
    Uses set_config() with is_local=true so settings are transaction-scoped
    and automatically reset when the connection returns to the pool.

    Note: SET LOCAL does not support parameterized queries in PostgreSQL.
    set_config() is used instead because it does support bound parameters.
    """
    pg_role = _ROLE_TO_PG_ROLE.get(user_role, "app_personnel")
    # SET LOCAL ROLE must use literal (pg_role is always from a trusted internal dict, never user input)
    await session.execute(text(f"SET LOCAL ROLE {pg_role}"))
    # set_config() supports parameters and is transaction-local when is_local=true
    await session.execute(
        text("SELECT set_config('app.current_user_id', :uid, true)"),
        {"uid": user_id},
    )
    await session.execute(
        text("SELECT set_config('app.current_user_role', :urole, true)"),
        {"urole": user_role},
    )


async def set_service_context(session: AsyncSession) -> None:
    """
    Set service-level (app_welfare) context for aggregate-only queries.
    Use ONLY for endpoints that return aggregate data (counts/trends)
    and never expose individual rows.
    """
    await session.execute(text("SET LOCAL ROLE app_welfare"))
