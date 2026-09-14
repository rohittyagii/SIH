from __future__ import annotations
"""Notifications router — in-app notification feed for all roles."""
from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import select, update, func

from app.dependencies import CurrentUser, DbSession
from app.models.notification import Notification
from app.schemas.notification import NotificationResponse, UnreadCountResponse

router = APIRouter(prefix="/notifications", tags=["notifications"])


# ── GET /notifications/ ────────────────────────────────────────────────────────

@router.get("/", response_model=list[NotificationResponse])
async def list_notifications(
    current_user: CurrentUser,
    db: DbSession,
    unread_only: bool = Query(False),
    limit: int = Query(50, le=200),
    offset: int = Query(0, ge=0),
):
    """List the current user's notifications, newest first. RLS enforces ownership."""
    q = select(Notification).where(Notification.user_id == current_user.id)
    if unread_only:
        q = q.where(Notification.is_read == False)
    q = q.order_by(Notification.created_at.desc()).limit(limit).offset(offset)

    result = await db.execute(q)
    notifications = result.scalars().all()
    return [
        NotificationResponse(
            id=str(n.id),
            user_id=str(n.user_id),
            title=n.title,
            body=n.body,
            notification_type=n.notification_type.value,
            related_entity_id=n.related_entity_id,
            is_read=n.is_read,
            created_at=n.created_at,
        )
        for n in notifications
    ]


# ── GET /notifications/unread-count ───────────────────────────────────────────

@router.get("/unread-count", response_model=UnreadCountResponse)
async def unread_count(current_user: CurrentUser, db: DbSession):
    """Return the badge count (number of unread notifications)."""
    res = await db.execute(
        select(func.count(Notification.id)).where(
            Notification.user_id == current_user.id,
            Notification.is_read == False,
        )
    )
    count = res.scalar_one() or 0
    return UnreadCountResponse(unread_count=count)


# ── PATCH /notifications/{id}/read ────────────────────────────────────────────

@router.patch("/{notification_id}/read", response_model=NotificationResponse)
async def mark_read(
    notification_id: str,
    current_user: CurrentUser,
    db: DbSession,
):
    """Mark a single notification as read. Users can only mark their own."""
    res = await db.execute(
        select(Notification).where(
            Notification.id == notification_id,
            Notification.user_id == current_user.id,
        )
    )
    notif = res.scalar_one_or_none()
    if not notif:
        raise HTTPException(status_code=404, detail="Notification not found")

    notif.is_read = True
    return NotificationResponse(
        id=str(notif.id),
        user_id=str(notif.user_id),
        title=notif.title,
        body=notif.body,
        notification_type=notif.notification_type.value,
        related_entity_id=notif.related_entity_id,
        is_read=notif.is_read,
        created_at=notif.created_at,
    )


# ── PATCH /notifications/read-all ─────────────────────────────────────────────

@router.patch("/read-all")
async def mark_all_read(current_user: CurrentUser, db: DbSession):
    """Mark all of the current user's notifications as read."""
    await db.execute(
        update(Notification)
        .where(Notification.user_id == current_user.id, Notification.is_read == False)
        .values(is_read=True)
    )
    return {"message": "All notifications marked as read"}
