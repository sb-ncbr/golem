"""Main module."""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from starlette_admin.contrib.sqlmodel import Admin

from app.admin.admin_base import AdminIndexView, AdminViewBase
from app.admin.group_admin import GroupAdminView
from app.admin.organism_admin import OrganismAdminView
from app.admin.stage_preference_admin import (
    UserStagePreferenceAdminView,
    DefaultStagePreferenceAdminView,
)
from app.admin.usage_admin import UsageAdminView
from app.admin.user_admin import UserAdminView
from app.api.v1.middleware.exception import http_exception_handler
from app.api.v1.middleware.user_loader import UserLoaderMiddleware
from app.api.v1.routes.auth import auth_router
from app.api.v1.routes.motifs import motifs_router
from app.api.v1.routes.organisms import organisms_router
from app.api.v1.routes.preferences import preferences_router
from app.api.v1.routes.ready import ready_router
from app.api.v1.routes.analytics import analytics_router
from app.db.db import engine
from app.db.models.group import Group
from app.db.models.motif import Motif, MotifDefinition
from app.db.models.organism import Organism
from app.db.models.stage_preference import UserStagePreference, DefaultStagePreference
from app.db.models.user import User


V1_PREFIX = "/api/v1"


def _setup_middleware(app: FastAPI) -> None:
    app.add_middleware(
        CORSMiddleware,  # warning: https://github.com/fastapi/fastapi/discussions/10968
        allow_origins=["http://localhost:4200"],  # TODO: add allowed origins
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    app.add_middleware(UserLoaderMiddleware)
    app.add_exception_handler(HTTPException, http_exception_handler)


def _setup_routes(app: FastAPI) -> None:
    app.include_router(router=ready_router, prefix=V1_PREFIX)
    app.include_router(router=auth_router, prefix=V1_PREFIX)
    app.include_router(router=organisms_router, prefix=V1_PREFIX)
    app.include_router(router=preferences_router, prefix=V1_PREFIX)
    app.include_router(router=motifs_router, prefix=V1_PREFIX)
    app.include_router(router=analytics_router, prefix=V1_PREFIX)


def _setup_admin(app: FastAPI) -> None:
    admin = Admin(
        engine=engine,
        title="GOLEM Admin",
        index_view=AdminIndexView(label="GOLEM Admin", path="/"),
        templates_dir="app/admin/templates",
        base_url="/admin",
    )

    admin.add_view(GroupAdminView(Group))
    admin.add_view(OrganismAdminView(Organism))
    admin.add_view(UserAdminView(User))
    admin.add_view(UserStagePreferenceAdminView(UserStagePreference))
    admin.add_view(DefaultStagePreferenceAdminView(DefaultStagePreference))
    admin.add_view(AdminViewBase(Motif))
    admin.add_view(AdminViewBase(MotifDefinition))
    admin.add_view(UsageAdminView(label="Usage", path="/usage"))

    admin.mount_to(app)


def create_app() -> FastAPI:
    app = FastAPI(title="GOLEM API v1", docs_url=None, redoc_url=None)

    _setup_middleware(app)
    _setup_routes(app)
    _setup_admin(app)

    return app


golem_app = create_app()
