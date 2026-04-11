from datetime import datetime
from uuid import uuid4


def make_request_id() -> str:
    return f"req-{datetime.utcnow().strftime('%Y%m%d%H%M%S')}-{uuid4().hex[:8]}"


def make_deployment_id() -> str:
    return f"dep-{datetime.utcnow().strftime('%Y%m%d%H%M%S')}-{uuid4().hex[:8]}"


def make_recovery_id() -> str:
    return f"rec-{datetime.utcnow().strftime('%Y%m%d%H%M%S')}-{uuid4().hex[:8]}"
