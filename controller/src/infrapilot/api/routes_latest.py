from fastapi import APIRouter, HTTPException

from infrapilot.services.execution_store import list_execution_records, load_execution
from infrapilot.services.recovery_store import list_recovery_records, load_recovery

router = APIRouter()


@router.get("/latest")
def latest_deployment():
    records = list_execution_records()
    if not records:
        raise HTTPException(status_code=404, detail="no deployment records found")
    latest = records[0]
    deployment_id = latest.get("deployment_id")
    if not deployment_id:
        raise HTTPException(status_code=404, detail="latest deployment record is malformed")
    record = load_execution(deployment_id)
    if not record:
        raise HTTPException(status_code=404, detail="latest deployment record not found")
    return record


@router.get("/recover/latest")
def latest_recovery():
    records = list_recovery_records()
    if not records:
        raise HTTPException(status_code=404, detail="no recovery records found")
    latest = records[0]
    recovery_id = latest.get("recovery_id")
    if not recovery_id:
        raise HTTPException(status_code=404, detail="latest recovery record is malformed")
    record = load_recovery(recovery_id)
    if not record:
        raise HTTPException(status_code=404, detail="latest recovery record not found")
    return record
