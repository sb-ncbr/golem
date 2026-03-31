from app.schemas.base import BaseSchema


class UsageStats(BaseSchema):
    unique_users: int
    total_analyses: int
    logged_in_analyses: int
    anonymous_analyses: int
