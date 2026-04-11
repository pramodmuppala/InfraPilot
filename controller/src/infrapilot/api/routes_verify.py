from fastapi import APIRouter

from infrapilot.models.spec_models import VerifyDeployRequest, VerifyDeployResponse
from infrapilot.services.verifier import verify_instances

router = APIRouter()


@router.post("/verify", response_model=VerifyDeployResponse)
def deploy_verify(request: VerifyDeployRequest) -> VerifyDeployResponse:
    return verify_instances(
        expected_instances=request.expected_instances,
        health_path=request.health_path,
        timeout_seconds=request.timeout_seconds,
    )
