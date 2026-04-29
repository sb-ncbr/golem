from fastapi import Depends
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession
from app.db import db
from app.db.models.site_setting import SiteSetting


class SiteSettingRepository:
    """
    Repository for managing site settings.
    """

    def __init__(self, session: AsyncSession = Depends(db.get_session)) -> None:
        self.session = session

    async def get_all(self) -> dict:
        statement = select(SiteSetting)
        result = await self.session.execute(statement)

        return {setting.name: setting.value for setting in result.scalars().all()}

    async def get(self, key: str) -> SiteSetting:
        statement = select(SiteSetting).where(SiteSetting.name == key)
        result = await self.session.execute(statement)

        return result.scalars().first()

    async def set(self, key: str, value: str) -> None:
        site_setting = SiteSetting(name=key, value=value)

        existing_site_setting = await self.get(key)
        if existing_site_setting is not None:
            site_setting = existing_site_setting
            site_setting.value = value

        self.session.add(site_setting)
        await self.session.commit()

    async def delete(self, key: str) -> None:
        setting = await self.get(key)
        if not setting:
            raise ValueError("Setting not found")

        await self.session.delete(setting)
        await self.session.commit()
