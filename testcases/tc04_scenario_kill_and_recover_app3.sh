#!/usr/bin/env bash
set -euo pipefail

API_BASE="${API_BASE:-http://10.211.55.38:8000}"
INVENTORY_FILE="${INVENTORY_FILE:-/home/parallels/Desktop/Parallels Shared Folders/Home/Desktop/Automation/InfraPilot/inventory/lab.ini}"
TARGET_GROUP="${TARGET_GROUP:-tomcat}"
CLEANUP_SCRIPT="${CLEANUP_SCRIPT:-/home/parallels/Desktop/Parallels Shared Folders/Home/Desktop/Automation/InfraPilot/Demo/cleanup_infrapilot_lab.sh}"
OUT_BASE="${OUT_BASE:-./testcase_results}"
mkdir -p "$OUT_BASE"
OUT_BASE="$(cd "$OUT_BASE" && pwd)"
RAW_DIR="${OUT_BASE}/raw"
mkdir -p "$RAW_DIR"

echo "Checking API health at ${API_BASE}..."
curl -sS "${API_BASE}/health" > "${OUT_BASE}/api_health.json"
python3 - <<PY
import json
with open("${OUT_BASE}/api_health.json", "r", encoding="utf-8") as f:
    data = json.load(f)
print(data)
PY

json_field() {
  local file="$1"
  local field="$2"

  if [[ ! -s "$file" ]]; then
    echo "ERROR: JSON file is empty: $file" >&2
    exit 1
  fi

  python3 - <<PY
import json
with open("$file", "r", encoding="utf-8") as f:
    data = json.load(f)
value = data
for part in "$field".split("."):
    value = value[part]
print(value)
PY
}

save_json_post() {
  local name="$1"
  local url="$2"
  local payload="$3"

  printf '%s\n' "$payload" > "${name}_payload.json"

  local http_code
  http_code=$(
    curl -sS \
      -o "${name}_response.json" \
      -w "%{http_code}" \
      -X POST "$url" \
      -H "Content-Type: application/json" \
      -d "$payload"
  )

  echo "$http_code" > "${name}_http_code.txt"

  if [[ ! -s "${name}_response.json" ]]; then
    echo "ERROR: ${name}_response.json is empty"
    exit 1
  fi

  python3 - <<PY
import json, sys
path = "${name}_response.json"
try:
    with open(path, "r", encoding="utf-8") as f:
        json.load(f)
except Exception as e:
    print(f"ERROR: invalid JSON in {path}: {e}")
    with open(path, "r", encoding="utf-8") as f:
        print(f.read())
    sys.exit(1)
PY
}

append_csv_row() {
  local csv_file="$1"
  local row="$2"
  printf '%s\n' "$row" >> "$csv_file"
}

ensure_results_header() {
  local csv_file="$1"
  if [[ ! -f "$csv_file" ]]; then
    printf '%s\n' "run_id,scenario,status,start_time,end_time,duration_seconds,requested_instances,deployment_id,recovery_id,healthy_count,unhealthy_count,notes" > "$csv_file"
  fi
}

RUN_ID="${RUN_ID:-run-$(date +%Y%m%d-%H%M%S)}"
RESULTS_CSV="${RESULTS_CSV:-${OUT_BASE}/results.csv}"
SCENARIO="kill_and_recover_app3"
RUN_DIR="${RAW_DIR}/${RUN_ID}_${SCENARIO}"
mkdir -p "$RUN_DIR"
ensure_results_header "$RESULTS_CSV"

start_epoch="$(date +%s)"
start_iso="$(date --iso-8601=seconds)"

cd "$RUN_DIR"

# Ensure 5 instances are deployed first
payload='{"prompt":"Deploy a scalable Java app with 5 instances and auto-recovery","dry_run":false}'
save_json_post execute "${API_BASE}/deploy/execute" "$payload"

deployment_id="$(json_field execute_response.json deployment_id)"

# Kill app3 on all tomcat nodes
ansible -i "$INVENTORY_FILE" "$TARGET_GROUP" -b -m shell -a \
"ps -eo pid,args | grep '[j]ava' | grep 'Dcatalina.base=/opt/tomcat/app3' | awk '{print \$1}' | xargs -r kill -9 || true" \
> kill_app3.txt 2>&1 || true

# Verify degraded state
verify_payload='{"expected_instances":5,"health_path":"/","timeout_seconds":10}'
save_json_post verify_before_recover "${API_BASE}/deploy/verify" "$verify_payload"

# Recover app3
recover_payload='{"instances":["app3"],"health_path":"/","timeout_seconds":20}'
save_json_post recover "${API_BASE}/deploy/recover" "$recover_payload"

recovery_id="$(json_field recover_response.json recovery_id)"
status="$(json_field recover_response.json status)"

# Verify healthy state after recovery
save_json_post verify_after_recover "${API_BASE}/deploy/verify" "$verify_payload"

healthy_count="$(python3 - <<PY
import json
with open("verify_after_recover_response.json", "r", encoding="utf-8") as f:
    d = json.load(f)
print(len(d.get("healthy_instances", [])))
PY
)"

unhealthy_count="$(python3 - <<PY
import json
with open("verify_after_recover_response.json", "r", encoding="utf-8") as f:
    d = json.load(f)
print(len(d.get("unhealthy_instances", [])))
PY
)"

end_epoch="$(date +%s)"
end_iso="$(date --iso-8601=seconds)"
duration="$((end_epoch - start_epoch))"

append_csv_row "$RESULTS_CSV" "${RUN_ID},${SCENARIO},${status},${start_iso},${end_iso},${duration},5,${deployment_id},${recovery_id},${healthy_count},${unhealthy_count},killed app3 and recovered"

echo "Completed ${SCENARIO} (${RUN_ID})"