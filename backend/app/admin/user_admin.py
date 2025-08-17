import uuid

from fastapi import Request
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession
from starlette_admin import PasswordField, StringField
from starlette_admin.exceptions import FormValidationError

from app.admin.admin_base import AdminViewBase
from app.db.models.user import User
from app.services.auth import get_password_hash


class UserAdminView(AdminViewBase):
    USERNAME_MIN_LENGTH = 3
    USERNAME_MAX_LENGTH = 32
    PASSWORD_MIN_LENGTH = 8
    PASSWORD_MAX_LENGTH = 128

    model = User
    fields = [
        StringField("username", label="Username", required=True),
        PasswordField("password", label="Password", required=True),
        PasswordField("password_edit", label="Password"),
        "groups",
    ]
    exclude_fields_from_list = [
        "id",
        "stage_preferences",
        "hashed_password",
        "password",
        "password_edit",
    ]
    exclude_fields_from_edit = [
        "id",
        "stage_preferences",
        "hashed_password",
        "password",
    ]
    exclude_fields_from_create = [
        "id",
        "stage_preferences",
        "hashed_password",
        "password_edit",
    ]

    async def create(self, request: Request, data: dict):
        session: AsyncSession = request.state.session
        errors: dict[str, str] = {}

        username = data["username"]
        password = data["password"]
        group_ids = data["groups"]

        await self._validate_username(username, session, errors)
        self._validate_password(password, errors)

        if errors:
            raise FormValidationError(errors)

        hashed_password = get_password_hash(password)
        groups = self._get_groups(session, group_ids)
        user = User(username=username, hashed_password=hashed_password, groups=groups)

        session.add(user)
        await session.commit()
        await session.refresh(user)

        return user

    async def edit(self, request: Request, pk: uuid.UUID, data: dict):
        session: AsyncSession = request.state.session
        errors: dict[str, str] = {}

        user = await session.get(User, pk)

        new_username = data["username"]
        new_password = data["password_edit"]
        new_groups = data["groups"]

        if user.username != new_username:
            await self._validate_username(new_username, session, errors)

        if new_password and self._validate_password(
            new_password, errors, "password_edit"
        ):
            hashed_password = get_password_hash(new_password)
            user.hashed_password = hashed_password

        if errors:
            raise FormValidationError(errors)

        user.username = new_username
        user.groups = await self._get_groups(session, new_groups)

        await session.commit()
        await session.refresh(user)

        return user

    async def _validate_username(
        self, username: str, session: AsyncSession | None, errors: dict[str, str]
    ) -> bool:
        if not (
            username is not None
            and self.USERNAME_MIN_LENGTH <= len(username) <= self.USERNAME_MAX_LENGTH
        ):
            errors["username"] = (
                f"Username must be between {self.USERNAME_MIN_LENGTH} and {self.USERNAME_MAX_LENGTH} characters long."
            )
            return False

        user_exists = (
            await session.scalars(select(User).where(User.username == username))
        ).first()
        if user_exists is not None:
            errors["username"] = f"User '{username}' already exists."
            return False

        return True

    def _validate_password(
        self, password: str, errors: dict[str, str], error_key: str = "password"
    ) -> bool:
        if not (
            password is not None
            and self.PASSWORD_MIN_LENGTH <= len(password) <= self.PASSWORD_MAX_LENGTH
        ):
            errors[error_key] = (
                f"Password must be between {self.PASSWORD_MIN_LENGTH} and {self.PASSWORD_MAX_LENGTH} characters long."
            )
            return False

        return True
