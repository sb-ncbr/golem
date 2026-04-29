"""Ready route for checking if the service is running."""

from fastapi import APIRouter, Depends

from app.api.v1.schemas.response import ResponseSingle
from app.db.repositories.site_setting import SiteSettingRepository

from app.db.models.user import User
from app.services.auth import get_current_admin_user
from app.api.v1.schemas.site_setting import SettingUpdateRequest

settings_router = APIRouter(prefix="/settings", tags=["settings"])


@settings_router.get("/")
async def get_settings(
    settings_repository: SiteSettingRepository = Depends(SiteSettingRepository),
) -> ResponseSingle[dict]:
    settings = await settings_repository.get_all()
    return ResponseSingle(data=settings)


@settings_router.put("/")
async def update_setting(
    setting: SettingUpdateRequest,
    _: User = Depends(get_current_admin_user),
    settings_repository: SiteSettingRepository = Depends(SiteSettingRepository),
) -> ResponseSingle[dict]:
    await settings_repository.set(setting.key, setting.value)
    return ResponseSingle(data={"message": "Setting updated successfully."})


@settings_router.delete("/{key}")
async def delete_setting(
    key: str,
    _: User = Depends(get_current_admin_user),
    settings_repository: SiteSettingRepository = Depends(SiteSettingRepository),
) -> ResponseSingle[dict]:
    await settings_repository.delete(key)
    return ResponseSingle(data={"message": "Setting deleted successfully."})
