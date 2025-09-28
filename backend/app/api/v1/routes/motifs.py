import uuid

from fastapi import APIRouter, Depends, HTTPException

from app.api.v1.schemas.motif import MotifResponse, MotifCreateRequest
from app.api.v1.schemas.response import ResponseList, ResponseSingle
from app.db.models.motif import Motif, MotifDefinition
from app.db.repositories.motif import MotifRepository, MotifFilters
from app.db.models.user import User
from app.services.auth import get_current_user, get_current_user_optional

motifs_router = APIRouter(prefix="/motifs", tags=["motifs"])


@motifs_router.get("/")
async def get_motifs(
    motif_repository: MotifRepository = Depends(MotifRepository),
    user: User | None = Depends(get_current_user_optional),
) -> ResponseList[MotifResponse]:
    filters = MotifFilters(user_id=user.id if user else None)
    motifs = await motif_repository.get(filters)

    data = [
        MotifResponse(
            id=motif.id,
            name=motif.name,
            definitions=[definition.definition for definition in motif.definitions],
            public=motif.public,
        )
        for motif in motifs
    ]

    return ResponseList[MotifResponse](data=data)


@motifs_router.post("/")
async def create_motif(
    data: MotifCreateRequest,
    motif_repository: MotifRepository = Depends(MotifRepository),
    user: User = Depends(get_current_user),
) -> ResponseSingle[MotifResponse]:
    motif = Motif(
        name=data.name,
        user_id=user.id,
        definitions=[
            MotifDefinition(definition=definition) for definition in data.definitions
        ],
        public=False,
    )
    await motif_repository.create(motif)

    data = MotifResponse(
        id=motif.id,
        name=motif.name,
        definitions=[definition.definition for definition in motif.definitions],
        public=motif.public,
    )

    return ResponseSingle[MotifResponse](data=data)

@motifs_router.delete("/{id}")
async def delete_motif(
    id: uuid.UUID,
    motif_repository: MotifRepository = Depends(MotifRepository),
    user: User = Depends(get_current_user)
) -> ResponseSingle[None]:
    motif = await motif_repository.get_by_id(id)
    not_found_exception = HTTPException(status_code=404, detail="Motif not found")

    if not motif or motif.user_id != user.id:
        raise not_found_exception

    await motif_repository.delete(id)

    return ResponseSingle(data=None)