"""Role separation — PostgreSQL RLS, app roles, disclosure_requests, notifications tables

Revision ID: 002_role_separation
Revises: 001_initial
Create Date: 2026-09-14
"""
from typing import Sequence, Union
from alembic import op

revision: str = "002_role_separation"
down_revision: Union[str, None] = "001_initial"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("""
        -- ── 1. New tables: disclosure_requests & notifications ────────────────

        DO $$ BEGIN
            CREATE TYPE disclosurereason AS ENUM (
                'IMMINENT_RISK', 'WELFARE_CONCERN', 'INVESTIGATION', 'MEDICAL_EMERGENCY'
            );
        EXCEPTION WHEN duplicate_object THEN NULL; END $$;

        DO $$ BEGIN
            CREATE TYPE disclosurestatus AS ENUM (
                'PENDING', 'APPROVED', 'DENIED', 'EXPIRED'
            );
        EXCEPTION WHEN duplicate_object THEN NULL; END $$;

        CREATE TABLE IF NOT EXISTS disclosure_requests (
            id                  UUID PRIMARY KEY,
            requesting_officer_id UUID NOT NULL REFERENCES users(id),
            approving_officer_id  UUID REFERENCES users(id),         -- NULL until reviewed
            target_user_id      UUID NOT NULL REFERENCES users(id),
            reason              disclosurereason NOT NULL,
            status              disclosurestatus NOT NULL DEFAULT 'PENDING',
            scope               VARCHAR(120) NOT NULL DEFAULT 'wellness,assessments',
            justification       TEXT,
            expires_at          TIMESTAMPTZ,                          -- Set on approval (now + 48h)
            created_at          TIMESTAMPTZ NOT NULL,
            reviewed_at         TIMESTAMPTZ
        );
        CREATE INDEX IF NOT EXISTS ix_disclosures_requesting ON disclosure_requests(requesting_officer_id);
        CREATE INDEX IF NOT EXISTS ix_disclosures_target     ON disclosure_requests(target_user_id);
        CREATE INDEX IF NOT EXISTS ix_disclosures_status     ON disclosure_requests(status);

        DO $$ BEGIN
            CREATE TYPE notificationtype AS ENUM (
                'DISCLOSURE_REQUESTED',
                'DISCLOSURE_APPROVED',
                'DISCLOSURE_DENIED',
                'DISCLOSURE_EXPIRED',
                'DATA_ACCESSED',
                'ASSESSMENT_UPDATED',
                'SYSTEM'
            );
        EXCEPTION WHEN duplicate_object THEN NULL; END $$;

        CREATE TABLE IF NOT EXISTS notifications (
            id                  UUID PRIMARY KEY,
            user_id             UUID NOT NULL REFERENCES users(id),
            title               VARCHAR(200) NOT NULL,
            body                TEXT NOT NULL,
            notification_type   notificationtype NOT NULL DEFAULT 'SYSTEM',
            related_entity_id   VARCHAR(36),         -- disclosure_requests.id or assessment.id
            is_read             BOOLEAN NOT NULL DEFAULT FALSE,
            created_at          TIMESTAMPTZ NOT NULL
        );
        CREATE INDEX IF NOT EXISTS ix_notifications_user    ON notifications(user_id);
        CREATE INDEX IF NOT EXISTS ix_notifications_unread  ON notifications(user_id, is_read);

        -- ── 2. Application-level PostgreSQL roles ────────────────────────────────
        -- These roles are switched into via SET LOCAL ROLE on each transaction.
        -- They hold the minimum privilege needed to do their job.

        DO $$ BEGIN
            CREATE ROLE app_welfare  NOLOGIN;
        EXCEPTION WHEN duplicate_object THEN NULL; END $$;

        DO $$ BEGIN
            CREATE ROLE app_commander NOLOGIN;
        EXCEPTION WHEN duplicate_object THEN NULL; END $$;

        DO $$ BEGIN
            CREATE ROLE app_personnel NOLOGIN;
        EXCEPTION WHEN duplicate_object THEN NULL; END $$;

        -- Grant connect/usage to the roles (they inherit from the login user)
        GRANT USAGE ON SCHEMA public TO app_welfare, app_commander, app_personnel;

        -- app_welfare: full read/write on all tables (care providers)
        GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public
            TO app_welfare;
        GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_welfare;

        -- app_commander: read-only on non-sensitive aggregate tables only;
        --   explicitly blocked from individual wellness/assessment rows via RLS
        GRANT SELECT ON units, users, hr_metrics, audit_logs TO app_commander;
        -- commanders also need to read ai_assessments for aggregate/trends (via bypass session)
        GRANT SELECT ON ai_assessments, wellness_checkins TO app_commander;

        -- app_personnel: own rows only (enforced by RLS below)
        GRANT SELECT, INSERT ON wellness_checkins, support_requests TO app_personnel;
        GRANT SELECT, UPDATE ON users TO app_personnel;
        GRANT SELECT ON units, hr_metrics TO app_personnel;
        GRANT SELECT ON notifications TO app_personnel;
        GRANT UPDATE ON notifications TO app_personnel;
        GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_personnel;

        -- ── 3. Enable Row Level Security on sensitive tables ───────────────────
        -- FORCE applies RLS to table owners too (important for migrations/seeds
        -- run as the same user that owns the table).

        ALTER TABLE wellness_checkins        ENABLE ROW LEVEL SECURITY;
        ALTER TABLE wellness_checkins        FORCE  ROW LEVEL SECURITY;

        ALTER TABLE ai_assessments           ENABLE ROW LEVEL SECURITY;
        ALTER TABLE ai_assessments           FORCE  ROW LEVEL SECURITY;

        ALTER TABLE support_requests         ENABLE ROW LEVEL SECURITY;
        ALTER TABLE support_requests         FORCE  ROW LEVEL SECURITY;

        ALTER TABLE notifications            ENABLE ROW LEVEL SECURITY;
        ALTER TABLE notifications            FORCE  ROW LEVEL SECURITY;

        -- ── 4. RLS Policies ──────────────────────────────────────────────────
        -- Each policy uses current_setting('app.current_user_id', TRUE) which is
        -- injected per-transaction by database.py via SET LOCAL app.current_user_id.
        -- TRUE = return NULL (not error) when the setting is missing.

        -- ── wellness_checkins ─────────────────────────────────────────────────

        -- Welfare officers see every row
        DROP POLICY IF EXISTS wc_welfare_all ON wellness_checkins;
        CREATE POLICY wc_welfare_all ON wellness_checkins
            FOR ALL
            TO app_welfare
            USING (TRUE)
            WITH CHECK (TRUE);

        -- Personnel see only their own rows
        DROP POLICY IF EXISTS wc_personnel_own ON wellness_checkins;
        CREATE POLICY wc_personnel_own ON wellness_checkins
            FOR ALL
            TO app_personnel
            USING (user_id::text = current_setting('app.current_user_id', TRUE))
            WITH CHECK (user_id::text = current_setting('app.current_user_id', TRUE));

        -- ── ai_assessments ────────────────────────────────────────────────────

        DROP POLICY IF EXISTS aa_welfare_all ON ai_assessments;
        CREATE POLICY aa_welfare_all ON ai_assessments
            FOR ALL
            TO app_welfare
            USING (TRUE)
            WITH CHECK (TRUE);

        -- ── support_requests ──────────────────────────────────────────────────

        DROP POLICY IF EXISTS sr_welfare_all ON support_requests;
        CREATE POLICY sr_welfare_all ON support_requests
            FOR ALL
            TO app_welfare
            USING (TRUE)
            WITH CHECK (TRUE);

        DROP POLICY IF EXISTS sr_personnel_own ON support_requests;
        CREATE POLICY sr_personnel_own ON support_requests
            FOR ALL
            TO app_personnel
            USING (user_id::text = current_setting('app.current_user_id', TRUE))
            WITH CHECK (user_id::text = current_setting('app.current_user_id', TRUE));

        -- ── notifications ─────────────────────────────────────────────────────

        DROP POLICY IF EXISTS notif_own ON notifications;
        CREATE POLICY notif_own ON notifications
            FOR ALL
            TO app_personnel, app_welfare, app_commander
            USING (user_id::text = current_setting('app.current_user_id', TRUE))
            WITH CHECK (user_id::text = current_setting('app.current_user_id', TRUE));

        -- Welfare officers bypass notification RLS so they can INSERT for other users
        DROP POLICY IF EXISTS notif_welfare_all ON notifications;
        CREATE POLICY notif_welfare_all ON notifications
            FOR ALL
            TO app_welfare
            USING (TRUE)
            WITH CHECK (TRUE);

        -- Ensure future tables get permissions too
        ALTER DEFAULT PRIVILEGES IN SCHEMA public
            GRANT SELECT ON TABLES TO app_commander;
    """)


