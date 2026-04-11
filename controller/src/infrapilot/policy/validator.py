from __future__ import annotations

from typing import Any


MIN_INSTANCES = 1
MAX_INSTANCES = 5
SUPPORTED_APP_TYPES = {"java"}
SUPPORTED_RUNTIMES = {"tomcat"}


def validate_spec(spec: dict[str, Any]) -> dict[str, Any]:
    violations: list[str] = []

    application = spec.get("application", {})
    runtime = spec.get("runtime", {})
    deployment = spec.get("deployment", {})
    health_check = spec.get("health_check", {})

    app_type = str(application.get("type", "")).lower()
    runtime_platform = str(runtime.get("platform", "")).lower()

    if app_type not in SUPPORTED_APP_TYPES:
        violations.append(
            f"Unsupported application type '{app_type}'. Supported types: {sorted(SUPPORTED_APP_TYPES)}."
        )

    if runtime_platform not in SUPPORTED_RUNTIMES:
        violations.append(
            f"Unsupported runtime platform '{runtime_platform}'. Supported runtimes: {sorted(SUPPORTED_RUNTIMES)}."
        )

    instances = deployment.get("instances")
    try:
        instances = int(instances)
    except (TypeError, ValueError):
        violations.append("Deployment instances must be an integer.")
        instances = None

    if instances is not None and not (MIN_INSTANCES <= instances <= MAX_INSTANCES):
        violations.append(
            f"Requested instance count {instances} is out of supported range. "
            f"Supported range is {MIN_INSTANCES} to {MAX_INSTANCES} instances."
        )

    auto_recovery = bool(deployment.get("auto_recovery", False))
    health_path = health_check.get("path")

    if auto_recovery and not health_path:
        violations.append("Auto-recovery requires a health_check.path to be defined.")

    normalized_spec = {
        "application": {
            "type": app_type or "java",
            "artifact_source": application.get("artifact_source", "sample-war"),
        },
        "runtime": {
            "platform": runtime_platform or "tomcat",
            "port": int(runtime.get("port", 8080)),
        },
        "deployment": {
            "instances": instances if instances is not None else 1,
            "auto_recovery": auto_recovery,
            "target_group": deployment.get("target_group", "tomcat"),
        },
        "health_check": {
            "path": health_path or "/",
            "interval_seconds": int(health_check.get("interval_seconds", 30)),
        },
    }

    return {
        "valid": len(violations) == 0,
        "violations": violations,
        "normalized_spec": normalized_spec,
    }