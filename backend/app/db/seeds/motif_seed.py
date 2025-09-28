from sqlmodel.ext.asyncio.session import AsyncSession

from app.db.models.motif import Motif, MotifDefinition

MOTIF_PRESETS: list[Motif] = [
    Motif(name="ABRE", definitions=[MotifDefinition(definition="ACGTG")], public=True),
    Motif(
        name="ARR10_core", definitions=[MotifDefinition(definition="GATY")], public=True
    ),
    Motif(
        name="BR_response element",
        definitions=[MotifDefinition(definition="CGTGYG")],
        public=True,
    ),
    Motif(
        name="CAAT-box", definitions=[MotifDefinition(definition="CCAATT")], public=True
    ),
    Motif(
        name="DOF_core motif",
        definitions=[MotifDefinition(definition="AAAG")],
        public=True,
    ),
    Motif(
        name="DRE/CRT element",
        definitions=[MotifDefinition(definition="CCGAC")],
        public=True,
    ),
    Motif(
        name="E-box", definitions=[MotifDefinition(definition="CANNTG")], public=True
    ),
    Motif(
        name="G-box", definitions=[MotifDefinition(definition="CACGTG")], public=True
    ),
    Motif(
        name="GCC-box", definitions=[MotifDefinition(definition="GCCGCC")], public=True
    ),
    Motif(
        name="GTGA motif", definitions=[MotifDefinition(definition="GTGA")], public=True
    ),
    Motif(
        name="I-box", definitions=[MotifDefinition(definition="GATAAG")], public=True
    ),
    Motif(
        name="pollen Q-element",
        definitions=[MotifDefinition(definition="AGGTCA")],
        public=True,
    ),
    Motif(
        name="POLLEN1_LeLAT52",
        definitions=[MotifDefinition(definition="AGAAA")],
        public=True,
    ),
    Motif(
        name="TATA-box", definitions=[MotifDefinition(definition="TATAWA")], public=True
    ),
]


async def seed(session: AsyncSession) -> None:
    session.add_all(MOTIF_PRESETS)
    await session.commit()
