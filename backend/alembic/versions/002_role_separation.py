"""Role separation — RLS, disclosure_requests, notifications

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
        -- ================================================================
        -- 1. PostgreSQL application roles (NOLOGIN — used via SET LOCAL ROLE)
        -- ================================================================
        DO $$ BEGIN CREATE ROLE app_welfare NOLOGIN; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
        DO $$ BEGIN CREATE ROLE app_commander NOLOGIN; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
        DO $$ BEGIN CREATE ROLE app_personnel NOLOGIN; EXCEPTION WHEN duplicate_object THEN NULL; END $$;

        -- Allow the connection user (postgres) to assume these roles
        GRANT app_welfare TO CURRENT_USER;
        GRANT app_commander TO CURRENT_USER;
        GRANT app_personnel TO CURRENT_USER;

        -- ================================================================
        -- 2. New ENUMs
        -- ================================================================
        DO $$ BEGIN
            CREATE TYPE justificationcategory AS ENUM (
                'IMMINENT_RISK', 'INDIVIDUAL_CONSENT',
                'OPERATIONAL_NECESSITY', 'LEGAL_MANDATE'
            );
        EXCEPTION WHEN duplicate_object THEN NULL; END $$;

        DO $$ BEGIN
            CREATE TYPE disclosurestatus AS ENUM (
                'PENDING_INITIATOR', 'PENDING_APPROVER',
                'APPROVED', 'DENIED', 'EXPIRED'
            );
        EXCEPTION WHEN duplicate_object THEN NULL; END $$;

        -- ================================================================
        -- 3. New tables
        -- ================================================================

        -- disclosure_requests
        CREATE TABLE IF NOT EXISTS disclosure_requests (
            id UUID PRIMARY KEY,
            requesting_officer_id UUID NOT NULL REFERENCES users(id),
            subject_user_id UUID NOT NULL REFERENCES users(id),
            justification_category justificationcategory NOT NULL,
            justification_text TEXT NOT NULL,
            initiator_approved_at TIMESTAMPTZ,
            approver_id UUID REFERENCES users(id),
            approver_decided_at TIMESTAMPTZ,
            status disclosurestatus NOT NULL DEFAULT 'PENDING_INITIATOR',
            disclosed_data_scope TEXT NOT NULL DEFAULT '{}',
            expires_at TIMESTAMPTZ,
            created_at TIMESTAMPTZ NOT NULL
        );
        CREATE INDEX IF NOT EXISTS ix_disclosure_status ON disclosure_requests(status);
        CREATE INDEX IF NOT EXISTS ix_disclosure_officer ON disclosure_requests(requesting_officer_id);
        CREATE INDEX IF NOT EXISTS ix_disclosure_subject ON disclosure_requests(subject_user_id);

        -- notifications
        CREATE TABLE IF NOT EXISTS notifications (
            id UUID PRIMARY KEY,
            user_id UUID NOT NULL REFERENCES users(id),
            notification_type VARCHAR(50) NOT NULL,
            title VARCHAR(200) NOT NULL,
            message TEXT NOT NULL,
            related_entity_type VARCHAR(50),
            related_entity_id VARCHAR(36),
            is_read BOOLEAN NOT NULL DEFAULT FALSE,
            created_at TIMESTAMPTZ NOT NULL
        );
        CREATE INDEX IF NOT EXISTS ix_notif_user ON notifications(user_id);
        CREATE INDEX IF NOT EXISTS ix_notif_unread ON notifications(user_id, is_read) WHERE NOT is_read;

        -- ================================================================
        -- 4. Extend audit_logs with disclosure-specific columns
        -- ================================================================
        ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS justification_category VARCHAR(30);
        ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS initiator_id UUID REFERENCES users(id);
        ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS approver_id UUID REFERENCES users(id);
        ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS disclosure_request_id UUID REFERENCES disclosure_requests(id);

        -- ================================================================
        -- 5. Table-level GRANTs
        -- ================================================================

        -- All roles can read units and users (for JOINs / lookups)
        GRANT SELECT ON units TO app_welfare, app_commander, app_personnel;
        GRANT SELECT ON users TO app_welfare, app_commander, app_personnel;

        -- wellness_checkins
        GRANT SELECT, INSERT, UPDATE ON wellness_checkins TO app_welfare;
        GRANT SELECT, INSERT, UPDATE ON wellness_checkins TO app_personnel;
        -- commander: no grant on wellness_checkins

        -- ai_assessments
        GRANT SELECT, INSERT, UPDATE ON ai_assessments TO app_welfare;
        GRANT SELECT ON ai_assessments TO app_commander;
        -- commander SELECT is granted but RLS will block all individual rows

        -- hr_metrics
        GRANT SELECT, INSERT, UPDATE ON hr_metrics TO app_welfare;
        GRANT SELECT ON hr_metrics TO app_commander;
        -- commander SELECT granted but RLS will block individual rows

        -- support_requests
        GRANT SELECT, INSERT, UPDATE ON support_requests TO app_welfare;
        GRANT SELECT, INSERT, UPDATE ON support_requests TO app_personnel;

        -- audit_logs
        GRANT SELECT, INSERT ON audit_logs TO app_welfare;
        GRANT INSERT ON audit_logs TO app_commander;
        GRANT INSERT ON audit_logs TO app_personnel;

        -- disclosure_requests
        GRANT SELECT, INSERT, UPDATE ON disclosure_requests TO app_welfare;

        -- notifications — all roles can read own (RLS enforced)
        GRANT SELECT, INSERT, UPDATE ON notifications TO app_welfare, app_commander, app_personnel;

        -- activation_codes
        GRANT SELECT, UPDATE ON activation_codes TO app_welfare, app_personnel;

        -- ================================================================
        -- 6. Enable RLS + policies
        -- ================================================================

        -- ── wellness_checkins ──────────────────────────────────────────────
        ALTER TABLE wellness_checkins ENABLE ROW LEVEL SECURITY;
        ALTER TABLE wellness_checkins FORCE ROW LEVEL SECURITY;

        CREATE POLICY checkins_personnel ON wellness_checkins
            FOR ALL TO app_personnel
            USING (user_id::text = current_setting('app.current_user_id', true));

        CREATE POLICY checkins_welfare ON wellness_checkins
            FOR ALL TO app_welfare
            USING (true);

        -- Commander: no policy = default deny (zero rows)

        -- ── ai_assessments ────────────────────────────────────────────────
        ALTER TABLE ai_assessments ENABLE ROW LEVEL SECURITY;
        ALTER TABLE ai_assessments FORCE ROW LEVEL SECURITY;

        CREATE POLICY assessments_welfare ON ai_assessments
            FOR ALL TO app_welfare
            USING (true);

        -- Commander: no policy = default deny
        -- Aggregate endpoints run as app_welfare via service-level override

        -- ── hr_metrics ────────────────────────────────────────────────────
        ALTER TABLE hr_metrics ENABLE ROW LEVEL SECURITY;
        ALTER TABLE hr_metrics FORCE ROW LEVEL SECURITY;

        CREATE POLICY hr_welfare ON hr_metrics
            FOR ALL TO app_welfare
            USING (true);

        -- Commander: no policy = default deny

        -- ── support_requests ──────────────────────────────────────────────
        ALTER TABLE support_requests ENABLE ROW LEVEL SECURITY;
        ALTER TABLE support_requests FORCE ROW LEVEL SECURITY;

        CREATE POLICY support_personnel ON support_requests
            FOR ALL TO app_personnel
            USING (user_id::text = current_setting('app.current_user_id', true));

        CREATE POLICY support_welfare ON support_requests
            FOR ALL TO app_welfare
            USING (true);

        -- Commander: no policy = default deny

        -- ── audit_logs ────────────────────────────────────────────────────
        ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
        ALTER TABLE audit_logs FORCE ROW LEVEL SECURITY;

        CREATE POLICY audit_welfare ON audit_logs
            FOR ALL TO app_welfare
            USING (true);

        CREATE POLICY audit_commander_insert ON audit_logs
            FOR INSERT TO app_commander
            WITH CHECK (actor_id::text = current_setting('app.current_user_id', true));

        CREATE POLICY audit_personnel_insert ON audit_logs
            FOR INSERT TO app_personnel
            WITH CHECK (actor_id::text = current_setting('app.current_user_id', true));

        -- ── disclosure_requests ───────────────────────────────────────────
        ALTER TABLE disclosure_requests ENABLE ROW LEVEL SECURITY;
        ALTER TABLE disclosure_requests FORCE ROW LEVEL SECURITY;

        CREATE POLICY disclosure_welfare ON disclosure_requests
            FOR ALL TO app_welfare
            USING (true);

        -- ── notifications ─────────────────────────────────────────────────
        ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
        ALTER TABLE notifications FORCE ROW LEVEL SECURITY;

        CREATE POLICY notif_own ON notifications
            FOR ALL TO app_welfare, app_commander, app_personnel
            USING (user_id::text = current_setting('app.current_user_id', true));
    """)


