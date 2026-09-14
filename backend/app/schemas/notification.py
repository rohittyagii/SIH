from __future__ import annotations
from datetime import datetime
from typing import Optional
from pydantic import BaseModel

class NotificationResponse(BaseModel):
    id: str
    user_id: str
    notification_type: str
    title: str
    message: str
    related_entity_type: Optional[str] = None
    related_entity_id: Optional[str] = None
    is_read: bool
    created_at: datetime

class NotificationMarkRead(BaseModel):
    notification_ids: list[str]

class UnreadCountResponse(BaseModel):
    unread_count: int
