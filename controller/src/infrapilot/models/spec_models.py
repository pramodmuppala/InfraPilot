from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, Field, ConfigDict


class ApplicationSpec(BaseModel):
    type: str = "java"
    artifact_source: str = "sample-war"


class RuntimeSpec(BaseModel):
    platform: str = "tomcat"
    port: int = 8080


class DeploymentSpec(BaseModel):
    instances: int = 1
    auto_recovery: bool = False
    target_group: str = "tomcat"


class HealthCheckSpec(BaseModel):
    path: str = "/"
    interval_seconds: int = 30


class InfraRequestSpec(BaseModel):
    application: ApplicationSpec
    runtime: RuntimeSpec
    deployment: DeploymentSpec
    health_check: HealthCheckSpec


class ParseIntentRequest(BaseModel):
    prompt: str


class ParseIntentResponse(BaseModel):
    request_id: str
    parsed_spec: InfraRequestSpec
    warnings: list[str] = Field(default_factory=list)


class ValidateSpecRequest(BaseModel):
    spec: dict[str, Any] | InfraRequestSpec


class ValidateSpecResponse(BaseModel):
    valid: bool
    violations: list[str] = Field(default_factory=list)
    normalized_spec: InfraRequestSpec


class DeployPlanRequest(BaseModel):
    prompt: str


class DeployPlanResponse(BaseModel):
    request_id: str
    plan: dict[str, Any]


class ExecuteRequest(BaseModel):
    prompt: str
    dry_run: bool = False


class InstanceHealth(BaseModel):
    model_config = ConfigDict(
        populate_by_name=True,
        extra="allow",
    )

    instance: str = Field(alias="instance_name")
    directory_exists: bool = False
    process_running: bool = False
    port_open: bool = False
    http_healthy: bool = False
    expected_port: int | None = None
    details: dict[str, Any] = Field(default_factory=dict)


class VerifyDeployRequest(BaseModel):
    expected_instances: int = 1
    health_path: str = "/"
    timeout_seconds: int = 10


class VerifyDeployResponse(BaseModel):
    status: str
    expected_instances: int = 1
    healthy_instances: list[str] = Field(default_factory=list)
    unhealthy_instances: list[str] = Field(default_factory=list)
    details: dict[str, Any] = Field(default_factory=dict)
    instance_results: list[InstanceHealth] = Field(default_factory=list)


class RecoverRequest(BaseModel):
    instances: list[str]
    health_path: str = "/"
    timeout_seconds: int = 20


class CommandResult(BaseModel):
    command: str
    return_code: int
    stdout: str = ""
    stderr: str = ""


class ExecutionStep(BaseModel):
    name: str
    status: str
    return_code: int | None = None
    stdout: str | None = None
    stderr: str | None = None


class RecoveryStep(BaseModel):
    name: str
    status: str
    instance: str | None = None
    return_code: int | None = None
    stdout: str | None = None
    stderr: str | None = None


class ExecutionRecord(BaseModel):
    deployment_id: str
    request_id: str
    mode: Literal["dry_run", "apply"]
    prompt: str
    spec: InfraRequestSpec
    started_at: str
    completed_at: str
    status: str
    steps: list[ExecutionStep | dict[str, Any]] = Field(default_factory=list)


class RecoveryRecord(BaseModel):
    recovery_id: str
    instances: list[str] = Field(default_factory=list)
    health_path: str = "/"
    timeout_seconds: int = 20
    started_at: str = ""
    completed_at: str = ""
    status: str
    steps: list[RecoveryStep | dict[str, Any]] = Field(default_factory=list)