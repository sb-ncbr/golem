import uuid

from pydantic import BaseModel, ConfigDict, field_validator
from pydantic.alias_generators import to_camel


class BaseSchema(BaseModel):
    """
    Base schema for all models. Converts snake_case to camelCase.
    """

    model_config = ConfigDict(
        alias_generator=to_camel,
        from_attributes=True,
        populate_by_name=True,
        json_encoders={uuid.UUID: str},
    )

    @field_validator("color", mode="after", check_fields=False)
    @classmethod
    def color_as_hex(cls, v):
        if v is None:
            return None
        return v.as_hex()
