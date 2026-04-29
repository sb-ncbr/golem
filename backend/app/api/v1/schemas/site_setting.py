from app.schemas.base import BaseSchema


class SettingUpdateRequest(BaseSchema):
    """Setting update request schema."""

    key: str
    value: str
