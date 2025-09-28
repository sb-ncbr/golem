import uuid

from sqlmodel import SQLModel, Field, Relationship

from app.db.models.group import Group, UserGroup
from app.db.models.motif import Motif
from app.db.models.stage_preference import UserStagePreference


class User(SQLModel, table=True):
    """A user of the GOLEM application."""

    __tablename__ = "users"

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    username: str = Field(unique=True)
    hashed_password: str

    groups: list[Group] = Relationship(
        back_populates="users",
        link_model=UserGroup,
        sa_relationship_kwargs={"lazy": "selectin"},
    )
    stage_preferences: list[UserStagePreference] = Relationship(
        back_populates="user",
        sa_relationship_kwargs={"lazy": "selectin"},
    )
    motifs: list[Motif] = Relationship(
        back_populates="user",
        sa_relationship_kwargs={"lazy": "selectin"},
    )

    def __admin_repr__(self, request) -> str:
        """
        Used for displaying the username instead of the UUID in the admin interface.
        """

        return f"{self.username}"
