import uuid

from app.schemas.base import BaseSchema

class MotifCreateRequest(BaseSchema):
    """Motif create request schema."""

    name: str
    definitions: list[str]

class MotifResponse(BaseSchema):
    """Motif response schema."""

    id: uuid.UUID
    name: str
    definitions: list[str]
    public: bool
