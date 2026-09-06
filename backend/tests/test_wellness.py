"""Tests for wellness endpoints."""
import pytest


@pytest.mark.asyncio
async def test_checkin_requires_auth(client):
    resp = await client.post("/api/v1/wellness/checkin", json={
        "overall_score": 4,
        "sleep_score": 3,
        "physical_score": 4,
        "focus_score": 4,
    })
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_history_requires_auth(client):
    resp = await client.get("/api/v1/wellness/history")
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_today_requires_auth(client):
    resp = await client.get("/api/v1/wellness/today")
    assert resp.status_code == 401
