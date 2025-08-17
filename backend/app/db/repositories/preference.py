from fastapi import Depends
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.db import db
from app.db.models.stage_preference import DefaultStagePreference
from app.db.models.user import User


class PreferenceRepository:
    """
    A repository for user management.
    """

    def __init__(self, session: AsyncSession = Depends(db.get_session)) -> None:
        self.session = session

    async def get_default(self) -> list[DefaultStagePreference]:
        """
        Get all default stage preferences.

        Returns:
            list[DefaultStagePreference]: List of default stage preferences.

        """

        statement = select(DefaultStagePreference)
        preferences = await self.session.execute(statement)

        return list(preferences.scalars().all())
