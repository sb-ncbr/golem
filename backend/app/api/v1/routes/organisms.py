import pathlib

from fastapi import APIRouter, Depends, HTTPException
from starlette.responses import FileResponse

from app.api.v1.schemas.organism import OrganismResponse
from app.api.v1.schemas.response import ResponseList
from app.config import app_config
from app.db.repositories.organism import OrganismRepository, OrganismFilters
from app.db.models.user import User
from app.services.auth import get_current_user_optional, is_admin

organisms_router = APIRouter(prefix="/organisms", tags=["organisms"])


@organisms_router.get("/")
async def get_organisms(
    include_public: bool = True,
    organism_repository: OrganismRepository = Depends(),
    user: User | None = Depends(get_current_user_optional),
) -> ResponseList[OrganismResponse]:
    """
    Get a list of organisms of a logged-in user.
    """

    filters = OrganismFilters(
        user_id=user.id if user is not None else None,
        include_public=include_public,
        is_admin=is_admin(user)
    )

    organisms = await organism_repository.get(filters)
    data = [OrganismResponse.model_validate(organism) for organism in organisms]

    return ResponseList[OrganismResponse](data=data)


@organisms_router.get("/{filename}")
async def download_organism(
    filename: str,
    organism_repository: OrganismRepository = Depends(),
    user: User = Depends(get_current_user_optional),
) -> FileResponse:
    """
    Download an organism file of a logged-in user or public.
    """

    filters = OrganismFilters(
        user_id=user.id if user is not None else None,
        is_admin=is_admin(user)
    )
    organisms = await organism_repository.get(filters)
    organism = next(
        (
            organism
            for organism in organisms
            if organism.sequences_filename == filename
            or organism.metadata_filename == filename
        ),
        None,
    )
    not_found_exception = HTTPException(status_code=404, detail="Organism not found")

    if organism is None:
        raise not_found_exception

    if not organism.public and user is None:
        raise not_found_exception

    organism_groups = [group.name for group in organism.groups]
    user_groups = user.groups if user is not None else []
    has_group_access = is_admin(user) or any(
        group for group in user_groups if group.name in organism_groups
    )
    if not organism.public and not has_group_access:
        raise not_found_exception

    # TODO: move .gz somewhere else
    path = pathlib.Path(app_config.data_dir) / f"{filename}.gz"

    if not path.exists():
        raise not_found_exception

    return FileResponse(
        path.absolute(),
        media_type="application/gzip",
        headers={"Content-Encoding": "gzip"},
    )
