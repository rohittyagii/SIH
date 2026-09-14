from __future__ import annotations
"""FastAPI application entry point."""
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.routers import auth, health, wellness, personnel, hr_metrics, assessments, users, support, disclosures, notifications
from app.ml.predictor import predictor
from app.ml.feature_engineering import FEATURE_NAMES

settings = get_settings()
_ml_logger = logging.getLogger("app.ml")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Load ML models at startup; clean up on shutdown."""
    if predictor.load_models():
        _ml_logger.info("ML models loaded successfully")
    else:
        _ml_logger.warning("ML models not available — using rule-based fallback")
    yield


app = FastAPI(
    title="SainikSaathi API",
    description=(
        "AI-Based Predictive Personnel Stress and Welfare Monitoring System — "
        "Backend API serving both the Flutter mobile app and Next.js web dashboard."
    ),
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
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
app.include_router(notifications.router, prefix="/api/v1")

# ── Unversioned routes — web dashboard compatibility ─────────────────────────
# Dashboard expects /auth/login, /auth/me, /personnel/, /assessments/*, etc.
app.include_router(auth.router)
app.include_router(personnel.router)
app.include_router(hr_metrics.router)
app.include_router(assessments.router)
app.include_router(disclosures.router)
app.include_router(notifications.router)
app.include_router(health.router)



@app.get('/api/v1/ml/status')
async def ml_status():
    import json, os
    metadata = {}
    meta_path = os.path.join(os.path.dirname(__file__), 'ml', 'models', 'model_metadata.json')
    if os.path.exists(meta_path):
        with open(meta_path) as f:
            metadata = json.load(f)
    return {
        'models_loaded': predictor.is_loaded,
        'feature_names': FEATURE_NAMES,
        'metadata': metadata,
    }


import traceback
from fastapi import Request
from fastapi.responses import JSONResponse

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=500,
        content={"error": type(exc).__name__, "detail": str(exc), "trace": traceback.format_exc()},
    )

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
