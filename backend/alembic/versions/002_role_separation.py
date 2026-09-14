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
    # ── 1. PostgreSQL application roles ──────────────────────────────────────
    op.execute("DO $$ BEGIN CREATE ROLE app_welfare NOLOGIN; EXCEPTION WHEN duplicate_object THEN NULL; END $$")
    op.execute("DO $$ BEGIN CREATE ROLE app_commander NOLOGIN; EXCEPTION WHEN duplicate_object THEN NULL; END $$")
    op.execute("DO $$ BEGIN CREATE ROLE app_personnel NOLOGIN; EXCEPTION WHEN duplicate_object THEN NULL; END $$")
    op.execute("GRANT app_welfare TO CURRENT_USER")
    op.execute("GRANT app_commander TO CURRENT_USER")
    op.execute("GRANT app_personnel TO CURRENT_USER")

    # ── 2. New ENUMs ──────────────────────────────────────────────────────────
    op.execute("""
        DO $$ BEGIN
            CREATE TYPE justificationcategory AS ENUM (
                'IMMINENT_RISK', 'INDIVIDUAL_CONSENT',
                'OPERATIONAL_NECESSITY', 'LEGAL_MANDATE'
            );
        EXCEPTION WHEN duplicate_object THEN NULL; END $$
    """)
    op.execute("""
        DO $$ BEGIN
            CREATE TYPE disclosurestatus AS ENUM (
                'PENDING_INITIATOR', 'PENDING_APPROVER',
                'APPROVED', 'DENIED', 'EXPIRED'
            );
        EXCEPTION WHEN duplicate_object THEN NULL; END $$
    """)

    # ── 3. New tables ─────────────────────────────────────────────────────────
    op.execute("""
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
        )
    """)
    op.execute("CREATE INDEX IF NOT EXISTS ix_disclosure_status ON disclosure_requests(status)")
    op.execute("CREATE INDEX IF NOT EXISTS ix_disclosure_officer ON disclosure_requests(requesting_officer_id)")
    op.execute("CREATE INDEX IF NOT EXISTS ix_disclosure_subject ON disclosure_requests(subject_user_id)")

    op.execute("""
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
        )
    """)
    op.execute("CREATE INDEX IF NOT EXISTS ix_notif_user ON notifications(user_id)")
    op.execute("CREATE INDEX IF NOT EXISTS ix_notif_unread ON notifications(user_id, is_read) WHERE NOT is_read")

    # ── 4. Extend audit_logs with disclosure-specific columns ─────────────────
    op.execute("ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS justification_category VARCHAR(30)")
    op.execute("ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS initiator_id UUID REFERENCES users(id)")
    op.execute("ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS approver_id UUID REFERENCES users(id)")
    op.execute("ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS disclosure_request_id UUID REFERENCES disclosure_requests(id)")

    # ── 5. Table-level GRANTs ─────────────────────────────────────────────────
    op.execute("GRANT SELECT ON units TO app_welfare, app_commander, app_personnel")
    op.execute("GRANT SELECT ON users TO app_welfare, app_commander, app_personnel")

    op.execute("GRANT SELECT, INSERT, UPDATE ON wellness_checkins TO app_welfare")
    op.execute("GRANT SELECT, INSERT, UPDATE ON wellness_checkins TO app_personnel")

    op.execute("GRANT SELECT, INSERT, UPDATE ON ai_assessments TO app_welfare")
    op.execute("GRANT SELECT ON ai_assessments TO app_commander")

    op.execute("GRANT SELECT, INSERT, UPDATE ON hr_metrics TO app_welfare")
    op.execute("GRANT SELECT ON hr_metrics TO app_commander")

    op.execute("GRANT SELECT, INSERT, UPDATE ON support_requests TO app_welfare")
    op.execute("GRANT SELECT, INSERT, UPDATE ON support_requests TO app_personnel")

    op.execute("GRANT SELECT, INSERT ON audit_logs TO app_welfare")
    op.execute("GRANT INSERT ON audit_logs TO app_commander")
    op.execute("GRANT INSERT ON audit_logs TO app_personnel")

    op.execute("GRANT SELECT, INSERT, UPDATE ON disclosure_requests TO app_welfare")
    op.execute("GRANT SELECT, INSERT, UPDATE ON notifications TO app_welfare, app_commander, app_personnel")
    op.execute("GRANT SELECT, UPDATE ON activation_codes TO app_welfare, app_personnel")

    # ── 6. Enable RLS + policies ──────────────────────────────────────────────

    # wellness_checkins
    op.execute("ALTER TABLE wellness_checkins ENABLE ROW LEVEL SECURITY")
    op.execute("ALTER TABLE wellness_checkins FORCE ROW LEVEL SECURITY")
    op.execute("""
        CREATE POLICY checkins_personnel ON wellness_checkins
            FOR ALL TO app_personnel
            USING (user_id::text = current_setting('app.current_user_id', true))
    """)
    op.execute("""
        CREATE POLICY checkins_welfare ON wellness_checkins
            FOR ALL TO app_welfare
            USING (true)
    """)

    # ai_assessments
    op.execute("ALTER TABLE ai_assessments ENABLE ROW LEVEL SECURITY")
    op.execute("ALTER TABLE ai_assessments FORCE ROW LEVEL SECURITY")
    op.execute("""
        CREATE POLICY assessments_welfare ON ai_assessments
            FOR ALL TO app_welfare
            USING (true)
    """)

    # hr_metrics
    op.execute("ALTER TABLE hr_metrics ENABLE ROW LEVEL SECURITY")
    op.execute("ALTER TABLE hr_metrics FORCE ROW LEVEL SECURITY")
    op.execute("""
        CREATE POLICY hr_welfare ON hr_metrics
            FOR ALL TO app_welfare
            USING (true)
    """)

    # support_requests
    op.execute("ALTER TABLE support_requests ENABLE ROW LEVEL SECURITY")
    op.execute("ALTER TABLE support_requests FORCE ROW LEVEL SECURITY")
    op.execute("""
        CREATE POLICY support_personnel ON support_requests
            FOR ALL TO app_personnel
            USING (user_id::text = current_setting('app.current_user_id', true))
    """)
    op.execute("""
        CREATE POLICY support_welfare ON support_requests
            FOR ALL TO app_welfare
            USING (true)
    """)

    # audit_logs
    op.execute("ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY")
    op.execute("ALTER TABLE audit_logs FORCE ROW LEVEL SECURITY")
    op.execute("""
        CREATE POLICY audit_welfare ON audit_logs
            FOR ALL TO app_welfare
            USING (true)
    """)
    op.execute("""
        CREATE POLICY audit_commander_insert ON audit_logs
            FOR INSERT TO app_commander
            WITH CHECK (actor_id::text = current_setting('app.current_user_id', true))
    """)
    op.execute("""
        CREATE POLICY audit_personnel_insert ON audit_logs
            FOR INSERT TO app_personnel
            WITH CHECK (actor_id::text = current_setting('app.current_user_id', true))
    """)

    # disclosure_requests
    op.execute("ALTER TABLE disclosure_requests ENABLE ROW LEVEL SECURITY")
    op.execute("ALTER TABLE disclosure_requests FORCE ROW LEVEL SECURITY")
    op.execute("""
        CREATE POLICY disclosure_welfare ON disclosure_requests
            FOR ALL TO app_welfare
            USING (true)
    """)

    # notifications
    op.execute("ALTER TABLE notifications ENABLE ROW LEVEL SECURITY")
    op.execute("ALTER TABLE notifications FORCE ROW LEVEL SECURITY")
    op.execute("""
        CREATE POLICY notif_own ON notifications
            FOR ALL TO app_welfare, app_commander, app_personnel
            USING (user_id::text = current_setting('app.current_user_id', true))
    """)


