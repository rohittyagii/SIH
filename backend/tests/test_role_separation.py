"""Tests for role-based access separation between Commander and Welfare Officer."""
from __future__ import annotations
import pytest
from httpx import AsyncClient


# ── Commander blocked from individual-data endpoints ──────────────────────────

class TestCommanderBlocked:

    async def test_commander_cannot_list_personnel(self, client: AsyncClient, commander_headers: dict):
        """Commander must get 403 on GET /personnel/"""
        resp = await client.get("/personnel/", headers=commander_headers)
        assert resp.status_code == 403, (
            f"Expected 403 for Commander on /personnel/, got {resp.status_code}: {resp.text}"
        )

    async def test_commander_cannot_get_personnel_detail(self, client: AsyncClient, commander_headers: dict):
        """Commander must get 403 on GET /personnel/{id} — any UUID."""
        resp = await client.get(
            "/personnel/00000000-0000-0000-0000-000000000001",
            headers=commander_headers,
        )
        # 403 (role guard fires before DB lookup) or 404 is acceptable — 200 is NOT
        assert resp.status_code in (403, 404), (
            f"Expected 403/404 for Commander on /personnel/{{id}}, got {resp.status_code}"
        )
        # Must specifically not be 200
        assert resp.status_code != 200

    async def test_commander_cannot_access_triage(self, client: AsyncClient, commander_headers: dict):
        """Commander must get 403 on GET /assessments/triage"""
        resp = await client.get("/assessments/triage", headers=commander_headers)
        assert resp.status_code == 403, (
            f"Expected 403 for Commander on /assessments/triage, got {resp.status_code}: {resp.text}"
        )

    async def test_commander_cannot_access_assessment_history(self, client: AsyncClient, commander_headers: dict):
        """Commander must get 403 on GET /assessments/history/{id}"""
        resp = await client.get(
            "/assessments/history/00000000-0000-0000-0000-000000000001",
            headers=commander_headers,
        )
        assert resp.status_code in (403, 404)
        assert resp.status_code != 200

    async def test_commander_cannot_run_assessment(self, client: AsyncClient, commander_headers: dict):
        """Commander must get 403 on POST /assessments/run/{id}"""
        resp = await client.post(
            "/assessments/run/00000000-0000-0000-0000-000000000001",
            headers=commander_headers,
        )
        assert resp.status_code in (403, 404)
        assert resp.status_code != 200

    async def test_commander_cannot_update_assessment_action(self, client: AsyncClient, commander_headers: dict):
        """Commander must get 403 on PATCH /assessments/{id}/action"""
        resp = await client.patch(
            "/assessments/00000000-0000-0000-0000-000000000001/action",
            headers=commander_headers,
            json={"status": "Acknowledged"},
        )
        assert resp.status_code in (403, 404)
        assert resp.status_code != 200

    async def test_commander_cannot_access_disclosures(self, client: AsyncClient, commander_headers: dict):
        """Commander must get 403 on POST /disclosures/ — disclosures are welfare-only"""
        resp = await client.post(
            "/disclosures/",
            headers=commander_headers,
            json={
                "target_user_id": "00000000-0000-0000-0000-000000000001",
                "reason": "WELFARE_CONCERN",
            },
        )
        assert resp.status_code == 403, (
            f"Expected 403 for Commander on /disclosures/, got {resp.status_code}: {resp.text}"
        )


# ── Commander allowed on aggregate endpoints ──────────────────────────────────

class TestCommanderAllowed:

    async def test_commander_can_access_unit_summary(self, client: AsyncClient, commander_headers: dict):
        """Commander must get 200 on GET /hr-metrics/unit-summary"""
        resp = await client.get("/hr-metrics/unit-summary", headers=commander_headers)
        assert resp.status_code == 200, (
            f"Expected 200 for Commander on /hr-metrics/unit-summary, got {resp.status_code}: {resp.text}"
        )
        data = resp.json()
        assert isinstance(data, list), "unit-summary should return a list"

    async def test_commander_can_access_trends(self, client: AsyncClient, commander_headers: dict):
        """Commander must get 200 on GET /assessments/trends"""
        resp = await client.get("/assessments/trends", headers=commander_headers)
        assert resp.status_code == 200, (
            f"Expected 200 for Commander on /assessments/trends, got {resp.status_code}: {resp.text}"
        )
        data = resp.json()
        assert isinstance(data, list)

    async def test_commander_can_access_health(self, client: AsyncClient, commander_headers: dict):
        """Commander can access /health (no auth required but should work)"""
        resp = await client.get("/health")
        assert resp.status_code == 200


# ── Welfare Officer has full access ──────────────────────────────────────────

class TestWelfareOfficerAccess:

    async def test_welfare_can_list_personnel(self, client: AsyncClient, welfare_headers: dict):
        """Welfare Officer must get 200 on GET /personnel/"""
        resp = await client.get("/personnel/", headers=welfare_headers)
        assert resp.status_code == 200, (
            f"Expected 200 for Welfare on /personnel/, got {resp.status_code}: {resp.text}"
        )
        data = resp.json()
        assert isinstance(data, list)
        assert len(data) > 0, "Expected seeded personnel in the response"

    async def test_welfare_can_access_triage(self, client: AsyncClient, welfare_headers: dict):
        """Welfare Officer must get 200 on GET /assessments/triage"""
        resp = await client.get("/assessments/triage", headers=welfare_headers)
        assert resp.status_code == 200, (
            f"Expected 200 for Welfare on /assessments/triage, got {resp.status_code}: {resp.text}"
        )

    async def test_welfare_can_access_unit_summary(self, client: AsyncClient, welfare_headers: dict):
        """Welfare Officer must also get 200 on /hr-metrics/unit-summary"""
        resp = await client.get("/hr-metrics/unit-summary", headers=welfare_headers)
        assert resp.status_code == 200

    async def test_unauthenticated_gets_401(self, client: AsyncClient):
        """No token → 401 on all protected endpoints"""
        for endpoint in ["/personnel/", "/assessments/triage", "/hr-metrics/unit-summary"]:
            resp = await client.get(endpoint)
            assert resp.status_code == 401, f"Expected 401 on {endpoint}, got {resp.status_code}"
