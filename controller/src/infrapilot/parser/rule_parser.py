import re
from typing import Any


DEFAULT_SPEC: dict[str, Any] = {
    "application": {
        "type": "java",
        "artifact_source": "sample-war",
    },
    "runtime": {
        "platform": "tomcat",
        "port": 8080,
    },
    "deployment": {
        "instances": 1,
        "auto_recovery": False,
        "target_group": "tomcat",
    },
    "health_check": {
        "path": "/",
        "interval_seconds": 30,
    },
}


_SCALE_PATTERNS = [
    re.compile(
        r"\b(?P<action>increase|decrease|scale|set|run)\s+"
        r"(?P<target>jvms?|tomcats?|instances?|nodes?)\s+"
        r"(?:to\s+)?(?P<count>\d+)\b",
        re.IGNORECASE,
    ),
    re.compile(
        r"\b(?P<action>increase|decrease|scale|set)\s+"
        r"(?:to\s+)?(?P<count>\d+)\s+"
        r"(?P<target>jvms?|tomcats?|instances?|nodes?)\b",
        re.IGNORECASE,
    ),
    re.compile(
        r"\bdeploy\b.*?\bwith\s+(?P<count>\d+)\s+"
        r"(?P<target>jvms?|tomcats?|instances?|nodes?)\b",
        re.IGNORECASE,
    ),
]


def _base_spec() -> dict[str, Any]:
    return {
        "application": dict(DEFAULT_SPEC["application"]),
        "runtime": dict(DEFAULT_SPEC["runtime"]),
        "deployment": dict(DEFAULT_SPEC["deployment"]),
        "health_check": dict(DEFAULT_SPEC["health_check"]),
    }


def _extract_instance_count(prompt: str) -> int | None:
    for pattern in _SCALE_PATTERNS:
        match = pattern.search(prompt)
        if match:
            return int(match.group("count"))

    generic = re.search(
        r"\b(?P<count>\d+)\s+(?:instances?|jvms?|tomcats?|nodes?)\b",
        prompt,
        re.IGNORECASE,
    )
    if generic:
        return int(generic.group("count"))

    return None


def _has_auto_recovery(prompt: str) -> bool:
    keywords = [
        "auto-recovery",
        "auto recovery",
        "autorecovery",
        "recover automatically",
        "self-heal",
        "self heal",
    ]
    lowered = prompt.lower()
    return any(k in lowered for k in keywords)


def _looks_like_scale_request(prompt: str) -> bool:
    lowered = prompt.lower()
    keywords = [
        "increase",
        "decrease",
        "scale",
        "set",
        "run",
        "deploy",
        "jvm",
        "tomcat",
        "instance",
        "node",
    ]
    return any(k in lowered for k in keywords)


def parse_prompt(prompt: str) -> dict[str, Any]:
    spec = _base_spec()
    lowered = prompt.lower()

    if "java" in lowered:
        spec["application"]["type"] = "java"

    if "tomcat" in lowered or "jvm" in lowered or "instance" in lowered or "node" in lowered:
        spec["runtime"]["platform"] = "tomcat"
        spec["deployment"]["target_group"] = "tomcat"

    count = _extract_instance_count(prompt)
    if count is not None:
        spec["deployment"]["instances"] = count

    if "scalable" in lowered and count is None:
        spec["deployment"]["instances"] = max(spec["deployment"]["instances"], 2)

    spec["deployment"]["auto_recovery"] = _has_auto_recovery(prompt)

    return spec


def can_parse(prompt: str) -> bool:
    return _looks_like_scale_request(prompt)


def parse_prompt_to_spec(prompt: str) -> dict[str, Any]:
    return parse_prompt(prompt)