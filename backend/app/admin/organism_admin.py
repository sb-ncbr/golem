import aiofiles, asyncio, lzma, uuid

from sqlmodel.ext.asyncio.session import AsyncSession
from starlette_admin import FileField

from fastapi import Request, UploadFile
from starlette_admin.exceptions import FormValidationError

from app.admin.admin_base import AdminViewBase
from app.config import app_config
from app.db.models.organism import Organism


class OrganismAdminView(AdminViewBase):
    NAME_MIN_LENGTH = 3
    NAME_MAX_LENGTH = 128
    DESCRIPTION_MAX_LENGTH = 1024

    model = Organism
    fields = [
        "name",
        "description",
        FileField("sequences_file", label="FASTA File", required=True, accept=".fasta"),
        FileField(
            "metadata_file", label="Metadata File", required=True, accept=".json"
        ),
        FileField("sequences_file_edit", label="FASTA File", accept=".fasta"),
        FileField("metadata_file_edit", label="Metadata File", accept=".json"),
        "public",
        "groups",
    ]
    exclude_fields_from_list = [
        "id",
        "sequences_file",
        "metadata_file",
        "sequences_file_edit",
        "metadata_file_edit",
    ]
    exclude_fields_from_edit = ["id", "sequences_file", "metadata_file"]
    exclude_fields_from_create = ["id", "sequences_file_edit", "metadata_file_edit"]

    async def create(self, request: Request, data: dict) -> Organism:
        session: AsyncSession = request.state.session
        errors: dict[str, str] = {}

        name = data["name"]
        description = data["description"]
        public = data["public"]
        group_ids = data["groups"]
        sequences_file = data["sequences_file"][0]
        metadata_file = data["metadata_file"][0]

        self._validate_name(name, errors)
        self._validate_description(description, errors)
        self._validate_file(sequences_file, errors, "sequences_file")
        self._validate_file(metadata_file, errors, "metadata_file")

        if errors:
            raise FormValidationError(errors)

        sequence_filename, metadata_filename = await asyncio.gather(
            self._store_file(sequences_file),
            self._store_file(metadata_file),
        )

        groups = await OrganismAdminView._get_groups(session, group_ids)

        organism = Organism(
            name=name,
            description=description,
            public=public,
            groups=groups,
            sequences_filename=sequence_filename,
            metadata_filename=metadata_filename,
        )

        session.add(organism)
        await session.commit()
        await session.refresh(organism)

        return organism

    async def edit(self, request: Request, pk: uuid.UUID, data: dict) -> Organism:
        session: AsyncSession = request.state.session
        errors: dict[str, str] = {}

        name = data["name"]
        description = data["description"]
        public = data["public"]
        group_ids = data["groups"]
        sequences_file = data["sequences_file_edit"][0]
        metadata_file = data["metadata_file_edit"][0]

        organism = await session.get(Organism, pk)

        if name != organism.name:
            self._validate_name(name, errors)

        if description != organism.description:
            self._validate_description(description, errors)

        if errors:
            raise FormValidationError(errors)

        if sequences_file:
            sequence_filename = await self._store_file(sequences_file)
            organism.sequences_filename = sequence_filename

        if metadata_file:
            metadata_filename = await self._store_file(metadata_file)
            organism.metadata_filename = metadata_filename

        groups = await self._get_groups(session, group_ids)

        organism.name = name
        organism.description = description
        organism.public = public
        organism.groups = groups

        await session.commit()
        await session.refresh(organism)

        return organism

    @staticmethod
    async def _store_file(file: UploadFile) -> str:
        data_dir = app_config.data_dir
        file_path = f"{data_dir}/{file.filename}.xz"
        chunk_size = 1024 * 1024  # 1 MB

        compressor = lzma.LZMACompressor(format=lzma.FORMAT_XZ)

        async with aiofiles.open(file_path, "wb") as out_file:
            while content := await file.read(chunk_size):
                compressed_chunk = await asyncio.to_thread(compressor.compress, content)
                await out_file.write(compressed_chunk)

            flushed_chunk = await asyncio.to_thread(compressor.flush)
            await out_file.write(flushed_chunk)

        return f"{file.filename}.xz"

    @staticmethod
    def _validate_name(name: str, errors: dict[str, str]):
        min_len, max_len = (
            OrganismAdminView.NAME_MIN_LENGTH,
            OrganismAdminView.NAME_MAX_LENGTH,
        )
        if not (name is not None and min_len <= len(name) <= max_len):
            errors["name"] = (
                f"Organism name must be between {OrganismAdminView.NAME_MIN_LENGTH} and {OrganismAdminView.NAME_MAX_LENGTH} characters long."
            )
            return False

        return True

    @staticmethod
    def _validate_description(description: str, errors: dict[str, str]):
        description = description or ""
        if len(description) > OrganismAdminView.DESCRIPTION_MAX_LENGTH:
            errors["description"] = (
                f"Organism description must at most {OrganismAdminView.DESCRIPTION_MAX_LENGTH} characters long."
            )
            return False

        return True

    @staticmethod
    def _validate_file(file: UploadFile | None, errors: dict[str, str], error_key: str):
        if file is None:
            errors[error_key] = "File is required."
            return False

        return True