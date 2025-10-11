"""add organism_id to preference pk

Revision ID: b2473e21f67b
Revises: 71834dfc5a17
Create Date: 2025-10-07 21:44:06.765236

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
import sqlmodel


# revision identifiers, used by Alembic.
revision: str = "b2473e21f67b"
down_revision: Union[str, Sequence[str], None] = "71834dfc5a17"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.drop_constraint("user_stages_preferences_pkey", "user_stages_preferences", type_="primary")
    op.create_primary_key(
        "user_stages_preferences_pkey", "user_stages_preferences", ["user_id", "stage_name", "organism_id"]
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_constraint("user_stages_preferences_pkey", "user_stages_preferences", type_="primary")
    op.create_primary_key(
        "user_stages_preferences_pkey", "user_stages_preferences", ["user_id", "stage_name"]
    )
