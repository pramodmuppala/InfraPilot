import os
import subprocess
from pathlib import Path
from typing import Dict, Optional

from infrapilot.core.config import settings
from infrapilot.models.spec_models import CommandResult


def _validate_package_root() -> Path:
    root = Path(settings.ansible_package_root).expanduser().resolve()

    required_paths = [
        root / "scripts",
        root / "playbooks",
        root / "inventory",
        root / "templates",
    ]

    missing = [str(p) for p in required_paths if not p.exists()]
    if missing:
        raise ValueError(
            f"InfraPilot root auto-detected as {root}, but required paths are missing: {missing}"
        )

    return root


def _run_script(script_name: str, extra_env: Optional[Dict[str, str]] = None) -> CommandResult:
    root = _validate_package_root()
    script_path = root / "scripts" / script_name
    if not script_path.exists():
        raise ValueError(f"Script not found: {script_path}")

    env = os.environ.copy()
    if extra_env:
        env.update(extra_env)

    completed = subprocess.run(
        ["/bin/bash", str(script_path)],
        cwd=str(root),
        env=env,
        capture_output=True,
        text=True,
        check=False,
    )
    return CommandResult(
        command=str(script_path),
        return_code=completed.returncode,
        stdout=completed.stdout,
        stderr=completed.stderr,
    )


def run_base_install() -> CommandResult:
    return _run_script("run_base_install.sh")


def run_scale(instance_count: int, destroy_enabled: bool = True) -> CommandResult:
    env = {
        "TOMCAT_INSTANCE_COUNT": str(instance_count),
        "TOMCAT_DESTROY_ENABLED": "true" if destroy_enabled else "false",
    }
    return _run_script("run_scale.sh", extra_env=env)


def run_recover_instance(instance_name: str, health_path: str = "/", timeout_seconds: int = 20) -> CommandResult:
    env = {
        "INSTANCE_NAME": instance_name,
        "HEALTH_PATH": health_path,
        "TIMEOUT_SECONDS": str(timeout_seconds),
    }
    return _run_script("recover_instance.sh", extra_env=env)
