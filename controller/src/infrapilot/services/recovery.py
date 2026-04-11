from __future__ import annotations

from datetime import datetime, UTC
from pathlib import Path
import os
import subprocess
from uuid import uuid4

from infrapilot.models.spec_models import RecoverRequest, RecoveryRecord, RecoveryStep
from infrapilot.services.recovery_store import save_recovery


def _now_iso() -> str:
    return datetime.now(UTC).isoformat()


def _controller_root() -> Path:
    # controller/src/infrapilot/services/recovery.py -> controller
    return Path(__file__).resolve().parents[3]


def _repo_root() -> Path:
    # controller -> InfraPilot
    return _controller_root().parent


def _recover_script_path() -> Path:
    return _repo_root() / "scripts" / "recover_instance.sh"


def _run_recover_script(instance: str) -> RecoveryStep:
    script_path = _recover_script_path()

    if not script_path.exists():
        return RecoveryStep(
            name="recover_instance",
            status="failed",
            instance=instance,
            return_code=127,
            stdout="",
            stderr=f"Recovery script not found: {script_path}",
        )

    env = os.environ.copy()
    env["INSTANCE_NAME"] = instance

    completed = subprocess.run(
        ["/bin/bash", str(script_path)],
        cwd=str(_repo_root()),
        env=env,
        capture_output=True,
        text=True,
        check=False,
    )

    return RecoveryStep(
        name="recover_instance",
        status="success" if completed.returncode == 0 else "failed",
        instance=instance,
        return_code=completed.returncode,
        stdout=completed.stdout,
        stderr=completed.stderr,
    )


def recover_instances(request: RecoverRequest) -> RecoveryRecord:
    recovery_id = f"rec-{datetime.now(UTC).strftime('%Y%m%d%H%M%S')}-{uuid4().hex[:8]}"
    started_at = _now_iso()

    steps: list[RecoveryStep] = []
    overall_status = "success"

    for instance in request.instances:
        step = _run_recover_script(instance)
        steps.append(step)
        if step.status != "success":
            overall_status = "failed"

    record = RecoveryRecord(
        recovery_id=recovery_id,
        instances=request.instances,
        health_path=request.health_path,
        timeout_seconds=request.timeout_seconds,
        started_at=started_at,
        completed_at=_now_iso(),
        status=overall_status,
        steps=steps,
    )

    save_recovery(record)
    return record