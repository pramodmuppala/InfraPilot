from fastapi import APIRouter, HTTPException

from infrapilot.services.execution_store import load_execution

router = APIRouter()


@router.get("/status/{deployment_id}")
def deploy_status(deployment_id: str):
    record = load_execution(deployment_id)
    if record is None:
        raise HTTPException(status_code=404, detail="deployment_id not found")
    return record.model_dump(mode="json")
