import asyncio, os, sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))

# importing models so they are initialized in the correct order
from app.db.models.group import Group # noqa
from app.db.models.organism import Organism # noqa
from app.db.models.user import User # noqa

from app.db.seeds.user_seed import seed as seed_users
from app.db.seeds.motif_seed import seed as seed_motifs
from app.db.seeds.organism_seed import seed as seed_organisms
from app.db.db import get_session


async def _seed():
    async for session in get_session():
        await seed_users(session)
        await seed_motifs(session)
        await seed_organisms(session)


if __name__ == "__main__":
    asyncio.run(_seed())