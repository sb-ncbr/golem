from fastapi import Request, Response, status
from fastapi.responses import RedirectResponse
from fastapi.templating import Jinja2Templates
from starlette_admin import CustomView

from app.db.models.user import User
from app.services import auth


class UsageAdminView(CustomView):
    async def render(self, request: Request, templates: Jinja2Templates) -> Response:
        user: User = request.state.user
        if not auth.is_admin(user):
            return RedirectResponse(url="/", status_code=status.HTTP_404_NOT_FOUND)

        return templates.TemplateResponse(
            request=request, name="usage_admin.html", context={}
        )
