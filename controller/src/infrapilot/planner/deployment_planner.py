from typing import Any, Dict

from infrapilot.models.spec_models import InfraRequestSpec


def build_plan(spec: InfraRequestSpec) -> Dict[str, Any]:
    actions = [
        {
            "name": "base_install",
            "needed": True,
            "reason": "Ensure shared Tomcat runtime and app1 baseline are present.",
        },
        {
            "name": "scale",
            "needed": True,
            "reason": f"Reconcile desired instance count to {spec.deployment.instances}.",
            "desired_instances": spec.deployment.instances,
            "destroy_enabled": True,
        },
    ]

    steps = [
        "Validate inventory and reachability",
        "Ensure base Tomcat installation",
        "Scale to requested instance count",
        "Verify runtime health",
    ]

    return {
        "execution_mode": "apply",
        "target_group": spec.deployment.target_group,
        "requested_instances": spec.deployment.instances,
        "auto_recovery": spec.deployment.auto_recovery,
        "actions": actions,
        "steps": steps,
        "risk_level": "medium",
    }