def downgrade() -> None:
    # Drop RLS policies
    op.execute("DROP POLICY IF EXISTS notif_own ON notifications")
    op.execute("DROP POLICY IF EXISTS disclosure_welfare ON disclosure_requests")
    op.execute("DROP POLICY IF EXISTS audit_personnel_insert ON audit_logs")
    op.execute("DROP POLICY IF EXISTS audit_commander_insert ON audit_logs")
    op.execute("DROP POLICY IF EXISTS audit_welfare ON audit_logs")
    op.execute("DROP POLICY IF EXISTS support_welfare ON support_requests")
    op.execute("DROP POLICY IF EXISTS support_personnel ON support_requests")
    op.execute("DROP POLICY IF EXISTS hr_welfare ON hr_metrics")
    op.execute("DROP POLICY IF EXISTS assessments_welfare ON ai_assessments")
    op.execute("DROP POLICY IF EXISTS checkins_welfare ON wellness_checkins")
    op.execute("DROP POLICY IF EXISTS checkins_personnel ON wellness_checkins")

    # Disable RLS
    op.execute("ALTER TABLE wellness_checkins DISABLE ROW LEVEL SECURITY")
    op.execute("ALTER TABLE ai_assessments DISABLE ROW LEVEL SECURITY")
    op.execute("ALTER TABLE hr_metrics DISABLE ROW LEVEL SECURITY")
    op.execute("ALTER TABLE support_requests DISABLE ROW LEVEL SECURITY")
    op.execute("ALTER TABLE audit_logs DISABLE ROW LEVEL SECURITY")
    op.execute("ALTER TABLE disclosure_requests DISABLE ROW LEVEL SECURITY")
    op.execute("ALTER TABLE notifications DISABLE ROW LEVEL SECURITY")

    # Revoke grants
    op.execute("REVOKE ALL ON wellness_checkins FROM app_welfare, app_commander, app_personnel")
    op.execute("REVOKE ALL ON ai_assessments FROM app_welfare, app_commander, app_personnel")
    op.execute("REVOKE ALL ON hr_metrics FROM app_welfare, app_commander, app_personnel")
    op.execute("REVOKE ALL ON support_requests FROM app_welfare, app_commander, app_personnel")
    op.execute("REVOKE ALL ON audit_logs FROM app_welfare, app_commander, app_personnel")
    op.execute("REVOKE ALL ON disclosure_requests FROM app_welfare, app_commander, app_personnel")
    op.execute("REVOKE ALL ON notifications FROM app_welfare, app_commander, app_personnel")
    op.execute("REVOKE ALL ON units FROM app_welfare, app_commander, app_personnel")
    op.execute("REVOKE ALL ON users FROM app_welfare, app_commander, app_personnel")
    op.execute("REVOKE ALL ON activation_codes FROM app_welfare, app_commander, app_personnel")

    # Drop extended audit_logs columns
    op.execute("ALTER TABLE audit_logs DROP COLUMN IF EXISTS disclosure_request_id")
    op.execute("ALTER TABLE audit_logs DROP COLUMN IF EXISTS approver_id")
    op.execute("ALTER TABLE audit_logs DROP COLUMN IF EXISTS initiator_id")
    op.execute("ALTER TABLE audit_logs DROP COLUMN IF EXISTS justification_category")

    # Drop new tables
    op.execute("DROP TABLE IF EXISTS notifications")
    op.execute("DROP TABLE IF EXISTS disclosure_requests")

    # Drop new enums
    op.execute("DROP TYPE IF EXISTS disclosurestatus")
    op.execute("DROP TYPE IF EXISTS justificationcategory")

    # Drop roles
    op.execute("DROP ROLE IF EXISTS app_personnel")
    op.execute("DROP ROLE IF EXISTS app_commander")
    op.execute("DROP ROLE IF EXISTS app_welfare")


