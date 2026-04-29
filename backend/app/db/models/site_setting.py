import uuid

from sqlmodel import Field, SQLModel


class SiteSetting(SQLModel, table=True):
    """Site settings."""

    __tablename__ = "settings"

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    name: str = Field(unique=True)
    value: str | None

    def __admin_repr__(self, request) -> str:
        """
        Used for displaying the key instead of UUID in the admin interface.
        """

        return self.key
