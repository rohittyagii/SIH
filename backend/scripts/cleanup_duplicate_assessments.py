"""
One-shot cleanup: delete all but the latest AIAssessment per user.
Run from backend/ directory:
    .venv/bin/python scripts/cleanup_duplicate_assessments.py
"""
import asyncio
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

DATABASE_URL = (
    "postgresql+asyncpg://postgres:joxwez-2xuhte-bYffib@aws-0-ap-southeast-1.pooler.supabase.com:6543/postgres"
)

async def cleanup():
    engine = create_async_engine(DATABASE_URL, echo=False)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as session:
        count_before = await session.execute(text("SELECT COUNT(*) FROM ai_assessments"))
        total_before = count_before.scalar()
        print(f"Total assessments before cleanup: {total_before}")

        delete_sql = text("""
            DELETE FROM ai_assessments
            WHERE id NOT IN (
                SELECT DISTINCT ON (user_id) id
                FROM ai_assessments
                ORDER BY user_id, created_at DESC
            )
        """)
        result = await session.execute(delete_sql)
        await session.commit()

        deleted = result.rowcount
        remaining = total_before - deleted
        print(f"Deleted {deleted} duplicate rows.")
        print(f"Remaining assessments: {remaining} (one per soldier)")

    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(cleanup())
