from __future__ import annotations
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
from sqlalchemy import text

from app.config import get_settings

settings = get_settings()

engine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.DEBUG,
    pool_pre_ping=True,
    pool_size=10,
    max_overflow=20,
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
    """FastAPI dependency: yields an async database session."""
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
    Uses SET LOCAL so settings are transaction-scoped and automatically
    reset when the connection returns to the pool.
    """
    pg_role = _ROLE_TO_PG_ROLE.get(user_role, "app_personnel")
    await session.execute(text(f"SET LOCAL ROLE {pg_role}"))
    await session.execute(text("SET LOCAL app.current_user_id = :uid"), {"uid": str(user_id)})
    await session.execute(text("SET LOCAL app.current_user_role = :urole"), {"urole": user_role})


async def set_service_context(session: AsyncSession) -> None:
    """
    Set service-level (app_welfare) context for aggregate-only queries.
    Use ONLY for endpoints that return aggregate data (counts/trends)
    and never expose individual rows.
    """
    await session.execute(text("SET LOCAL ROLE app_welfare"))
