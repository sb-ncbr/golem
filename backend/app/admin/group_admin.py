import uuid

from fastapi import Request
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession
from starlette_admin.exceptions import FormValidationError

from app.admin.admin_base import AdminViewBase
from app.db.models.group import Group


class GroupAdminView(AdminViewBase):
    NAME_MIN_LENGTH = 3
    NAME_MAX_LENGTH = 32

    model = Group
    exclude_fields_from_list = ["id"]

    async def create(self, request: Request, data: dict):
        session: AsyncSession = request.state.session
        errors: dict[str, str] = {}

        name = data["name"]
        user_ids = data["users"]
        organism_ids = data["organisms"]

        await self._validate_name(name, session, errors)

        if errors:
            raise FormValidationError(errors)

        users = await self._get_users(session, user_ids)
        organisms = await self._get_organisms(session, organism_ids)
        group = Group(name=name, users=users, organisms=organisms)

        session.add(group)
        await session.commit()
        await session.refresh(group)

        return group

    async def edit(self, request: Request, pk: uuid.UUID, data: dict):
        session: AsyncSession = request.state.session
        errors: dict[str, str] = {}

        group = await session.get(Group, pk)

        name = data["name"]
        user_ids = data["users"]
        organism_ids = data["organisms"]

        if group.name != name:
            await self._validate_name(name, session, errors)

        if errors:
            raise FormValidationError(errors)

        group.name = name
        group.users = await self._get_users(session, user_ids)
        group.organisms = await self._get_organisms(session, organism_ids)

        await session.commit()
        await session.refresh(group)

        return group

    async def _validate_name(
        self, name: str, session: AsyncSession, errors: dict[str, str]
    ):
        if not (
            name is not None
            and self.NAME_MIN_LENGTH <= len(name) <= self.NAME_MAX_LENGTH
        ):
            errors["name"] = (
                f"Group name must be between {self.NAME_MIN_LENGTH} and {self.NAME_MAX_LENGTH} characters long."
            )
            return False

        group_exists = (
            await session.scalars(select(Group).where(Group.name == name))
        ).first()
        if group_exists is not None:
            errors["name"] = f"Group '{name}' already exists."
            return False

        return True
