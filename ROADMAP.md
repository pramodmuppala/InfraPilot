# InfraPilot Roadmap

InfraPilot demonstrates a guarded natural-language control plane for Tomcat operations. The roadmap below focuses on making the project easier to run, easier to review, and stronger as an evidence-backed infrastructure automation tool.

## Phase 1: Review-ready demo

- Add a one-command local demo.
- Add clearer setup instructions for Fedora/Ubuntu lab environments.
- Add dashboard screenshots and a short demo GIF/video.
- Add example prompts and expected outputs.
- Improve README wording around recovery metrics.
- Separate workflow execution success from functional recovery success.

## Phase 2: Test and benchmark evidence

- Expand testcase coverage for invalid and unsafe prompts.
- Add negative tests for out-of-range scaling requests.
- Add manual-vs-InfraPilot comparison steps.
- Add repeatable benchmark output under `docs/evidence/`.
- Add raw testcase logs and summarized reports.
- Document known failure modes and limitations.

## Phase 3: Recovery reliability

- Improve targeted recovery validation.
- Add post-recovery health confirmation.
- Add retry and timeout handling.
- Track recovery reason, action, result, and final health state.
- Add recovery history to dashboard/API views.

## Phase 4: Observability and operator experience

- Improve deployment and recovery status pages.
- Add clearer execution history.
- Add structured decision logs.
- Add API examples for every endpoint.
- Add OpenAPI/Swagger screenshots.
- Add status export for audit and review.

## Phase 5: Policy and safety hardening

- Strengthen policy validation rules.
- Add explicit bounds for scale-up and scale-down.
- Block ambiguous or unsafe prompts.
- Add policy simulation/dry-run mode.
- Add documentation for safety boundaries.
- Add tests proving prompts cannot bypass guarded execution.

## Phase 6: Extensibility

- Add cleaner runtime abstraction.
- Evaluate support for additional Java middleware runtimes.
- Add plugin-style execution adapters.
- Compare deterministic execution against free-form LLM automation.
- Publish a technical design note on the control-plane pattern.

## Contribution priorities

Most useful contributions right now:

1. one-command demo setup
2. recovery validation fixes
3. negative prompt tests
4. benchmark reports
5. dashboard/API screenshots
6. documentation improvements
