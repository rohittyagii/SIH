from __future__ import annotations
"""Health check endpoints."""
from fastapi import APIRouter
from sqlalchemy import text

from app.database import AsyncSessionLocal

router = APIRouter(prefix="/health", tags=["health"])


@router.get("")
async def liveness():
    return {"status": "ok"}


@router.get("/ready")
async def readiness():
    """Check DB connectivity."""
    try:
        async with AsyncSessionLocal() as session:
            await session.execute(text("SELECT 1"))
        return {"status": "ready", "db": "ok"}
    except Exception as e:
        return {"status": "not_ready", "db": str(e)}
