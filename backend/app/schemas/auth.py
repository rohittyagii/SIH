"""Pydantic schemas for auth endpoints."""
from pydantic import BaseModel, Field
from app.models.user import UserRole


# ── Shared ────────────────────────────────────────────────────────────────────

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UserProfile(BaseModel):
    """Response for GET /auth/me — matches exactly what the web dashboard expects."""
    id: str
    username: str
    role: str
    unit: str
    full_name: str
    service_id: str

    model_config = {"from_attributes": True}


# ── Dashboard auth (OAuth2 password-grant, form-urlencoded) ───────────────────
# FastAPI's OAuth2PasswordRequestForm handles the form parsing automatically


# ── Mobile auth ───────────────────────────────────────────────────────────────

class MobileActivateRequest(BaseModel):
    activation_code: str = Field(..., pattern=r"^[A-Z0-9]{4}-[A-Z0-9]{4}$", examples=["ABCD-1234"])
    pin: str = Field(..., min_length=6, max_length=6, pattern=r"^\d{6}$")
    # These come from the Flutter ActivationScreen
    full_name: str = Field(..., min_length=2, max_length=150)


class MobileLoginRequest(BaseModel):
    service_id: str
    pin: str = Field(..., min_length=6, max_length=6, pattern=r"^\d{6}$")


class MobileLoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserProfile


class ChangePinRequest(BaseModel):
    current_pin: str = Field(..., min_length=6, max_length=6)
    new_pin: str = Field(..., min_length=6, max_length=6)
