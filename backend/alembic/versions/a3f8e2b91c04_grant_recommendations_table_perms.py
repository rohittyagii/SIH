"""Grant permissions and RLS policies for commander_recommendations table

Revision ID: a3f8e2b91c04
Revises: 0dca78a2fdb4
Create Date: 2026-09-26 00:00:00.000000+00:00

The commander_recommendations table was created in 0dca78a2fdb4 but was
never granted access to the app_welfare / app_commander roles, and RLS
was never enabled on it.  Any attempt to SELECT or INSERT via an RLS
session therefore failed with a PostgreSQL "permission denied" error,
which the backend surfaced as a 401 (or 500, depending on where the
error was caught).

This migration adds:
  - GRANT SELECT, INSERT on commander_recommendations TO app_welfare
  - GRANT SELECT on commander_recommendations TO app_commander
  - Row-level security so welfare officers only see their own recommendations
  - Row-level security so commanders only see recommendations directed at them
"""
from typing import Sequence, Union

from alembic import op


revision: str = 'a3f8e2b91c04'
down_revision: Union[str, None] = '0dca78a2fdb4'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ── 1. Table-level GRANTs ─────────────────────────────────────────────────
    # Welfare officers can create and read their own recommendations
    op.execute(
        "GRANT SELECT, INSERT, UPDATE ON commander_recommendations TO app_welfare"
    )
    # Commanders can read and update (change status/response) recommendations directed at them
    op.execute(
        "GRANT SELECT, UPDATE ON commander_recommendations TO app_commander"
    )

    # ── 2. Enable RLS on the table ────────────────────────────────────────────
    op.execute("ALTER TABLE commander_recommendations ENABLE ROW LEVEL SECURITY")
    op.execute("ALTER TABLE commander_recommendations FORCE ROW LEVEL SECURITY")

    # ── 3. RLS policies ───────────────────────────────────────────────────────

    # Welfare officers: see/create/update rows where they are the welfare_officer
    op.execute("""
        CREATE POLICY rec_welfare_policy ON commander_recommendations
            FOR ALL TO app_welfare
            USING (
                welfare_officer_id::text = current_setting('app.current_user_id', true)
            )
            WITH CHECK (
                welfare_officer_id::text = current_setting('app.current_user_id', true)
            )
    """)

    # Commanders: see/update rows where they are the commander
    op.execute("""
        CREATE POLICY rec_commander_policy ON commander_recommendations
            FOR ALL TO app_commander
            USING (
                commander_id::text = current_setting('app.current_user_id', true)
            )
            WITH CHECK (
                commander_id::text = current_setting('app.current_user_id', true)
            )
    """)


def downgrade() -> None:
    op.execute("DROP POLICY IF EXISTS rec_welfare_policy ON commander_recommendations")
    op.execute("DROP POLICY IF EXISTS rec_commander_policy ON commander_recommendations")
    op.execute("ALTER TABLE commander_recommendations DISABLE ROW LEVEL SECURITY")
    op.execute("REVOKE ALL ON commander_recommendations FROM app_welfare, app_commander")
