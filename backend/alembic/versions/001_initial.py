"""Initial schema — all tables (pure SQL, no SQLAlchemy Enum object)

Revision ID: 001_initial
Revises:
Create Date: 2026-09-06
"""
from typing import Sequence, Union
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "001_initial"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Write all DDL as raw SQL — avoids SQLAlchemy's Enum auto-create behaviour
    # which can't be reliably suppressed on older SQLAlchemy+asyncpg combos.
    op.execute("""
        DO $$ BEGIN
            CREATE TYPE userrole AS ENUM ('Personnel', 'Welfare_Officer', 'Commander', 'Admin');
        EXCEPTION WHEN duplicate_object THEN NULL; END $$;

        DO $$ BEGIN
            CREATE TYPE risklevel AS ENUM ('Routine', 'Monitor', 'Intervention_Recommended');
        EXCEPTION WHEN duplicate_object THEN NULL; END $$;

        DO $$ BEGIN
            CREATE TYPE assessmentstatus AS ENUM ('Pending', 'Acknowledged', 'Action_Taken');
        EXCEPTION WHEN duplicate_object THEN NULL; END $$;

        CREATE TABLE IF NOT EXISTS units (
            id UUID PRIMARY KEY,
            name VARCHAR(120) NOT NULL UNIQUE,
            parent_unit_id UUID REFERENCES units(id),
            created_at TIMESTAMPTZ NOT NULL
        );

        CREATE TABLE IF NOT EXISTS users (
            id UUID PRIMARY KEY,
            service_id VARCHAR(50) NOT NULL UNIQUE,
            username VARCHAR(80) NOT NULL UNIQUE,
            full_name VARCHAR(150) NOT NULL,
            unit_id UUID NOT NULL REFERENCES units(id),
            pin_hash VARCHAR(255) NOT NULL,
            role userrole NOT NULL,
            is_active BOOLEAN NOT NULL DEFAULT TRUE,
            consent_given BOOLEAN NOT NULL DEFAULT FALSE,
            consent_given_at TIMESTAMPTZ,
            language_pref VARCHAR(10) NOT NULL DEFAULT 'en-GB',
            theme_dark BOOLEAN NOT NULL DEFAULT TRUE,
            notif_daily_reminder BOOLEAN NOT NULL DEFAULT TRUE,
            notif_sync_alerts BOOLEAN NOT NULL DEFAULT TRUE,
            notif_weekly_summary BOOLEAN NOT NULL DEFAULT FALSE,
            created_at TIMESTAMPTZ NOT NULL,
            updated_at TIMESTAMPTZ NOT NULL
        );
        CREATE INDEX IF NOT EXISTS ix_users_username ON users(username);
        CREATE INDEX IF NOT EXISTS ix_users_service_id ON users(service_id);

        CREATE TABLE IF NOT EXISTS activation_codes (
            id UUID PRIMARY KEY,
            code VARCHAR(9) NOT NULL UNIQUE,
            unit_id UUID NOT NULL REFERENCES units(id),
            is_used BOOLEAN NOT NULL DEFAULT FALSE,
            created_at TIMESTAMPTZ NOT NULL,
            used_at TIMESTAMPTZ
        );

        CREATE TABLE IF NOT EXISTS wellness_checkins (
            id UUID PRIMARY KEY,
            user_id UUID NOT NULL REFERENCES users(id),
            checkin_date DATE NOT NULL,
            overall_score INTEGER NOT NULL,
            sleep_score INTEGER NOT NULL,
            physical_score INTEGER NOT NULL,
            focus_score INTEGER NOT NULL,
            average_score FLOAT NOT NULL,
            note_encrypted BYTEA,
            risk_level risklevel NOT NULL,
            created_at TIMESTAMPTZ NOT NULL,
            CONSTRAINT uq_checkin_user_date UNIQUE(user_id, checkin_date)
        );
        CREATE INDEX IF NOT EXISTS ix_checkins_user_date ON wellness_checkins(user_id, checkin_date);
        CREATE INDEX IF NOT EXISTS ix_checkins_risk ON wellness_checkins(risk_level);

        CREATE TABLE IF NOT EXISTS hr_metrics (
            id UUID PRIMARY KEY,
            user_id UUID NOT NULL UNIQUE REFERENCES users(id),
            avg_weekly_duty_hours FLOAT NOT NULL DEFAULT 48.0,
            days_since_last_leave INTEGER NOT NULL DEFAULT 0,
            deployment_history_months INTEGER NOT NULL DEFAULT 0,
            hrv_baseline_deviation FLOAT NOT NULL DEFAULT 0.0,
            avg_mood_score FLOAT NOT NULL DEFAULT 5.0,
            avg_sleep_recovery FLOAT NOT NULL DEFAULT 5.0,
            avg_fatigue_level FLOAT NOT NULL DEFAULT 5.0,
            last_updated TIMESTAMPTZ NOT NULL
        );

        CREATE TABLE IF NOT EXISTS ai_assessments (
            id UUID PRIMARY KEY,
            user_id UUID NOT NULL REFERENCES users(id),
            unit_id UUID NOT NULL REFERENCES units(id),
            risk_level risklevel NOT NULL,
            resilience_score INTEGER NOT NULL,
            mood_score FLOAT NOT NULL,
            sleep_recovery FLOAT NOT NULL,
            fatigue_level FLOAT NOT NULL,
            hrv_baseline_deviation FLOAT NOT NULL,
            contributing_factors TEXT NOT NULL,
            recommended_intervention TEXT NOT NULL,
            ai_narrative TEXT NOT NULL,
            status assessmentstatus NOT NULL,
            acknowledged_by UUID REFERENCES users(id),
            resolved_at TIMESTAMPTZ,
            created_at TIMESTAMPTZ NOT NULL
        );
        CREATE INDEX IF NOT EXISTS ix_assessments_user ON ai_assessments(user_id);
        CREATE INDEX IF NOT EXISTS ix_assessments_status ON ai_assessments(status);
        CREATE INDEX IF NOT EXISTS ix_assessments_risk ON ai_assessments(risk_level);

        CREATE TABLE IF NOT EXISTS support_requests (
            id UUID PRIMARY KEY,
            user_id UUID NOT NULL REFERENCES users(id),
            request_type VARCHAR(30) NOT NULL DEFAULT 'Callback',
            status VARCHAR(20) NOT NULL DEFAULT 'Pending',
            notes TEXT,
            created_at TIMESTAMPTZ NOT NULL
        );

        CREATE TABLE IF NOT EXISTS audit_logs (
            id UUID PRIMARY KEY,
            actor_id UUID NOT NULL REFERENCES users(id),
            action VARCHAR(100) NOT NULL,
            resource_type VARCHAR(50) NOT NULL,
            resource_id VARCHAR(36),
            ip_address VARCHAR(45),
            created_at TIMESTAMPTZ NOT NULL
        );
        CREATE INDEX IF NOT EXISTS ix_audit_actor ON audit_logs(actor_id);
        CREATE INDEX IF NOT EXISTS ix_audit_created ON audit_logs(created_at);
    """)


def downgrade() -> None:
    op.execute("""
        DROP TABLE IF EXISTS audit_logs;
        DROP TABLE IF EXISTS support_requests;
        DROP TABLE IF EXISTS ai_assessments;
        DROP TABLE IF EXISTS hr_metrics;
        DROP TABLE IF EXISTS wellness_checkins;
        DROP TABLE IF EXISTS activation_codes;
        DROP TABLE IF EXISTS users;
        DROP TABLE IF EXISTS units;
        DROP TYPE IF EXISTS assessmentstatus;
        DROP TYPE IF EXISTS risklevel;
        DROP TYPE IF EXISTS userrole;
    """)
