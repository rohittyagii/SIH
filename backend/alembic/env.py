"""Alembic env.py — async migration runner using asyncpg (matches app DB engine)."""
import asyncio
from logging.config import fileConfig

from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import pool

from alembic import context

# Import settings and all models so Alembic can detect them
from app.config import get_settings
from app.database import Base
import app.models  # noqa: F401 — registers all ORM models on Base.metadata

settings = get_settings()

# Alembic Config object
config = context.config

# Set the DB URL from application settings (uses asyncpg, works with Supabase pooler)
config.set_main_option("sqlalchemy.url", settings.DATABASE_URL)

# Interpret logging configuration
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata


def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode — generates SQL script without a live connection."""
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()


async def run_async_migrations() -> None:
    """Run migrations online using an async engine (asyncpg) for full Supabase compatibility."""
    async_engine = create_async_engine(
        settings.DATABASE_URL,
        poolclass=pool.NullPool,
        # Disable prepared statement cache — required for Supabase transaction pooler
        connect_args={
            "statement_cache_size": 0,
            "prepared_statement_cache_size": 0,
        },
    )

    async with async_engine.connect() as connection:
        await connection.run_sync(_do_run_migrations)

    await async_engine.dispose()


def _do_run_migrations(connection):
    context.configure(connection=connection, target_metadata=target_metadata)
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Entry point for Alembic online mode — dispatches to the async runner."""
    asyncio.run(run_async_migrations())


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()


