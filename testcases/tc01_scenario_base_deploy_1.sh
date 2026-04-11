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
  local csv_dir
  csv_dir="$(dirname "$csv_file")"
  mkdir -p "$csv_dir"

  if [[ ! -f "$csv_file" ]]; then
    printf '%s\n' "run_id,scenario,status,start_time,end_time,duration_seconds,requested_instances,deployment_id,recovery_id,healthy_count,unhealthy_count,notes" > "$csv_file"
  fi
}

RUN_ID="${RUN_ID:-run-$(date +%Y%m%d-%H%M%S)}"
RESULTS_CSV="${RESULTS_CSV:-${OUT_BASE}/results.csv}"
SCENARIO="base_deploy_1"
RUN_DIR="${RAW_DIR}/${RUN_ID}_${SCENARIO}"
mkdir -p "$RUN_DIR"
ensure_results_header "$RESULTS_CSV"

start_epoch="$(date +%s)"
start_iso="$(date --iso-8601=seconds)"

if [[ -x "$CLEANUP_SCRIPT" ]]; then
  "$CLEANUP_SCRIPT" > "${RUN_DIR}/cleanup.txt" 2>&1 || true
fi

cd "$RUN_DIR"

payload='{"prompt":"Deploy a scalable Java app with 1 instance and auto-recovery","dry_run":false}'
save_json_post execute "${API_BASE}/deploy/execute" "$payload"

deployment_id="$(json_field execute_response.json deployment_id)"
status="$(json_field execute_response.json status)"

verify_payload='{"expected_instances":1,"health_path":"/","timeout_seconds":10}'
save_json_post verify "${API_BASE}/deploy/verify" "$verify_payload"

healthy_count="$(python3 - <<PY
import json
with open("verify_response.json", "r", encoding="utf-8") as f:
    d = json.load(f)
print(len(d.get("healthy_instances", [])))
PY
)"

unhealthy_count="$(python3 - <<PY
import json
with open("verify_response.json", "r", encoding="utf-8") as f:
    d = json.load(f)
print(len(d.get("unhealthy_instances", [])))
PY
)"

end_epoch="$(date +%s)"
end_iso="$(date --iso-8601=seconds)"
duration="$((end_epoch - start_epoch))"

append_csv_row "$RESULTS_CSV" "${RUN_ID},${SCENARIO},${status},${start_iso},${end_iso},${duration},1,${deployment_id},,${healthy_count},${unhealthy_count},base deployment to 1 instance"

echo "Completed ${SCENARIO} (${RUN_ID})"