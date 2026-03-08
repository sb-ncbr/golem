"""Ready route for checking if the service is running."""

from fastapi import APIRouter

from app.api.v1.schemas.response import ResponseSingle

ready_router = APIRouter(prefix="/ready", tags=["ready"])


@ready_router.get("/")
async def Ready() -> ResponseSingle[str]:
    return ResponseSingle(data="Service is ready.")
