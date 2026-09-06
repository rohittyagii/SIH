"""Tests for personnel endpoints."""
import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_personnel_list_requires_auth(client: AsyncClient):
    resp = await client.get("/personnel/")
    assert resp.status_code == 401

@pytest.mark.asyncio
async def test_personnel_detail_requires_auth(client: AsyncClient):
    resp = await client.get("/personnel/some-uuid")
    assert resp.status_code == 401
