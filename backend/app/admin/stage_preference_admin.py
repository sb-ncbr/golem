import uuid

from fastapi import Request
from pydantic_extra_types.color import Color
from sqlalchemy.exc import IntegrityError
from sqlmodel.ext.asyncio.session import AsyncSession
from starlette_admin.exceptions import FormValidationError

from app.admin.admin_base import AdminViewBase
from app.admin.fields.hex_color_field import HexColorField
from app.db.models.stage_preference import DefaultStagePreference, UserStagePreference
from app.db.models.user import User


class UserStagePreferenceAdminView(AdminViewBase):
    model = UserStagePreference
    fields = [
        "stage_name",
        HexColorField("color", label="Color", required=True),
        "user",
    ]

    async def create(self, request: Request, data: dict) -> UserStagePreference:
        session: AsyncSession = request.state.session

        user = await session.get(User, data["user"])
        stage_name = data["stage_name"]
        hex_color = Color(data["color"]).as_hex()
        stage_preference = UserStagePreference(
            stage_name=stage_name, color=hex_color, user=user
        )

        try:
            session.add(stage_preference)
            await session.commit()
            await session.refresh(stage_preference)
        except IntegrityError as e:
            raise FormValidationError(
                {"stage_name": f"Preference for stage '{stage_name}' already exists."}
            ) from e

        return stage_preference

    async def edit(self, request: Request, pk: str, data: dict) -> UserStagePreference:
        session: AsyncSession = request.state.session

        stage_name = data["stage_name"]
        hex_color = Color(data["color"]).as_hex()
        user_id = data["user"]

        # for some reason pk is a string of the form "stage_name,user_id" ...
        pk_name, pk_user_id = pk.split(",")
        stage_preference = await session.get(UserStagePreference, (pk_name, pk_user_id))

        stage_preference.stage_name = stage_name
        stage_preference.color = hex_color
        stage_preference.user_id = user_id

        try:
            await session.commit()
            await session.refresh(stage_preference)
        except IntegrityError as e:
            raise FormValidationError(
                {"stage_name": f"Preference for stage '{stage_name}' already exists."}
            ) from e

        return stage_preference


class DefaultStagePreferenceAdminView(AdminViewBase):
    model = DefaultStagePreference
    fields = [
        "stage_name",
        HexColorField("color", label="Color", required=True),
    ]

    form_include_pk = True

    async def create(self, request: Request, data: dict) -> DefaultStagePreference:
        session: AsyncSession = request.state.session

        hex_color = Color(data["color"]).as_hex()
        default_stage_preference = DefaultStagePreference(
            stage_name=data["stage_name"], color=hex_color
        )

        session.add(default_stage_preference)
        await session.commit()
        await session.refresh(default_stage_preference)

        return default_stage_preference

    async def edit(
        self, request: Request, pk: uuid.UUID, data: dict
    ) -> DefaultStagePreference:
        session: AsyncSession = request.state.session
        errors: dict[str, str] = {}

        stage_name = data["stage_name"]
        hex_color = Color(data["color"]).as_hex()

        default_stage_preference = await session.get(DefaultStagePreference, pk)

        if stage_name != default_stage_preference.stage_name:
            await self._validate_name(stage_name, session, errors)

        if errors:
            raise FormValidationError(errors)

        default_stage_preference.stage_name = stage_name
        default_stage_preference.color = hex_color

        await session.commit()
        await session.refresh(default_stage_preference)

        return default_stage_preference

    @staticmethod
    async def _validate_name(name: str, session: AsyncSession, errors: dict[str, str]):
        stage_preference = await session.get(UserStagePreference, name)

        if stage_preference:
            errors["stage_name"] = f"Preference for stage '{name}' already exists."
