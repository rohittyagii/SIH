from __future__ import annotations
import uuid

from fastapi import APIRouter, HTTPException
from sqlalchemy import select, func

from app.dependencies import CurrentUser, RlsSession
from app.models.disclosure import Notification
from app.schemas.notification import NotificationResponse, UnreadCountResponse

router = APIRouter(prefix="/notifications", tags=["notifications"])

@router.get("/", response_model=list[NotificationResponse])
async def list_notifications(
    current_user: CurrentUser,
    db: RlsSession,
):
    res = await db.execute(
        select(Notification)
        .where(Notification.user_id == current_user.id)
        .order_by(Notification.created_at.desc())
        .limit(50)
    )
    notifications = res.scalars().all()
    return [
        NotificationResponse(
            id=str(n.id),
            user_id=str(n.user_id),
            notification_type=n.notification_type,
            title=n.title,
            message=n.message,
            related_entity_type=n.related_entity_type,
            related_entity_id=n.related_entity_id,
            is_read=n.is_read,
            created_at=n.created_at
        ) for n in notifications
    ]

@router.get("/unread-count", response_model=UnreadCountResponse)
async def unread_count(
    current_user: CurrentUser,
    db: RlsSession,
):
    res = await db.execute(
        select(func.count(Notification.id))
        .where(Notification.user_id == current_user.id, Notification.is_read == False)
    )
    count = res.scalar_one()
    return UnreadCountResponse(count=count)

@router.patch("/{id}/read", response_model=NotificationResponse)
async def mark_read(
    id: str,
    current_user: CurrentUser,
    db: RlsSession,
):
    res = await db.execute(
        select(Notification)
        .where(Notification.id == uuid.UUID(id), Notification.user_id == current_user.id)
    )
    notification = res.scalar_one_or_none()
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")
        
    notification.is_read = True
    await db.commit()
    await db.refresh(notification)
    
    return NotificationResponse(
        id=str(notification.id),
        user_id=str(notification.user_id),
        notification_type=notification.notification_type,
        title=notification.title,
        message=notification.message,
        related_entity_type=notification.related_entity_type,
        related_entity_id=notification.related_entity_id,
        is_read=notification.is_read,
        created_at=notification.created_at
    )

@router.patch("/read-all", response_model=dict)
async def mark_all_read(
    current_user: CurrentUser,
    db: RlsSession,
):
    res = await db.execute(
        select(Notification)
        .where(Notification.user_id == current_user.id, Notification.is_read == False)
    )
    notifications = res.scalars().all()
    for n in notifications:
        n.is_read = True
    await db.commit()
    return {"status": "ok"}
