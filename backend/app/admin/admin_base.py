import uuid

from fastapi import Request, Response
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession
from starlette.responses import RedirectResponse
from starlette.status import HTTP_404_NOT_FOUND
from starlette.templating import Jinja2Templates
from starlette_admin import CustomView
from starlette_admin.contrib.sqlmodel import ModelView

from app.db.models.group import Group
from app.db.models.organism import Organism
from app.db.models.user import User
import app.services.auth as auth


class AdminIndexView(CustomView):
    async def render(self, request: Request, templates: Jinja2Templates) -> Response:
        user: User = request.state.user
        if not auth.is_admin(user):
            return RedirectResponse(url="/", status_code=HTTP_404_NOT_FOUND)

        return RedirectResponse(url="organism/list")


class AdminViewBase(ModelView):
    def is_accessible(self, request: Request) -> bool:
        user: User = request.state.user
        return auth.is_admin(user)

    @staticmethod
    async def _get_groups(
        session: AsyncSession, group_ids: list[uuid.UUID | str]
    ) -> list[Group]:
        return list(await session.scalars(select(Group).where(Group.id.in_(group_ids))))

    @staticmethod
    async def _get_users(
        session: AsyncSession, user_ids: list[uuid.UUID | str]
    ) -> list[User]:
        return list((await session.scalars(select(User).where(User.id.in_(user_ids)))))

    @staticmethod
    async def _get_organisms(
        session: AsyncSession, organism_ids: list[uuid.UUID | str]
    ) -> list[Organism]:
        return list(
            (
                await session.scalars(
                    select(Organism).where(Organism.id.in_(organism_ids))
                )
            )
        )