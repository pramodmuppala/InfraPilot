# InfraPilot Demo Scripts (Steps 1-5)

These scripts are intended to help you **collect reproducible demo data** for each milestone.

## Expected lab
- Fedora control plane running the API at `http://10.211.55.38:8000`
- Ubuntu nodes reachable through `inventory/lab.ini`
- InfraPilot repo at:
  `/home/parallels/Desktop/Parallels Shared Folders/Home/Desktop/Automation/InfraPilot`

## Scripts
- `step1_base_install_collect.sh`
- `step2_scale_collect.sh`
- `step3_api_collect.sh`
- `step4_execute_collect.sh`
- `step5_verify_recover_collect.sh`

## Common overrides
You can override variables when running any script, for example:

```bash
API_BASE=http://10.211.55.38:8000 INVENTORY_FILE=/path/to/lab.ini ./step4_execute_collect.sh
```

## Output
Each script creates an output folder like:

```text
./demo_outputs/<script-name>-YYYYmmdd-HHMMSS/
```

That folder contains:
- request payloads
- API responses
- command output
- process / port / filesystem state

## Make executable
```bash
chmod +x *.sh
```
