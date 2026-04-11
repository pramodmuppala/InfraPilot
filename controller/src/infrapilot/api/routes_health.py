from fastapi import APIRouter

from infrapilot.core.config import settings

router = APIRouter()


@router.get("/health")
def health() -> dict:
    return {"status": "ok", "app": settings.app_name}
