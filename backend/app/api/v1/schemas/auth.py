import uuid

from app.api.v1.schemas.preference import PreferenceResponse
from app.schemas.base import BaseSchema


class GroupResponse(BaseSchema):
    """Response schema for a user group."""

    id: uuid.UUID
    name: str


class UserResponse(BaseSchema):
    """Response schema for a user."""

    id: uuid.UUID
    username: str
    groups: list[GroupResponse]
    stage_preferences: list[PreferenceResponse]


class LoginResponse(BaseSchema):
    """Response schema for login endpoint."""

    access_token: str
    token_type: str
    user: UserResponse


class LoginRequest(BaseSchema):
    """Request schema for login endpoint."""

    username: str
    password: str