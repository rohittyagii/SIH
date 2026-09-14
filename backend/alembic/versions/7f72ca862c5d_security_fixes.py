"""security_fixes

Revision ID: 7f72ca862c5d
Revises: 002_role_separation
Create Date: 2026-09-14 08:14:26.820515+00:00

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '7f72ca862c5d'
down_revision: Union[str, None] = '002_role_separation'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
