import uuid
from typing import Optional

from sqlmodel import SQLModel, Field, Relationship


class Motif(SQLModel, table=True):
    """Motif model."""

    __tablename__ = "motifs"

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    name: str
    public: bool = Field(default=False, nullable=False)

    definitions: list["MotifDefinition"] = Relationship(
        back_populates="motif",
        sa_relationship_kwargs={"lazy": "selectin"},
        cascade_delete=True,
    )

    user_id: uuid.UUID | None = Field(foreign_key="users.id", default=None)
    user: Optional["User"] = Relationship(back_populates="motifs")

    def __admin_repr__(self, request) -> str:
        """
        Used for displaying the label instead of the UUID in the admin interface.
        """
        return f"{self.name}{' (public)' if self.public else ''}"


class MotifDefinition(SQLModel, table=True):
    """Motif definition model."""

    __tablename__ = "motif_definitions"

    definition: str = Field(primary_key=True)
    motif_id: uuid.UUID = Field(foreign_key="motifs.id", primary_key=True)

    motif: Motif = Relationship(back_populates="definitions")

    def __admin_repr__(self, request) -> str:
        """
        Used for displaying the definition instead of the UUID in the admin interface.
        """
        return self.definition