"""add commander_recommendations table

Revision ID: 0dca78a2fdb4
Revises: 7f72ca862c5d
Create Date: 2026-09-21 05:34:38.636010+00:00

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '0dca78a2fdb4'
down_revision: Union[str, None] = '7f72ca862c5d'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # risklevel already exists from 001_initial — skip it.
    # Create recommendationstatus safely.
    op.execute("""
        DO $$ BEGIN
            CREATE TYPE recommendationstatus AS ENUM ('Pending', 'Reviewed', 'Actioned');
        EXCEPTION WHEN duplicate_object THEN NULL; END $$
    """)

    # Use raw SQL (same pattern as 001_initial / 002_role_separation) to avoid
    # SQLAlchemy's sa.Enum before_create hook attempting CREATE TYPE risklevel.
    op.execute("""
        CREATE TABLE IF NOT EXISTS commander_recommendations (
            id                  UUID        PRIMARY KEY,
            welfare_officer_id  UUID        NOT NULL REFERENCES users(id),
            commander_id        UUID        NOT NULL REFERENCES users(id),
            soldier_id          UUID        NOT NULL REFERENCES users(id),
            assessment_id       UUID        REFERENCES ai_assessments(id),
            unit_id             UUID        NOT NULL REFERENCES units(id),
            note                TEXT        NOT NULL,
            risk_level          risklevel   NOT NULL,
            status              recommendationstatus NOT NULL,
            commander_response  TEXT,
            created_at          TIMESTAMPTZ NOT NULL,
            reviewed_at         TIMESTAMPTZ
        )
    """)


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS commander_recommendations")
    op.execute("DROP TYPE IF EXISTS recommendationstatus")

