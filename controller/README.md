# InfraPilot Controller

FastAPI control plane for natural-language driven Tomcat deployment, scaling, verification, and targeted recovery.

## Features

- Parse constrained natural-language deployment prompts
- Validate supported deployment specs
- Produce deployment plans
- Execute base install and scale workflows through existing InfraPilot scripts
- Persist deployment execution history
- Verify expected Tomcat instances
- Recover named failed instances

## Expected layout

Place this package under:

```text
InfraPilot/
  inventory/
  playbooks/
  scripts/
  templates/
  controller/
```

The controller auto-detects the parent `InfraPilot` directory.

## Start

```bash
python3.11 -m venv .venv
source .venv/bin/activate
pip install -U pip
pip install -r requirements.txt
cp .env.example .env
export PYTHONPATH="$(pwd)/src"
uvicorn infrapilot.main:app --host 0.0.0.0 --port 8000
```

## Important

Your parent `InfraPilot/scripts/` directory must include:

- `run_base_install.sh`
- `run_scale.sh`
- `recover_instance.sh`

`run_scale.sh` should honor:

- `TOMCAT_INSTANCE_COUNT`
- `TOMCAT_DESTROY_ENABLED`

`recover_instance.sh` should honor:

- `INSTANCE_NAME`
- `HEALTH_PATH`
- `TIMEOUT_SECONDS`
