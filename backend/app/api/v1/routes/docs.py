from fastapi import APIRouter
from fastapi.responses import RedirectResponse


docs_router = APIRouter(prefix="/docs", tags=["docs"])


@docs_router.get("/")
async def get_docs():
    return RedirectResponse(
        url="https://drive.google.com/file/d/1EFfUJUjOmB2I-NPqfbtPiiuEvXRdcQsp/view"
    )
