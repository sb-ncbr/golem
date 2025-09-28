import uuid
from typing import Any, Dict

from fastapi import Request
from sqlmodel.ext.asyncio.session import AsyncSession
from starlette_admin import ListField, StringField

from app.admin.admin_base import AdminViewBase
from app.db.models.motif import Motif, MotifDefinition


class MotifAdminView(AdminViewBase):
    model = Motif

    fields = [
        "name",
        "definitions",
        ListField(
            StringField("motif_definitions", label="Definition"),
            required=True,

        ),
    ]

    exclude_fields_from_form = ["definitions"]
    exclude_fields_from_list = ["id", "motif_definitions"]
    exclude_fields_from_detail = ["motif_definitions"]

    def _populate_obj(
        self,
        request: Request,
        obj: Any,
        data: Dict[str, Any],
        is_edit: bool = False,
    ) -> Any:
        obj = super()._populate_obj(request, obj, data, is_edit)

        obj.motif_definitions = [
            definition.definition for definition in data["definitions"]
        ]

        return obj

    async def create(self, request: Request, data: dict):
        session: AsyncSession = request.state.session
        errors: dict[str, str] = {}

        name = data["name"]
        definitions = data["motif_definitions"]

        motif = Motif(
            name=name,
            definitions=[
                MotifDefinition(definition=definition) for definition in definitions
            ],
        )

        session.add(motif)
        await session.commit()
        await session.refresh(motif)

        return motif

    async def edit(self, request: Request, pk: uuid.UUID, data: dict):
        session: AsyncSession = request.state.session
        errors: dict[str, str] = {}

        name = data["name"]
        definitions = data["definitions"]

        motif = await session.get(Motif, pk)

        motif.name = name
        motif.definitions = self._unique_definitions(definitions, motif.definitions)

        await session.commit()
        await session.refresh(motif)

        return motif

    @staticmethod
    def _unique_definitions(
        new_definitions: list[str], existing_definitions: list[MotifDefinition]
    ) -> list[MotifDefinition]:
        definitions = set(
            *[definition.definition for definition in existing_definitions],
            *new_definitions,
        )

        return [MotifDefinition(definition=definition) for definition in definitions]
