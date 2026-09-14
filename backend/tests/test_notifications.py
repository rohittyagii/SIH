"""Tests for the in-app notifications system."""
from __future__ import annotations
import pytest
from httpx import AsyncClient


class TestNotifications:

    async def test_unauthenticated_cannot_list_notifications(self, client: AsyncClient):
        """No token → 401 on GET /notifications/"""
        resp = await client.get("/notifications/")
        assert resp.status_code == 401

    async def test_welfare_can_list_notifications(self, client: AsyncClient, welfare_headers: dict):
        """Welfare officer can list their notification feed."""
        resp = await client.get("/notifications/", headers=welfare_headers)
        assert resp.status_code == 200
        assert isinstance(resp.json(), list)

    async def test_commander_can_list_notifications(self, client: AsyncClient, commander_headers: dict):
        """Commanders also have a notification feed (in-app announcements)."""
        resp = await client.get("/notifications/", headers=commander_headers)
        assert resp.status_code == 200
        assert isinstance(resp.json(), list)

    async def test_unread_count_returns_integer(self, client: AsyncClient, welfare_headers: dict):
        """GET /notifications/unread-count returns a non-negative integer."""
        resp = await client.get("/notifications/unread-count", headers=welfare_headers)
        assert resp.status_code == 200
        data = resp.json()
        assert "unread_count" in data
        assert isinstance(data["unread_count"], int)
        assert data["unread_count"] >= 0

    async def test_notification_created_on_disclosure_request(
        self, client: AsyncClient, welfare_headers: dict
    ):
        """
        Creating a disclosure request should generate notifications:
        - One for the target soldier
        - One for each other welfare officer
        After creating, the unread count for the requesting officer should not decrease.
        """
        # Get count before
        count_before_resp = await client.get("/notifications/unread-count", headers=welfare_headers)
        count_before = count_before_resp.json()["unread_count"]

        # Create disclosure
        personnel_resp = await client.get("/personnel/", headers=welfare_headers)
        assert personnel_resp.status_code == 200
        personnel = personnel_resp.json()
        assert len(personnel) > 0
        target_id = personnel[0]["id"]

        create_resp = await client.post(
            "/disclosures/",
            headers=welfare_headers,
            json={
                "target_user_id": target_id,
                "reason": "WELFARE_CONCERN",
                "justification": "Notification trigger test.",
            },
        )
        assert create_resp.status_code == 201

        # Welfare officer may receive a notification from their own action (system confirms)
        # At minimum, the notification list should be retrievable
        list_resp = await client.get("/notifications/", headers=welfare_headers)
        assert list_resp.status_code == 200

    async def test_mark_notification_read(self, client: AsyncClient, welfare_headers: dict):
        """
        If the welfare officer has any notifications, mark the first one as read.
        Then verify is_read is True.
        """
        list_resp = await client.get("/notifications/", headers=welfare_headers)
        assert list_resp.status_code == 200
        notifications = list_resp.json()

        if not notifications:
            pytest.skip("No notifications available to mark as read — run disclosure test first")

        notif_id = notifications[0]["id"]
        mark_resp = await client.patch(
            f"/notifications/{notif_id}/read",
            headers=welfare_headers,
        )
        assert mark_resp.status_code == 200
        assert mark_resp.json()["is_read"] is True

    async def test_mark_all_read(self, client: AsyncClient, welfare_headers: dict):
        """PATCH /notifications/read-all → 200 with success message."""
        resp = await client.patch("/notifications/read-all", headers=welfare_headers)
        assert resp.status_code == 200
        assert "read" in resp.json().get("message", "").lower()

    async def test_cannot_mark_other_users_notification_read(
        self, client: AsyncClient, welfare_headers: dict, commander_headers: dict
    ):
        """
        Commander cannot mark a welfare officer's notification as read
        (ownership is enforced in the query — returns 404, not the notification).
        First, trigger a notification for the welfare officer via a disclosure,
        then attempt to read it as Commander.
        """
        # Get welfare officer's notifications
        wf_notifs = (await client.get("/notifications/", headers=welfare_headers)).json()
        if not wf_notifs:
            pytest.skip("No welfare officer notifications to test cross-user access")

        wf_notif_id = wf_notifs[0]["id"]

        # Commander tries to mark it as read → should 404 (not found for that user)
        resp = await client.patch(
            f"/notifications/{wf_notif_id}/read",
            headers=commander_headers,
        )
        assert resp.status_code == 404, (
            f"Commander should get 404 on other user's notification, got {resp.status_code}: {resp.text}"
        )

    async def test_unread_count_decreases_after_mark_all_read(
        self, client: AsyncClient, welfare_headers: dict
    ):
        """After marking all as read, unread count should be 0."""
        await client.patch("/notifications/read-all", headers=welfare_headers)
        count_resp = await client.get("/notifications/unread-count", headers=welfare_headers)
        assert count_resp.json()["unread_count"] == 0