def downgrade() -> None:
    op.execute("""
        -- Drop new tables
        DROP TABLE IF EXISTS notifications;
        DROP TABLE IF EXISTS disclosure_requests;

        -- Drop new types
        DROP TYPE IF EXISTS notificationtype;
        DROP TYPE IF EXISTS disclosurestatus;
        DROP TYPE IF EXISTS disclosurereason;

        -- Disable RLS
        ALTER TABLE IF EXISTS wellness_checkins  DISABLE ROW LEVEL SECURITY;
        ALTER TABLE IF EXISTS ai_assessments     DISABLE ROW LEVEL SECURITY;
        ALTER TABLE IF EXISTS support_requests   DISABLE ROW LEVEL SECURITY;

        -- Drop RLS policies
        DROP POLICY IF EXISTS wc_welfare_all     ON wellness_checkins;
        DROP POLICY IF EXISTS wc_personnel_own   ON wellness_checkins;
        DROP POLICY IF EXISTS aa_welfare_all     ON ai_assessments;
        DROP POLICY IF EXISTS sr_welfare_all     ON support_requests;
        DROP POLICY IF EXISTS sr_personnel_own   ON support_requests;
        DROP POLICY IF EXISTS notif_own          ON notifications;
        DROP POLICY IF EXISTS notif_welfare_all  ON notifications;

        -- Drop app roles
        DROP ROLE IF EXISTS app_welfare;
        DROP ROLE IF EXISTS app_commander;
        DROP ROLE IF EXISTS app_personnel;
    """)
