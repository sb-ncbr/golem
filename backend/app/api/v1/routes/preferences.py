from fastapi import APIRouter, HTTPException
from fastapi.params import Depends

from app.api.v1.schemas.preference import PreferenceUpdateRequest, PreferenceResponse
from app.api.v1.schemas.response import ResponseSingle
from app.db.models.stage_preference import StagePreference
from app.db.models.user import User
from app.db.repositories.user import UserRepository
from app.services.auth import get_current_user


preferences_router = APIRouter(prefix="/preferences", tags=["preferences"])


@preferences_router.put("/")
async def preferences(
    data: PreferenceUpdateRequest,
    user: User = Depends(get_current_user),
    user_repository: UserRepository = Depends(UserRepository),
) -> ResponseSingle[PreferenceResponse]:
    try:
        preference = next(
            (
                preference
                for preference in user.stage_preferences
                if preference.stage_name == data.stage_name
            ),
            None,
        )

        if preference is None:
            preference = StagePreference(
                stage_name=data.stage_name, color=data.color, user_id=user.id
            )
            user.stage_preferences.append(preference)
        else:
            preference.color = data.color

        await user_repository.update(user)

        return ResponseSingle(
            data=PreferenceResponse(stage_name=data.stage_name, color=data.color)
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail="Invalid color format.") from e
    except Exception as e:
        raise HTTPException(
            status_code=400, detail="Something went wrong when updating preference."
        ) from e
