from fastapi import APIRouter, HTTPException

from infrapilot.models.spec_models import DeployPlanRequest, DeployPlanResponse
from infrapilot.parser.rule_parser import parse_prompt_to_spec
from infrapilot.planner.deployment_planner import build_plan
from infrapilot.policy.validator import validate_spec
from infrapilot.services.id_factory import make_request_id

router = APIRouter()


@router.post("/plan", response_model=DeployPlanResponse)
def deploy_plan(request: DeployPlanRequest) -> DeployPlanResponse:
    if request.spec is not None:
        spec = request.spec
    elif request.prompt:
        spec = parse_prompt_to_spec(request.prompt)
    else:
        raise HTTPException(status_code=400, detail="Either prompt or spec is required.")

    valid, violations, normalized = validate_spec(spec)
    if not valid:
        raise HTTPException(status_code=400, detail={"violations": violations})

    return DeployPlanResponse(
        request_id=make_request_id(),
        plan=build_plan(normalized),
    )
