from fastapi import Request
from sqlmodel.ext.asyncio.session import AsyncSession

from app.admin.admin_base import AdminViewBase
from app.db.models.stage_preference import StagePreference
from app.db.models.user import User


class StagePreferenceAdminView(AdminViewBase):
    async def create(self, request: Request, data: dict) -> StagePreference:
        session: AsyncSession = request.state.session
        user = await session.get(User, data["user"])
        stage_preference = StagePreference(
            stage_name=data["stage_name"], color=data["color"], user=user
        )

        session.add(stage_preference)
        await session.commit()
        await session.refresh(stage_preference)
        return stage_preference