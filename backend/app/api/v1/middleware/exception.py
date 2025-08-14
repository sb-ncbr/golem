from fastapi import HTTPException, Request
from starlette.responses import JSONResponse

from app.api.v1.schemas.response import ErrorResponse


async def http_exception_handler(_: Request, exception: HTTPException) -> JSONResponse:
    """
    Handle HTTP exceptions and return a JSON response with an error message.
    """

    return JSONResponse(
        status_code=exception.status_code,
        content=ErrorResponse(message=exception.detail).model_dump(mode="json"),
    )