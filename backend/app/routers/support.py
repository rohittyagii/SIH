"""Support router — callback requests (Flutter app)."""
import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, status
from pydantic import BaseModel
from sqlalchemy import select

from app.dependencies import CurrentUser, DbSession
from app.models.assessment import SupportRequest

router = APIRouter(prefix="/support", tags=["support"])


class CallbackRequest(BaseModel):
    request_type: str = "Callback"
    notes: str | None = None


@router.post("/callback", status_code=status.HTTP_201_CREATED)
async def request_callback(body: CallbackRequest, current_user: CurrentUser, db: DbSession):
    """Submit a welfare callback/counseling request from the Flutter app."""
    req = SupportRequest(
        id=uuid.uuid4(),
        user_id=current_user.id,
        request_type=body.request_type,
        status="Pending",
        notes=body.notes,
        created_at=datetime.now(timezone.utc),
    )
    db.add(req)
    await db.flush()
    return {"id": str(req.id), "status": "Pending", "message": "Support request submitted"}


@router.get("/requests")
async def get_my_requests(current_user: CurrentUser, db: DbSession):
    """List own support requests."""
    result = await db.execute(
        select(SupportRequest)
        .where(SupportRequest.user_id == current_user.id)
        .order_by(SupportRequest.created_at.desc())
    )
    requests = result.scalars().all()
    return [
        {
            "id": str(r.id),
            "request_type": r.request_type,
            "status": r.status,
            "notes": r.notes,
            "created_at": r.created_at.isoformat(),
        }
        for r in requests
    ]
