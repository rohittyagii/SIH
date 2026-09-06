"""Tests for auth endpoints."""
import pytest


@pytest.mark.asyncio
async def test_health_liveness(client):
    resp = await client.get("/health")
    assert resp.status_code == 200
    assert resp.json()["status"] == "ok"


@pytest.mark.asyncio
async def test_root(client):
    resp = await client.get("/")
    assert resp.status_code == 200
    data = resp.json()
    assert data["name"] == "SainikSaathi API"


@pytest.mark.asyncio
async def test_login_wrong_credentials(client):
    resp = await client.post(
        "/auth/login",
        data={"username": "nobody", "password": "wrong"},
        headers={"Content-Type": "application/x-www-form-urlencoded"},
    )
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_me_without_token(client):
    resp = await client.get("/auth/me")
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_mobile_login_invalid(client):
    resp = await client.post(
        "/api/v1/auth/mobile/login",
        json={"service_id": "INVALID-999", "pin": "000000"},
    )
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_activate_invalid_code(client):
    resp = await client.post(
        "/api/v1/auth/mobile/activate",
        json={
            "activation_code": "FAKE-0000",
            "pin": "123456",
            "full_name": "Test User",
        },
    )
    assert resp.status_code == 400
