from __future__ import annotations
"""FastAPI application entry point."""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.routers import auth, health, wellness, personnel, hr_metrics, assessments, users, support

settings = get_settings()

app = FastAPI(
    title="SainikSaathi API",
    description=(
        "AI-Based Predictive Personnel Stress and Welfare Monitoring System — "
        "Backend API serving both the Flutter mobile app and Next.js web dashboard."
    ),
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# ── CORS ──────────────────────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Versioned API routes (/api/v1/*) — Flutter app ───────────────────────────
app.include_router(auth.router, prefix="/api/v1")
app.include_router(wellness.router, prefix="/api/v1")
app.include_router(users.router, prefix="/api/v1")
app.include_router(support.router, prefix="/api/v1")
app.include_router(health.router, prefix="/api/v1")

# ── Unversioned routes — web dashboard compatibility ─────────────────────────
# Dashboard expects /auth/login, /auth/me, /personnel/, /assessments/*, etc.
app.include_router(auth.router)
app.include_router(personnel.router)
app.include_router(hr_metrics.router)
app.include_router(assessments.router)
app.include_router(health.router)


@app.get("/")
async def root():
    return {
        "name": "SainikSaathi API",
        "version": "1.0.0",
        "docs": "/docs",
        "status": "running",
        "endpoints": {
            "auth": "/auth/login, /auth/me",
            "mobile": "/api/v1/auth/mobile/*, /api/v1/wellness/*, /api/v1/users/*",
            "dashboard": "/personnel/, /hr-metrics/, /assessments/*",
        },
    }
