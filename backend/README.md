# SainikSaathi Backend

**AI-Based Predictive Personnel Stress and Welfare Monitoring System — FastAPI Backend**

---

## Quick Start (Local Dev)

### Prerequisites
- Docker + Docker Compose
- Python 3.12+ (for running scripts outside Docker)

### 1. Clone and configure

```bash
cd backend
cp .env.example .env
# Edit .env — fill in JWT_SECRET_KEY and ENCRYPTION_MASTER_KEY
# Generate keys:
python -c "import secrets; print(secrets.token_hex(32))"
```

### 2. Start services

```bash
docker-compose up --build
```

API is now live at: **http://localhost:8000**
Swagger docs: **http://localhost:8000/docs**

### 2.5. Train ML models (required — run once per environment)

The trained model artifacts (`.joblib`) are gitignored and must be generated
locally before the "Run AI Assessment" button will use the real ML pipeline.

```bash
cd backend
.venv/bin/python -m app.ml.training.train_models
```

This reads `app/ml/training/training_data.csv` and saves three files into
`app/ml/models/`: `risk_classifier.joblib`, `resilience_regressor.joblib`,
and `feature_scaler.joblib`. The script takes ~30 seconds and only needs to
run once (or again after updating the training data).

Without these files the backend automatically falls back to a rule-based
assessment engine that still reads real data but produces less nuanced results.

### 3. Run migrations

```bash
# Inside the running container:
docker-compose exec api alembic upgrade head

# Or locally (with .env configured):
pip install -r requirements.txt
alembic upgrade head
```

### 4. Seed demo data

```bash
# Inside container:
docker-compose exec api python scripts/seed_db.py

# Or locally:
python scripts/seed_db.py
```

### 5. Test the dashboard

Start the Next.js dashboard:
```bash
cd ../web-dashboard
npm run dev
```
Open http://localhost:3000 and login with:
- **Commander**: `cmd_sharma` / `demo123`
- **Welfare Officer**: `wo_meera` / `demo123`

---

## Architecture

```
backend/
├── app/
│   ├── main.py              # FastAPI app, CORS, routers
│   ├── config.py            # Pydantic settings from .env
│   ├── database.py          # Async SQLAlchemy engine
│   ├── dependencies.py      # get_db, get_current_user, require_role
│   ├── models/              # ORM models (SQLAlchemy)
│   ├── schemas/             # Request/response Pydantic models
│   ├── routers/             # API endpoint handlers
│   ├── services/            # Business logic
│   ├── ml/                  # ML models and prediction engines
│   └── utils/               # JWT, encryption, etc.
├── alembic/                 # DB migrations
├── scripts/                 # seed_db.py, train_models.py
└── tests/                   # pytest test suite
```

---

## API Overview

| Category | Prefix | Description |
|---|---|---|
| Auth (dashboard) | `/auth/` | OAuth2 form login, `/auth/me` |
| Auth (mobile) | `/auth/mobile/` | Activate, login, change-pin |
| Wellness | `/wellness/` | Check-in CRUD, history, batch sync |
| Personnel | `/personnel/` | List + individual detail |
| HR Metrics | `/hr-metrics/` | Unit summaries |
| Assessments | `/assessments/` | Triage, trends, run AI, update status |
| Users | `/users/` | Preferences, export, delete |
| Support | `/support/` | Callback requests |
| Health | `/health/` | Liveness + readiness |

Full interactive docs: **http://localhost:8000/docs**

---

## Implementation Progress

### ✅ Phase 1 — Foundation (COMPLETE)
- [x] Project structure, Docker, requirements
- [x] Config (Pydantic Settings + .env)
- [x] Database (async SQLAlchemy + Alembic migrations)
- [x] All ORM models (User, Unit, ActivationCode, WellnessCheckin, HRMetrics, AIAssessment, SupportRequest, AuditLog)
- [x] Auth router (`/auth/login`, `/auth/me`, mobile endpoints)
- [x] Security utils (JWT, bcrypt, AES-256-GCM encryption)
- [x] FastAPI app with CORS
- [x] Seed script (50 personnel, 30d history, simulated HRV, AI assessments)

### 🔲 Phase 2 — Dashboard API
- [ ] `/wellness/` router (checkin CRUD)
- [ ] `/personnel/` router
- [ ] `/hr-metrics/unit-summary` router
- [ ] `/assessments/` router (triage, trends, run, action)

### 🔲 Phase 3 — ML Engine
- [ ] `ml/risk_predictor.py`
- [ ] `ml/resilience_scorer.py`
- [ ] `ml/trend_analyzer.py`
- [ ] `scripts/train_models.py`

### 🔲 Phase 4 — Mobile API
- [ ] `/users/` router (preferences, export, delete)
- [ ] `/support/` router

