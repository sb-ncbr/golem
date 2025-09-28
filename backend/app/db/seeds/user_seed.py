from sqlmodel.ext.asyncio.session import AsyncSession

from app.config import app_config
from app.db.models.user import User
from app.db.models.group import Group

import app.services.auth as auth
from app.services.auth import ADMINISTRATORS_GROUP

USER_PRESETS = [
    User(
        username=app_config.default_admin_username,
        hashed_password=auth.get_password_hash(app_config.default_admin_password),
        groups=[Group(name=ADMINISTRATORS_GROUP)],
    )
]


async def seed(session: AsyncSession) -> None:
    session.add_all(USER_PRESETS)
    await session.commit()
