from pydantic_extra_types.color import Color
from sqlalchemy.types import TypeDecorator, String


class ColorType(TypeDecorator):
    """
    Custom SQLAlchemy type to store Pydantic Color objects as strings in the database.
    """

    impl = String
    cache_ok = True

    def process_bind_param(self, value: Color | str | None, dialect) -> str | None:
        """
        Convert the Color object to its string representation (hex) before saving.
        """

        if value is None:
            return None

        if isinstance(value, str):
            return Color(value).as_hex()

        return value.as_hex()

    def process_result_value(self, value: str | None, dialect) -> Color | None:
        """
        Convert the string from the database back into a Color object.
        """

        if value is None:
            return None

        return Color(value)