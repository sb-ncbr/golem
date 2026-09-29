"""Proxy route for fetching motif matrices from the public JASPAR API.
   Should solve the CORS problem.
"""

import httpx
from fastapi import APIRouter, HTTPException

from app.api.v1.schemas.response import ResponseSingle

jaspar_router = APIRouter(prefix="/jaspar", tags=["jaspar"])

JASPAR_API_BASE = "https://jaspar.elixir.no/api/v1/matrix"


@jaspar_router.get("/{motif_id}")
async def get_jaspar_motif(motif_id: str) -> ResponseSingle[dict]:
    url = f"{JASPAR_API_BASE}/{motif_id}/?format=json"

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(url)
    except httpx.RequestError as exc:
        raise HTTPException(
            status_code=502, detail=f"Could not reach JASPAR: {exc}"
        ) from exc

    if response.status_code == 404:
        raise HTTPException(
            status_code=404, detail=f'No JASPAR matrix found for id "{motif_id}".'
        )
    if response.status_code != 200:
        raise HTTPException(
            status_code=502,
            detail=f"JASPAR returned status {response.status_code}.",
        )

    return ResponseSingle(data=response.json())
