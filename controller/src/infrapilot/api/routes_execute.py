from fastapi import APIRouter, HTTPException

from infrapilot.models.spec_models import ExecuteRequest
from infrapilot.parser.rule_parser import parse_prompt_to_spec
from infrapilot.policy.validator import validate_spec
from infrapilot.services.deploy_orchestrator import execute_spec

router = APIRouter()


@router.post("/execute")
def deploy_execute(request: ExecuteRequest):
    parsed_spec = parse_prompt_to_spec(request.prompt)
    validation = validate_spec(parsed_spec)

    if not validation["valid"]:
        raise HTTPException(
            status_code=400,
            detail={
                "message": "Spec validation failed",
                "violations": validation["violations"],
                "normalized_spec": validation["normalized_spec"],
            },
        )

    normalized = validation["normalized_spec"]

    record = execute_spec(
        prompt=request.prompt,
        spec=normalized,
        dry_run=request.dry_run,
    )
    return record