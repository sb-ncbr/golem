from starlette_admin.fields import ColorField
from pydantic_extra_types.color import Color

class HexColorField(ColorField):
    """
    Form field for forcing the color value to be stored as a hex string.
    The default ColorField in some cases stored the color as a word (e.g. 'red').
    """

    async def parse_obj(self, request, obj):
        value = await super().parse_obj(request, obj)
        if value and isinstance(value, str):
            try:
                return Color(value).as_hex('long')
            except:
                return value
        return value

    async def serialize_value(self, request, value, action):
        if value:
            if hasattr(value, 'as_hex'):
                return value.as_hex('long')
            elif isinstance(value, str):
                try:
                    return Color(value).as_hex('long')
                except:
                    return value
        return value