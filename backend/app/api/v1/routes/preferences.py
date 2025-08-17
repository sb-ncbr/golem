from fastapi import APIRouter, HTTPException
from fastapi.params import Depends

from app.api.v1.schemas.preference import PreferenceUpdateRequest, PreferenceResponse
from app.api.v1.schemas.response import ResponseSingle, ResponseList
from app.db.models.stage_preference import UserStagePreference
from app.db.models.user import User
from app.db.repositories.preference import PreferenceRepository
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
            preference = UserStagePreference(
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


@preferences_router.get("/default")
async def default_preferences(
    preferences_repository: PreferenceRepository = Depends(PreferenceRepository),
) -> ResponseList[PreferenceResponse]:
    preferences = await preferences_repository.get_default()
    return ResponseList[PreferenceResponse](
        data=[
            PreferenceResponse.model_validate(preference) for preference in preferences
        ]
    )