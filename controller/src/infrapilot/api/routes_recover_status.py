from fastapi import APIRouter, HTTPException

from infrapilot.services.recovery_store import load_recovery

router = APIRouter()


@router.get("/recover/status/{recovery_id}")
def recover_status(recovery_id: str):
    record = load_recovery(recovery_id)
    if record is None:
        raise HTTPException(status_code=404, detail="recovery_id not found")
    return record.model_dump(mode="json")