### 🔲 Phase 5 — Flutter Integration
- [ ] Dart service layer (api_client, auth_service, checkin_service)
- [ ] Screen wiring

### 🔲 Phase 6 — Deploy
- [ ] Cloud PostgreSQL (Supabase/Neon)
- [ ] Railway/Render deployment

---

## For Gemini — Resuming from Phase 2

If you are picking this up after Phase 1, here is exactly what to build next.

### Context
- **Flutter app** (at `../lib/`) uses 4 wellness dimensions: `overall_score`, `sleep_score`, `physical_score`, `focus_score` (int 1-5)
- **Web dashboard** (at `../web-dashboard/`) expects these exact endpoints at `http://localhost:8000`:
  - `GET /personnel/` — list with `?unit=` filter
  - `GET /personnel/{id}` — full nested object (see schema below)
  - `GET /hr-metrics/unit-summary` — aggregated per unit
  - `GET /assessments/triage` — priority sorted, Intervention first
  - `GET /assessments/trends` — 26-week `{date, avg_mood, intervention, monitor}` array
  - `POST /assessments/run/{personnelId}` — triggers ML assessment
  - `POST /assessments/run-unit?unit={unit}` — batch
  - `PATCH /assessments/{id}/action` — `{"status": "Acknowledged"}` or `{"status": "Action_Taken"}`
  - `POST /wellness/checkin` — from Flutter
  - `GET /wellness/history?limit=30` — from Flutter

### `/personnel/{id}` response contract
```json
{
  "user": {"id": "...", "full_name": "...", "service_id": "...", "unit": "...", "role": "..."},
  "hr_metrics": {"avg_weekly_duty_hours": 58.5, "days_since_last_leave": 114, "deployment_history_months": 18},
  "recent_wellness": [
    {"timestamp": "2026-09-01T06:30:00Z", "self_reported_mood": 8, "sleep_score": 6, "subjective_fatigue_level": 7, "hrv_baseline_deviation": 22.4}
  ],
  "assessments": [
    {"assessment_id": "...", "risk_level": "Intervention_Recommended", "contributing_factors": "...", "recommended_intervention": "...", "status": "Pending", "created_at": "..."}
  ]
}
```

### Key files to read first
1. `app/models/__init__.py` — all models
2. `app/dependencies.py` — CurrentUser, OfficerOrAbove, DbSession
3. `app/schemas/auth.py` — UserProfile schema pattern to follow
4. `app/models/assessment.py` — AIAssessment, AssessmentStatus enum
5. `app/models/hr_metrics.py` — HRMetrics fields
6. `app/main.py` — how to register new routers

### Where to add new routers
In `app/main.py`, uncomment the relevant import and `app.include_router(...)` lines.

### ML Assessment Logic (for Phase 3)
Resilience score formula (must match dashboard exactly):
```python
resilience = max(15, min(98, (mood * 5) + (sleep * 3) - (fatigue * 2) + 20))
```
Risk classification rules:
- `Intervention_Recommended`: HRV > 25% AND leave > 120d, OR 3+ consecutive days avg ≤ 2, OR avg_overall < 2.0
- `Monitor`: HRV > 15% AND leave > 80d, OR avg_overall < 3.0, OR duty > 58h/wk
- `Routine`: everything else

---

## Tests

```bash
# Install test deps
pip install pytest pytest-asyncio pytest-cov httpx

# Run all tests
pytest tests/ -v --cov=app --cov-report=term-missing

# Run specific test file
pytest tests/test_auth.py -v
```

---

## Cloud Setup (Supabase)

1. Go to https://supabase.com → New project → Free tier
2. Project Settings → Database → Connection string (URI mode)
3. Copy the URI and update `DATABASE_URL` in `.env`:
   ```
   DATABASE_URL=postgresql+asyncpg://postgres:<password>@db.<project-ref>.supabase.co:5432/postgres
   ```
4. Run migrations: `alembic upgrade head`
5. Run seed: `python scripts/seed_db.py`

---

## Environment Variables Reference

| Variable | Description | Example |
|---|---|---|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql+asyncpg://...` |
| `REDIS_URL` | Redis connection string | `redis://localhost:6379/0` |
| `JWT_SECRET_KEY` | 64-char hex secret for JWT signing | `python -c "import secrets; print(secrets.token_hex(32))"` |
| `JWT_ALGORITHM` | JWT algorithm | `HS256` |
| `JWT_EXPIRY_MINUTES` | Access token lifetime | `60` |
| `ENCRYPTION_MASTER_KEY` | AES-256 master key (32 hex bytes) | `python -c "import secrets; print(secrets.token_hex(32))"` |
| `CORS_ORIGINS` | Comma-separated allowed origins | `http://localhost:3000` |
