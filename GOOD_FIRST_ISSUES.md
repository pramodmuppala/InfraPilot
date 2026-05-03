# Good First Issues for InfraPilot

This file lists contribution ideas for engineers who want to review or improve InfraPilot. Please open an issue before starting larger changes.

## Documentation

### Add a 5-minute quickstart

Create a short setup path that lets a new user run the basic flow with minimal assumptions.

Expected output:

- prerequisites
- setup commands
- first prompt to try
- expected result
- troubleshooting notes

Labels: `documentation`, `good first issue`

### Add prompt examples with expected behavior

Document supported prompts such as deployment, scale-up, scale-down, and invalid requests.

Include:

- prompt
- parsed intent
- expected target instance count
- validation result
- execution behavior

Labels: `documentation`, `testing`, `good first issue`

### Add dashboard screenshots

Add current dashboard screenshots under `docs/` and reference them from the README.

Labels: `documentation`, `dashboard`, `good first issue`

## Testing

### Add invalid prompt test cases

Add tests for prompts that should be rejected.

Examples:

- unsupported runtime
- negative instance count
- excessive scale-up request
- ambiguous command
- destructive request

Labels: `testing`, `policy`, `good first issue`

### Clarify recovery testcase result

Improve the recovery testcase output so it separates:

- workflow execution success
- actual Tomcat recovery success
- final health status

Labels: `testing`, `recovery`, `good first issue`

### Add testcase log examples

Add sanitized example logs for base deploy, scale-up, scale-down, and recovery.

Labels: `testing`, `documentation`, `good first issue`

## Benchmarking

### Add manual-vs-InfraPilot comparison

Create a small benchmark showing manual steps versus InfraPilot-assisted steps.

Track:

- number of commands
- elapsed time
- success/failure result
- operator actions required

Labels: `benchmark`, `documentation`

### Add benchmark report template

Create `docs/evidence/BENCHMARK_TEMPLATE.md` with fields for environment, scenario, run count, duration, and observations.

Labels: `benchmark`, `good first issue`

## Safety

### Add policy-boundary documentation

Document what InfraPilot will and will not execute from natural-language input.

Labels: `policy`, `documentation`, `good first issue`

### Add dry-run examples

Add examples showing how an operator can inspect the planned action before execution.

Labels: `policy`, `documentation`

## API and dashboard

### Add curl examples for API endpoints

Document example calls for parsing, validation, deployment, status, verification, and recovery.

Labels: `api`, `documentation`, `good first issue`

### Improve status response examples

Add sample JSON responses for deployment status and recovery status.

Labels: `api`, `documentation`
