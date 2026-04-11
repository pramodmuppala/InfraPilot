from fastapi import APIRouter

from infrapilot.models.spec_models import ValidateSpecRequest, ValidateSpecResponse
from infrapilot.policy.validator import validate_spec

router = APIRouter()


@router.post("/validate", response_model=ValidateSpecResponse)
def validate_spec_route(request: ValidateSpecRequest) -> ValidateSpecResponse:
    valid, violations, normalized = validate_spec(request.spec)
    return ValidateSpecResponse(valid=valid, violations=violations, normalized_spec=normalized if valid else None)
