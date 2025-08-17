from fastapi import Request, Response
from starlette.responses import RedirectResponse
from starlette.status import HTTP_404_NOT_FOUND
from starlette.templating import Jinja2Templates
from starlette_admin import CustomView
from starlette_admin.contrib.sqlmodel import ModelView

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
