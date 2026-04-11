from fastapi import APIRouter, HTTPException

from infrapilot.core.config import settings
from infrapilot.models.spec_models import RecoverRequest
from infrapilot.services.recovery import recover_instances

router = APIRouter()


@router.post("/recover")
def deploy_recover(request: RecoverRequest):
    if not settings.allow_execution:
        raise HTTPException(status_code=403, detail="Execution is disabled. Set ALLOW_EXECUTION=true.")
    record = recover_instances(request)
    return record.model_dump(mode="json")
