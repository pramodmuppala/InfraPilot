from fastapi import APIRouter

from infrapilot.services.execution_store import list_executions

router = APIRouter()


@router.get("/history")
def deploy_history(limit: int = 20):
    return [record.model_dump(mode="json") for record in list_executions(limit=limit)]
