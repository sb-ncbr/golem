from sqlmodel.ext.asyncio.session import AsyncSession

from app.db.models.organism import Organism

ORGANISM_PRESETS = [
    Organism(
        name="Chara braunii",
        sequences_filename="Chara_braunii.fasta",
        metadata_filename="Chara_braunii.metadata.json",
        description="ATG",
        take_first_transcript_only=False,
        public=True,
    ),
    Organism(
        name="Marchantia polymorpha",
        sequences_filename="Marchantia_polymorpha-with-tss.fasta",
        metadata_filename="Marchantia_polymorpha-with-tss.metadata.json",
        description="ATG, TSS",
        take_first_transcript_only=True,
        public=True,
    ),
    Organism(
        name="Physcomitrium patens",
        sequences_filename="Physcomitrium_patens-with-tss.fasta",
        metadata_filename="Physcomitrium_patens-with-tss.metadata.json",
        description="ATG, TSS",
        take_first_transcript_only=True,
        public=True,
    ),
    Organism(
        name="Azolla filiculoides",
        sequences_filename="Azolla_filiculoides.fasta",
        metadata_filename="Azolla_filiculoides.metadata.json",
        description="ATG",
        take_first_transcript_only=False,
        public=True,
    ),
    Organism(
        name="Ceratopteris richardii",
        sequences_filename="Ceratopteris_richardii-with-tss.fasta",
        metadata_filename="Ceratopteris_richardii-with-tss.metadata.json",
        description="ATG, TSS",
        take_first_transcript_only=True,
        public=True,
    ),
    Organism(
        name="Amborella trichopoda",
        sequences_filename="Amborella_trichopoda.fasta",
        metadata_filename="Amborella_trichopoda.metadata.json",
        description="ATG",
        take_first_transcript_only=False,
        public=True,
    ),
    Organism(
        name="Oryza sativa",
        sequences_filename="Oryza_sativa.fasta",
        metadata_filename="Oryza_sativa.metadata.json",
        description="ATG",
        take_first_transcript_only=True,
        public=True,
    ),
    Organism(
        name="Hordeum vulgare",
        sequences_filename="Hordeum_vulgare-with-tss.fasta",
        metadata_filename="Hordeum_vulgare-with-tss.metadata.json",
        description="ATG, TSS",
        take_first_transcript_only=True,
        public=True,
    ),
    Organism(
        name="Zea mays",
        sequences_filename="Zea_mays-with-tss.fasta",
        metadata_filename="Zea_mays-with-tss.metadata.json",
        description="ATG, TSS",
        take_first_transcript_only=True,
        public=True,
    ),
    Organism(
        name="Solanum lycopersicum",
        sequences_filename="Solanum_lycopersicum-with-tss.fasta",
        metadata_filename="Solanum_lycopersicum-with-tss.metadata.json",
        description="ATG, TSS",
        take_first_transcript_only=True,
        public=True,
    ),
    Organism(
        name="Arabidopsis thaliana",
        sequences_filename="Arabidopsis_thaliana-with-tss.fasta",
        metadata_filename="Arabidopsis_thaliana-with-tss.metadata.json",
        description="ATG, TSS",
        take_first_transcript_only=True,
        public=True,
    ),
]


async def seed(session: AsyncSession) -> None:
    session.add_all(ORGANISM_PRESETS)
    await session.commit()
    