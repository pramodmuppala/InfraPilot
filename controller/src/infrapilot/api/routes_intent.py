from fastapi import APIRouter

from infrapilot.models.spec_models import ParseIntentRequest, ParseIntentResponse
from infrapilot.parser.rule_parser import parse_prompt_to_spec
from infrapilot.services.id_factory import make_request_id

router = APIRouter()


@router.post("/parse", response_model=ParseIntentResponse)
def parse_intent(request: ParseIntentRequest) -> ParseIntentResponse:
    spec = parse_prompt_to_spec(request.prompt)
    return ParseIntentResponse(
        request_id=make_request_id(),
        parsed_spec=spec,
        warnings=[],
    )
