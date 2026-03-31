import json
from datetime import datetime, timezone, timedelta
from pathlib import Path

from fastapi import APIRouter, Depends, Query, Request, status
from fastapi.responses import RedirectResponse

from app.services.auth import get_current_user, get_current_user_optional
from app.db.models.user import User

from app.api.v1.schemas.response import ResponseSingle

from app.config import app_config
from app.api.v1.schemas.usage_stats import UsageStats

analytics_router = APIRouter(prefix="/analytics", tags=["analytics"])

LOG_FILE = Path(app_config.data_dir) / "analysis_usage.jsonl"


@analytics_router.post("/track")
async def track_analysis(
    request: Request,
    user: User | None = Depends(get_current_user_optional),
) -> ResponseSingle:
    """Track an analysis start event."""

    log_entry = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "username": user.username if user else None,
        "ip": _get_client_ip(request),
    }

    with open(LOG_FILE, "a+") as f:
        f.writelines(json.dumps(log_entry) + "\n")

    return ResponseSingle(data=None)


@analytics_router.get("/stats")
async def get_usage_stats(
    start_date: str | None = Query(default=None, description="Start date (YYYY-MM-DD)"),
    end_date: str | None = Query(default=None, description="End date (YYYY-MM-DD)"),
    user: User = Depends(get_current_user),
) -> ResponseSingle[UsageStats]:
    """Get usage statistics filtered by date range."""

    if not user.is_admin():
        return RedirectResponse(url="/", status_code=status.HTTP_404_NOT_FOUND)

    if not LOG_FILE.exists():
        return ResponseSingle(
            data=UsageStats(
                unique_users=0,
                total_analyses=0,
                logged_in_analyses=0,
                anonymous_analyses=0,
            )
        )

    if end_date is None:
        end_date = datetime.now(timezone.utc).date().isoformat()
    if start_date is None:
        start_date = (
            datetime.now(timezone.utc).date() - timedelta(days=365)
        ).isoformat()

    unique_users = set()
    total_analyses = 0
    logged_in_analyses = 0
    anonymous_analyses = 0

    try:
        with open(LOG_FILE, "r") as f:
            for line in f:
                try:
                    entry = json.loads(line.strip())
                    entry_timestamp = datetime.fromisoformat(
                        entry["timestamp"].replace("Z", "+00:00")
                    )
                    entry_date = entry_timestamp.date().isoformat()

                    if entry_date > end_date:
                        break

                    if start_date <= entry_date <= end_date:
                        total_analyses += 1
                        username = entry.get("username")
                        ip = entry.get("ip")

                        if username:
                            unique_users.add(username)
                            logged_in_analyses += 1
                        else:
                            unique_users.add(ip)
                            anonymous_analyses += 1
                except (json.JSONDecodeError, KeyError, ValueError):
                    continue
    except FileNotFoundError:
        pass

    return ResponseSingle(
        data=UsageStats(
            unique_users=len(unique_users),
            total_analyses=total_analyses,
            logged_in_analyses=logged_in_analyses,
            anonymous_analyses=anonymous_analyses,
        )
    )


def _get_client_ip(request: Request) -> str:
    forwarded = request.headers.get("x-forwarded-for")
    if forwarded:
        # X-Forwarded-For: <client>, <proxy>, …, <proxyN>
        return forwarded.split(",")[0].strip()

    return request.client.host if request.client else "unknown"
