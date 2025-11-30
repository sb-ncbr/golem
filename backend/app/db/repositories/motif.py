import uuid

from fastapi import Depends
from sqlmodel import or_, select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.db import db
from app.db.models.motif import Motif
from app.db.models.user import User
from app.db.repositories.user import UserRepository
from app.schemas.base import BaseSchema


class MotifFilters(BaseSchema):
    """
    Filters for motifs.
    """

    user_id: uuid.UUID | None = None
    is_admin: bool = False


class MotifRepository:
    """
    A repository for Motif management.
    """

    def __init__(self, session: AsyncSession = Depends(db.get_session)) -> None:
        self.session = session

    async def get_by_id(self, id: uuid.UUID) -> Motif | None:
        """
        Get motif by id.

        Args:
            id (uuid.UUID): The id of the motif to get.

        Returns:
            Motif | None: The motif with the given id or None if not found.
        """

        motif = await self.session.get(Motif, id)
        return motif

    async def get(self, filters: MotifFilters = None) -> list[Motif]:
        """
        Get a list of filtered motifs.

        Args:
            filters (MotifFilters): Filters to apply.

        Returns:
            list[Motif]: The list of motifs matching the filters.
        """

        filters = filters or MotifFilters()

        statement = select(Motif).where(
            or_(filters.is_admin, Motif.user_id == filters.user_id, Motif.public == True)
        )
        motifs = await self.session.execute(statement)

        return list(motifs.scalars().all())

    async def create(self, motif: Motif) -> Motif:
        """
        Create a new motif.

        Args:
            motif (Motif): The motif to create.

        Returns:
            Motif: The created motif.
        """
        self.session.add(motif)
        await self.session.commit()
        await self.session.refresh(motif)

        return motif

    async def delete(self, id: uuid.UUID) -> None:
        """
        Delete a motif by id.

        Args:
            id (uuid.UUID): The id of the motif to delete.
        """
        motif = await self.get_by_id(id)
        if not motif:
            raise ValueError("Motif not found")

        await self.session.delete(motif)
        await self.session.commit()
        