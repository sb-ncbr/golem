import uuid

from pydantic_extra_types.color import Color

from app.schemas.base import BaseSchema


class PreferenceUpdateRequest(BaseSchema):
    organism_id: uuid.UUID
    stage_name: str
    color: Color

class PreferenceResponse(BaseSchema):
    organism_id: uuid.UUID
    stage_name: str
    color: Color

class DefaultPreferenceResponse(BaseSchema):
    stage_name: str
    color: Color