def downgrade() -> None:
    op.execute("""
        -- Drop RLS policies
        DROP POLICY IF EXISTS notif_own ON notifications;
        DROP POLICY IF EXISTS disclosure_welfare ON disclosure_requests;
        DROP POLICY IF EXISTS audit_personnel_insert ON audit_logs;
        DROP POLICY IF EXISTS audit_commander_insert ON audit_logs;
        DROP POLICY IF EXISTS audit_welfare ON audit_logs;
        DROP POLICY IF EXISTS support_welfare ON support_requests;
        DROP POLICY IF EXISTS support_personnel ON support_requests;
        DROP POLICY IF EXISTS hr_welfare ON hr_metrics;
        DROP POLICY IF EXISTS assessments_welfare ON ai_assessments;
        DROP POLICY IF EXISTS checkins_welfare ON wellness_checkins;
        DROP POLICY IF EXISTS checkins_personnel ON wellness_checkins;

        -- Disable RLS
        ALTER TABLE wellness_checkins DISABLE ROW LEVEL SECURITY;
        ALTER TABLE ai_assessments DISABLE ROW LEVEL SECURITY;
        ALTER TABLE hr_metrics DISABLE ROW LEVEL SECURITY;
        ALTER TABLE support_requests DISABLE ROW LEVEL SECURITY;
        ALTER TABLE audit_logs DISABLE ROW LEVEL SECURITY;
        ALTER TABLE disclosure_requests DISABLE ROW LEVEL SECURITY;
        ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;

        -- Revoke grants
        REVOKE ALL ON wellness_checkins, ai_assessments, hr_metrics, support_requests,
            audit_logs, disclosure_requests, notifications, units, users, activation_codes
            FROM app_welfare, app_commander, app_personnel;

        -- Drop extended audit_logs columns
        ALTER TABLE audit_logs DROP COLUMN IF EXISTS disclosure_request_id;
        ALTER TABLE audit_logs DROP COLUMN IF EXISTS approver_id;
        ALTER TABLE audit_logs DROP COLUMN IF EXISTS initiator_id;
        ALTER TABLE audit_logs DROP COLUMN IF EXISTS justification_category;

        -- Drop new tables
        DROP TABLE IF EXISTS notifications;
        DROP TABLE IF EXISTS disclosure_requests;

        -- Drop new enums
        DROP TYPE IF EXISTS disclosurestatus;
        DROP TYPE IF EXISTS justificationcategory;

        -- Drop roles
        DROP ROLE IF EXISTS app_personnel;
        DROP ROLE IF EXISTS app_commander;
        DROP ROLE IF EXISTS app_welfare;
    """)
