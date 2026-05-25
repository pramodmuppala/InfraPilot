from fastapi import APIRouter

from infrapilot.models.spec_models import ValidateSpecRequest, ValidateSpecResponse
from infrapilot.policy.validator import validate_spec

router = APIRouter()


@router.post("/validate", response_model=ValidateSpecResponse)
def validate_spec_route(request: ValidateSpecRequest) -> ValidateSpecResponse:
    result = validate_spec(request.spec)
    valid = result.get("valid", False)
    violations = result.get("violations", [])
    normalized = result.get("normalized_spec") or result.get("normalized")
    return ValidateSpecResponse(
        valid=valid,
        violations=violations,
        normalized_spec=normalized if valid else None,
    )
