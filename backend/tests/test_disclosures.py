"""Tests for the dual-control disclosure flow."""
from __future__ import annotations
import pytest
from httpx import AsyncClient


class TestDisclosureFlow:

    async def test_welfare_can_create_disclosure(
        self, client: AsyncClient, welfare_headers: dict
    ):
        """POST /disclosures/ → 201 for a welfare officer"""
        # First get a valid personnel ID from the personnel list
        personnel_resp = await client.get("/personnel/", headers=welfare_headers)
        assert personnel_resp.status_code == 200
        personnel = personnel_resp.json()
        assert len(personnel) > 0, "Need at least one seeded personnel"
        target_id = personnel[0]["id"]

        resp = await client.post(
            "/disclosures/",
            headers=welfare_headers,
            json={
                "target_user_id": target_id,
                "reason": "WELFARE_CONCERN",
                "scope": "wellness,assessments",
                "justification": "Personnel missed 3 check-ins and reported distress to unit buddy.",
            },
        )
        assert resp.status_code == 201, f"Expected 201, got {resp.status_code}: {resp.text}"
        data = resp.json()
        assert data["status"] == "PENDING"
        assert data["target_user_id"] == target_id
        assert data["approving_officer_id"] is None

    async def test_self_approval_rejected(
        self, client: AsyncClient, welfare_headers: dict
    ):
        """The requesting officer cannot approve their own disclosure — must get 403."""
        # Get a valid target
        personnel_resp = await client.get("/personnel/", headers=welfare_headers)
        target_id = personnel_resp.json()[0]["id"]

        # Create disclosure
        create_resp = await client.post(
            "/disclosures/",
            headers=welfare_headers,
            json={
                "target_user_id": target_id,
                "reason": "IMMINENT_RISK",
                "justification": "Self-approval test.",
            },
        )
        assert create_resp.status_code == 201
        disclosure_id = create_resp.json()["id"]

        # Attempt self-approval with the SAME token → must be 403
        approve_resp = await client.patch(
            f"/disclosures/{disclosure_id}/approve",
            headers=welfare_headers,  # same officer who created it
            json={"notes": "Approving my own request (should fail)"},
        )
        assert approve_resp.status_code == 403, (
            f"Expected 403 for self-approval, got {approve_resp.status_code}: {approve_resp.text}"
        )
        assert "self-approval" in approve_resp.json()["detail"].lower()

    async def test_commander_cannot_create_disclosure(
        self, client: AsyncClient, commander_headers: dict
    ):
        """Commanders are blocked from the disclosure endpoint (WelfareOnly)."""
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

    async def test_list_disclosures_returns_pending(
        self, client: AsyncClient, welfare_headers: dict
    ):
        """GET /disclosures/ returns the officer's own requests."""
        # Create one first
        personnel_resp = await client.get("/personnel/", headers=welfare_headers)
        target_id = personnel_resp.json()[0]["id"]
        await client.post(
            "/disclosures/",
            headers=welfare_headers,
            json={"target_user_id": target_id, "reason": "WELFARE_CONCERN"},
        )

        list_resp = await client.get("/disclosures/", headers=welfare_headers)
        assert list_resp.status_code == 200
        data = list_resp.json()
        assert isinstance(data, list)
        assert len(data) > 0

    async def test_cannot_access_data_on_pending_disclosure(
        self, client: AsyncClient, welfare_headers: dict
    ):
        """GET /disclosures/{id}/data on a PENDING disclosure → 403."""
        personnel_resp = await client.get("/personnel/", headers=welfare_headers)
        target_id = personnel_resp.json()[0]["id"]

        create_resp = await client.post(
            "/disclosures/",
            headers=welfare_headers,
            json={
                "target_user_id": target_id,
                "reason": "WELFARE_CONCERN",
                "justification": "Testing data access guard on pending.",
            },
        )
        assert create_resp.status_code == 201
        disclosure_id = create_resp.json()["id"]

        data_resp = await client.get(
            f"/disclosures/{disclosure_id}/data",
            headers=welfare_headers,
        )
        assert data_resp.status_code == 403, (
            f"Expected 403 on pending disclosure data access, got {data_resp.status_code}: {data_resp.text}"
        )

    async def test_deny_disclosure(
        self, client: AsyncClient, welfare_headers: dict
    ):
        """PATCH /disclosures/{id}/deny → 200, status becomes DENIED."""
        personnel_resp = await client.get("/personnel/", headers=welfare_headers)
        target_id = personnel_resp.json()[0]["id"]

        create_resp = await client.post(
            "/disclosures/",
            headers=welfare_headers,
            json={"target_user_id": target_id, "reason": "INVESTIGATION"},
        )
        assert create_resp.status_code == 201
        disclosure_id = create_resp.json()["id"]

        # Denying your own request is allowed (withdrawal)
        deny_resp = await client.patch(
            f"/disclosures/{disclosure_id}/deny",
            headers=welfare_headers,
            json={"notes": "Withdrawing request."},
        )
        assert deny_resp.status_code == 200, (
            f"Expected 200 on deny, got {deny_resp.status_code}: {deny_resp.text}"
        )
        assert deny_resp.json()["status"] == "DENIED"

    async def test_cannot_re_deny_denied_disclosure(
        self, client: AsyncClient, welfare_headers: dict
    ):
        """Cannot deny a DENIED disclosure twice → 409 Conflict."""
        personnel_resp = await client.get("/personnel/", headers=welfare_headers)
        target_id = personnel_resp.json()[0]["id"]

        create_resp = await client.post(
            "/disclosures/",
            headers=welfare_headers,
            json={"target_user_id": target_id, "reason": "WELFARE_CONCERN"},
        )
        disclosure_id = create_resp.json()["id"]

        # First deny
        await client.patch(
            f"/disclosures/{disclosure_id}/deny",
            headers=welfare_headers,
            json={},
        )

        # Second deny → 409
        second_deny = await client.patch(
            f"/disclosures/{disclosure_id}/deny",
            headers=welfare_headers,
            json={},
        )
        assert second_deny.status_code == 409, (
            f"Expected 409 on double-deny, got {second_deny.status_code}: {second_deny.text}"
        )
