from __future__ import annotations

from datetime import datetime, UTC
from uuid import uuid4

from infrapilot.models.spec_models import ExecutionRecord, InfraRequestSpec
from infrapilot.services.execution_store import save_execution
from infrapilot.services.executor import run_base_install, run_scale


def _now() -> str:
    return datetime.now(UTC).isoformat()


def execute_spec(prompt: str, spec: dict, dry_run: bool = False) -> ExecutionRecord:
    request_id = f"req-{datetime.now(UTC).strftime('%Y%m%d%H%M%S')}-{uuid4().hex[:8]}"
    deployment_id = f"dep-{datetime.now(UTC).strftime('%Y%m%d%H%M%S')}-{uuid4().hex[:8]}"

    spec_model = InfraRequestSpec(**spec)

    started_at = _now()

    if dry_run:
        record = ExecutionRecord(
            deployment_id=deployment_id,
            request_id=request_id,
            mode="dry_run",
            prompt=prompt,
            spec=spec_model,
            started_at=started_at,
            completed_at=_now(),
            status="success",
            steps=[
                {"name": "base_install", "status": "planned"},
                {"name": "scale", "status": "planned"},
            ],
        )
        save_execution(record)
        return record

    steps = []

    base_result = run_base_install()
    steps.append(
        {
            "name": "base_install",
            "status": "success" if base_result.return_code == 0 else "failed",
            "return_code": base_result.return_code,
            "stdout": base_result.stdout,
            "stderr": base_result.stderr,
        }
    )

    scale_result = run_scale(spec_model.deployment.instances, destroy_enabled=True)
    steps.append(
        {
            "name": "scale",
            "status": "success" if scale_result.return_code == 0 else "failed",
            "return_code": scale_result.return_code,
            "stdout": scale_result.stdout,
            "stderr": scale_result.stderr,
        }
    )

    overall_status = "success" if all(step["status"] == "success" for step in steps) else "failed"

    record = ExecutionRecord(
        deployment_id=deployment_id,
        request_id=request_id,
        mode="apply",
        prompt=prompt,
        spec=spec_model,
        started_at=started_at,
        completed_at=_now(),
        status=overall_status,
        steps=steps,
    )
    save_execution(record)
    return record