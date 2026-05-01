from fastapi import APIRouter, Depends, HTTPException, Request
from fastapi.responses import RedirectResponse

from app.db.repositories.site_setting import SiteSettingRepository


docs_router = APIRouter(prefix="/docs", tags=["docs"])


@docs_router.get("/")
async def get_docs(
    settings_repository: SiteSettingRepository = Depends(SiteSettingRepository),
):
    """Redirect to the documentation page."""

    setting = await settings_repository.get("manual_url")

    if setting is None:
        raise HTTPException(status_code=404, detail="Manual URL is not configured.")

    return RedirectResponse(url=setting.value)
