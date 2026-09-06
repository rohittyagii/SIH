"""Tests for assessments endpoints."""
import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_triage_requires_auth(client: AsyncClient):
    resp = await client.get("/assessments/triage")
    assert resp.status_code == 401

@pytest.mark.asyncio
async def test_trends_requires_auth(client: AsyncClient):
    resp = await client.get("/assessments/trends")
    assert resp.status_code == 401

@pytest.mark.asyncio
async def test_run_assessment_requires_auth(client: AsyncClient):
    resp = await client.post("/assessments/run/some-uuid")
    assert resp.status_code == 401
