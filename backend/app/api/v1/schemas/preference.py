from pydantic_extra_types.color import Color

from app.schemas.base import BaseSchema


class PreferenceUpdateRequest(BaseSchema):
    stage_name: str
    color: Color

class PreferenceResponse(BaseSchema):
    stage_name: str
    color: Color