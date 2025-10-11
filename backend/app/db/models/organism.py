import uuid

from sqlmodel import SQLModel, Field, Relationship

from app.db.models.group import Group, OrganismGroup
from app.db.models.stage_preference import UserStagePreference


class Organism(SQLModel, table=True):
    """An organism on which analysis can be performed."""

    __tablename__ = "organisms"

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    name: str
    description: str | None
    sequences_filename: str
    metadata_filename: str
    take_first_transcript_only: bool
    public: bool

    groups: list[Group] = Relationship(
        back_populates="organisms",
        link_model=OrganismGroup,
        sa_relationship_kwargs={"lazy": "selectin"},
    )
    stage_preferences: list[UserStagePreference] = Relationship(
        back_populates="organism",
        sa_relationship_kwargs={"lazy": "selectin"},
    )


    def __admin_repr__(self, request) -> str:
        """
        Used for displaying the Organism name instead of the UUID in the admin interface.
        """
        if not self.description:
            return self.name

        description = (
            self.description
            if len(self.description) < 10
            else f"{self.description[:10]}..."
        )

        return f"{self.name} ({description})"
