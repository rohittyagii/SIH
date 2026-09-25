"""Fix notifications RLS policy to allow users to send notifications to others

Revision ID: b4f9e3c12d15
Revises: a3f8e2b91c04
Create Date: 2026-09-26 01:00:00.000000+00:00

The previous policy on `notifications` was `FOR ALL`, restricted to
`user_id = current_user_id`. This meant a user could only insert
notifications for themselves, which broke the workflow where a
Welfare Officer sends a recommendation (and thus a notification)
to a Commanding Officer.

This migration splits the policy:
1. SELECT, UPDATE, DELETE: restricted to own notifications (user_id = current_user)
2. INSERT: allowed for all (so users can notify each other)
"""
from typing import Sequence, Union

from alembic import op


revision: str = 'b4f9e3c12d15'
down_revision: Union[str, None] = 'a3f8e2b91c04'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Drop the overly restrictive ALL policy
    op.execute("DROP POLICY IF EXISTS notif_own ON notifications")

    # Recreate as SELECT/UPDATE/DELETE only for own notifications
    op.execute("""
        CREATE POLICY notif_own_read_update ON notifications
            FOR SELECT TO app_welfare, app_commander, app_personnel
            USING (user_id::text = current_setting('app.current_user_id', true))
    """)
    op.execute("""
        CREATE POLICY notif_own_update ON notifications
            FOR UPDATE TO app_welfare, app_commander, app_personnel
            USING (user_id::text = current_setting('app.current_user_id', true))
            WITH CHECK (user_id::text = current_setting('app.current_user_id', true))
    """)
    op.execute("""
        CREATE POLICY notif_own_delete ON notifications
            FOR DELETE TO app_welfare, app_commander, app_personnel
            USING (user_id::text = current_setting('app.current_user_id', true))
    """)

    # Allow INSERT for any user to any user
    # (The application logic determines who can notify whom, not RLS)
    op.execute("""
        CREATE POLICY notif_insert_any ON notifications
            FOR INSERT TO app_welfare, app_commander, app_personnel
            WITH CHECK (true)
    """)


def downgrade() -> None:
    op.execute("DROP POLICY IF EXISTS notif_own_read_update ON notifications")
    op.execute("DROP POLICY IF EXISTS notif_own_update ON notifications")
    op.execute("DROP POLICY IF EXISTS notif_own_delete ON notifications")
    op.execute("DROP POLICY IF EXISTS notif_insert_any ON notifications")

    op.execute("""
        CREATE POLICY notif_own ON notifications
            FOR ALL TO app_welfare, app_commander, app_personnel
            USING (user_id::text = current_setting('app.current_user_id', true))
    """)
