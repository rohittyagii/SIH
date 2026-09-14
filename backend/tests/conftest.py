"""Shared pytest fixtures — extended with role-based token helpers."""
from __future__ import annotations
import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app


@pytest.fixture
async def client():
    """Async test client for the FastAPI app."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as c:
        yield c


@pytest.fixture
async def commander_token(client: AsyncClient) -> str:
    """Obtain a JWT for the seed Commander (cmd_sharma / demo123)."""
    resp = await client.post(
        "/auth/login",
        data={"username": "cmd_sharma", "password": "demo123"},
    )
    assert resp.status_code == 200, f"Commander login failed: {resp.text}"
    return resp.json()["access_token"]


@pytest.fixture
async def welfare_token(client: AsyncClient) -> str:
    """Obtain a JWT for the seed Welfare Officer (wo_meera / demo123)."""
    resp = await client.post(
        "/auth/login",
        data={"username": "wo_meera", "password": "demo123"},
    )
    assert resp.status_code == 200, f"Welfare Officer login failed: {resp.text}"
    return resp.json()["access_token"]


@pytest.fixture
async def commander_headers(commander_token: str) -> dict:
    return {"Authorization": f"Bearer {commander_token}"}


@pytest.fixture
async def welfare_headers(welfare_token: str) -> dict:
    return {"Authorization": f"Bearer {welfare_token}"}
