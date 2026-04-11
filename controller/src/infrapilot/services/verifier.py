from __future__ import annotations

import subprocess
from typing import Any

from infrapilot.models.spec_models import InstanceHealth, VerifyDeployResponse


CATALINA_BASE_ROOT = "/opt/tomcat"
INSTANCE_PREFIX = "app"
BASE_HTTP_PORT = 8080
PORT_STRIDE = 100


def _run_remote_check(command: str) -> tuple[int, str, str]:
    completed = subprocess.run(
        ["/bin/bash", "-lc", command],
        capture_output=True,
        text=True,
        check=False,
    )
    return completed.returncode, completed.stdout.strip(), completed.stderr.strip()


def _expected_port(instance_number: int) -> int:
    return BASE_HTTP_PORT + ((instance_number - 1) * PORT_STRIDE)


def _instance_name_list(expected_instances: int) -> list[str]:
    return [f"{INSTANCE_PREFIX}{i}" for i in range(1, expected_instances + 1)]


def verify_instances(
    expected_instances: int,
    health_path: str = "/",
    timeout_seconds: int = 10,
) -> VerifyDeployResponse:
    instance_results: list[InstanceHealth] = []
    healthy_instances: list[str] = []
    unhealthy_instances: list[str] = []

    for i, instance_name in enumerate(_instance_name_list(expected_instances), start=1):
        expected_port = _expected_port(i)
        instance_base = f"{CATALINA_BASE_ROOT}/{instance_name}"

        dir_rc, _, _ = _run_remote_check(f"test -d '{instance_base}'")
        ps_rc, ps_out, _ = _run_remote_check(
            f"ps -ef | grep '[j]ava' | grep 'Dcatalina.base={instance_base}'"
        )
        port_rc, _, _ = _run_remote_check(
            f"ss -ltn | grep ':{expected_port} '"
        )
        http_rc, http_out, http_err = _run_remote_check(
            f"curl -sS -m {timeout_seconds} -o /dev/null -w '%{{http_code}}' "
            f"http://127.0.0.1:{expected_port}{health_path}"
        )

        directory_exists = dir_rc == 0
        process_running = ps_rc == 0 and bool(ps_out)
        port_open = port_rc == 0
        http_healthy = http_rc == 0 and http_out == "200"

        if directory_exists and process_running and port_open and http_healthy:
            healthy_instances.append(instance_name)
            overall_status = "healthy"
        else:
            unhealthy_instances.append(instance_name)
            overall_status = "unhealthy"

        row = InstanceHealth(
            instance_name=instance_name,
            directory_exists=directory_exists,
            process_running=process_running,
            port_open=port_open,
            http_healthy=http_healthy,
            expected_port=expected_port,
            details={
                "instance_base": instance_base,
                "http_status": http_out,
                "http_error": http_err,
                "overall_status": overall_status,
            },
        )
        instance_results.append(row)

    status = "healthy" if not unhealthy_instances else "degraded"

    return VerifyDeployResponse(
    status=status,
    expected_instances=expected_instances,
    healthy_instances=healthy_instances,
    unhealthy_instances=unhealthy_instances,
    details={
        "health_path": health_path,
        "timeout_seconds": timeout_seconds,
    },
    instance_results=instance_results,
    )
    
    