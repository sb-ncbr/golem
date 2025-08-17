import uuid

from pydantic_extra_types.color import Color
from sqlmodel import SQLModel, Field, Relationship, Column

from app.db.types.color import ColorType

DEFAULT_COLOR_RGBA = (158, 158, 158, 1.0)


class UserStagePreference(SQLModel, table=True):
    """
    A stage preferences for a user.
    """
    __tablename__ = "user_stages_preferences"

    stage_name: str = Field(primary_key=True)
    user_id: uuid.UUID = Field(foreign_key="users.id", primary_key=True)
    color: Color = Field(sa_column=Column(ColorType))

    user: "User" = Relationship(back_populates="stage_preferences")

class DefaultStagePreference(SQLModel, table=True):
    """
    A default stage preferences.
    """
    __tablename__ = "default_stages_preferences"

    stage_name: str = Field(primary_key=True)
    color: Color = Field(sa_column=Column(ColorType))
