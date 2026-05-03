# Contributing to InfraPilot

Thanks for your interest in InfraPilot. This project explores a guarded natural-language control plane for Tomcat lifecycle operations.

Contributions are welcome in documentation, test coverage, benchmarks, dashboard/API usability, policy validation, recovery workflows, and new operator scenarios.

## Project scope

InfraPilot is intentionally bounded. It should translate operator intent into validated, deterministic automation, not arbitrary infrastructure generation.

In scope:

- Natural-language commands for Tomcat deployment and scaling
- Intent parsing and normalization
- Policy validation and safety bounds
- Deterministic Ansible-backed execution
- Runtime verification
- Targeted recovery workflows
- Dashboard and API usability
- Repeatable test cases and evidence generation

Out of scope for now:

- Unbounded free-form infrastructure changes
- Production claims without evidence
- Multi-runtime orchestration beyond the current design
- Unsafe scale-down or recovery behavior without validation

## How to contribute

1. Fork the repository.
2. Create a branch:
   ```bash
   git checkout -b feature/short-description
   ```
3. Make a focused change.
4. Run the available validation or testcase scripts.
5. Open a pull request with:
   - what changed
   - how it was tested
   - screenshots or logs, when relevant
   - any limitations or follow-up work

## Development expectations

Please keep changes reviewable and evidence-based.

Good contributions usually include one or more of:

- clear documentation
- repeatable commands
- before/after behavior
- logs, screenshots, or benchmark output
- tests for normal and failure scenarios
- safety considerations for operational actions

## Testing guidance

When changing deployment, scaling, verification, or recovery behavior, include the command used and the observed result.

Useful areas to validate:

- base deployment
- scale up
- scale down
- invalid or unsafe prompts
- failed Tomcat health check
- targeted recovery after killing an instance
- dashboard/API status visibility

## Safety and guardrails

InfraPilot should remain deterministic and auditable. Avoid changes that allow a natural-language prompt to execute arbitrary shell commands or bypass policy validation.

Any contribution touching intent parsing, policy validation, execution, or recovery should explain the safety boundary.

## Issue and discussion etiquette

Technical criticism is welcome. Please include enough detail for others to reproduce your observation:

- environment
- command or prompt used
- expected result
- actual result
- logs or screenshots, if available

## Pull request checklist

Before opening a PR, confirm:

- [ ] The change is focused and documented.
- [ ] The behavior is repeatable.
- [ ] Safety or policy impact is explained.
- [ ] Test commands or validation steps are included.
- [ ] No secrets, tokens, or local-only paths are committed.
