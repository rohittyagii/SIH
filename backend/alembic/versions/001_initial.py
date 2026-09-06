"""Initial schema — all tables

Revision ID: 001_initial
Revises:
Create Date: 2026-09-06
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "001_initial"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ── Enums ────────────────────────────────────────────────────────────────
    userrole = postgresql.ENUM(
        "Personnel", "Welfare_Officer", "Commander", "Admin",
        name="userrole", create_type=True
    )
    risklevel = postgresql.ENUM(
        "Routine", "Monitor", "Intervention_Recommended",
        name="risklevel", create_type=True
    )
    assessmentstatus = postgresql.ENUM(
        "Pending", "Acknowledged", "Action_Taken",
        name="assessmentstatus", create_type=True
    )
    userrole.create(op.get_bind(), checkfirst=True)
    risklevel.create(op.get_bind(), checkfirst=True)
    assessmentstatus.create(op.get_bind(), checkfirst=True)

    # ── units ─────────────────────────────────────────────────────────────────
    op.create_table(
        "units",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("name", sa.String(120), nullable=False, unique=True),
        sa.Column("parent_unit_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("units.id"), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )

    # ── users ─────────────────────────────────────────────────────────────────
    op.create_table(
        "users",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("service_id", sa.String(50), nullable=False, unique=True),
        sa.Column("username", sa.String(80), nullable=False, unique=True),
        sa.Column("full_name", sa.String(150), nullable=False),
        sa.Column("unit_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("units.id"), nullable=False),
        sa.Column("pin_hash", sa.String(255), nullable=False),
        sa.Column("role", sa.Enum("Personnel", "Welfare_Officer", "Commander", "Admin", name="userrole"), nullable=False),
        sa.Column("is_active", sa.Boolean(), default=True, nullable=False),
        sa.Column("consent_given", sa.Boolean(), default=False, nullable=False),
        sa.Column("consent_given_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("language_pref", sa.String(10), default="en-GB", nullable=False),
        sa.Column("theme_dark", sa.Boolean(), default=True, nullable=False),
        sa.Column("notif_daily_reminder", sa.Boolean(), default=True, nullable=False),
        sa.Column("notif_sync_alerts", sa.Boolean(), default=True, nullable=False),
        sa.Column("notif_weekly_summary", sa.Boolean(), default=False, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_users_username", "users", ["username"])
    op.create_index("ix_users_service_id", "users", ["service_id"])

    # ── activation_codes ──────────────────────────────────────────────────────
    op.create_table(
        "activation_codes",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("code", sa.String(9), nullable=False, unique=True),
        sa.Column("unit_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("units.id"), nullable=False),
        sa.Column("is_used", sa.Boolean(), default=False, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("used_at", sa.DateTime(timezone=True), nullable=True),
    )

    # ── wellness_checkins ─────────────────────────────────────────────────────
    op.create_table(
        "wellness_checkins",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("checkin_date", sa.Date(), nullable=False),
        sa.Column("overall_score", sa.Integer(), nullable=False),
        sa.Column("sleep_score", sa.Integer(), nullable=False),
        sa.Column("physical_score", sa.Integer(), nullable=False),
        sa.Column("focus_score", sa.Integer(), nullable=False),
        sa.Column("average_score", sa.Float(), nullable=False),
        sa.Column("note_encrypted", sa.LargeBinary(), nullable=True),
        sa.Column("risk_level", sa.Enum("Routine", "Monitor", "Intervention_Recommended", name="risklevel"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("user_id", "checkin_date", name="uq_checkin_user_date"),
    )
    op.create_index("ix_checkins_user_date", "wellness_checkins", ["user_id", "checkin_date"])
    op.create_index("ix_checkins_risk", "wellness_checkins", ["risk_level"])

    # ── hr_metrics ────────────────────────────────────────────────────────────
    op.create_table(
        "hr_metrics",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False, unique=True),
        sa.Column("avg_weekly_duty_hours", sa.Float(), default=48.0, nullable=False),
        sa.Column("days_since_last_leave", sa.Integer(), default=0, nullable=False),
        sa.Column("deployment_history_months", sa.Integer(), default=0, nullable=False),
        sa.Column("hrv_baseline_deviation", sa.Float(), default=0.0, nullable=False),
        sa.Column("avg_mood_score", sa.Float(), default=5.0, nullable=False),
        sa.Column("avg_sleep_recovery", sa.Float(), default=5.0, nullable=False),
        sa.Column("avg_fatigue_level", sa.Float(), default=5.0, nullable=False),
        sa.Column("last_updated", sa.DateTime(timezone=True), nullable=False),
    )

    # ── ai_assessments ────────────────────────────────────────────────────────
    op.create_table(
        "ai_assessments",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("unit_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("units.id"), nullable=False),
        sa.Column("risk_level", sa.Enum("Routine", "Monitor", "Intervention_Recommended", name="risklevel", create_constraint=False), nullable=False),
        sa.Column("resilience_score", sa.Integer(), nullable=False),
        sa.Column("mood_score", sa.Float(), nullable=False),
        sa.Column("sleep_recovery", sa.Float(), nullable=False),
        sa.Column("fatigue_level", sa.Float(), nullable=False),
        sa.Column("hrv_baseline_deviation", sa.Float(), nullable=False),
        sa.Column("contributing_factors", sa.Text(), nullable=False),
        sa.Column("recommended_intervention", sa.Text(), nullable=False),
        sa.Column("ai_narrative", sa.Text(), nullable=False),
        sa.Column("status", sa.Enum("Pending", "Acknowledged", "Action_Taken", name="assessmentstatus"), nullable=False),
        sa.Column("acknowledged_by", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=True),
        sa.Column("resolved_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_assessments_user", "ai_assessments", ["user_id"])
    op.create_index("ix_assessments_status", "ai_assessments", ["status"])
    op.create_index("ix_assessments_risk", "ai_assessments", ["risk_level"])

    # ── support_requests ──────────────────────────────────────────────────────
    op.create_table(
        "support_requests",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("request_type", sa.String(30), default="Callback", nullable=False),
        sa.Column("status", sa.String(20), default="Pending", nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )

    # ── audit_logs ────────────────────────────────────────────────────────────
    op.create_table(
        "audit_logs",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("actor_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("action", sa.String(100), nullable=False),
        sa.Column("resource_type", sa.String(50), nullable=False),
        sa.Column("resource_id", sa.String(36), nullable=True),
        sa.Column("ip_address", sa.String(45), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_audit_actor", "audit_logs", ["actor_id"])
    op.create_index("ix_audit_created", "audit_logs", ["created_at"])


def downgrade() -> None:
    op.drop_table("audit_logs")
    op.drop_table("support_requests")
    op.drop_table("ai_assessments")
    op.drop_table("hr_metrics")
    op.drop_table("wellness_checkins")
    op.drop_table("activation_codes")
    op.drop_table("users")
    op.drop_table("units")
    op.execute("DROP TYPE IF EXISTS assessmentstatus")
    op.execute("DROP TYPE IF EXISTS risklevel")
    op.execute("DROP TYPE IF EXISTS userrole")
