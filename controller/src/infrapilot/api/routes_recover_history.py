from fastapi import APIRouter

from infrapilot.services.recovery_store import list_recoveries

router = APIRouter()


@router.get("/recover/history")
def recover_history(limit: int = 20):
    return [record.model_dump(mode="json") for record in list_recoveries(limit=limit)]
