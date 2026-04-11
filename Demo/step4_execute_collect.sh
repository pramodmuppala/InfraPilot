#!/usr/bin/env bash
set -euo pipefail

API_BASE="${API_BASE:-http://10.211.55.38:8000}"
INVENTORY_FILE="${INVENTORY_FILE:-/home/parallels/Desktop/Parallels Shared Folders/Home/Desktop/Automation/InfraPilot/inventory/lab.ini}"
TARGET_GROUP="${TARGET_GROUP:-tomcat}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
SCRIPT_NAME="$(basename "$0" .sh)"
OUT_DIR="${OUT_DIR:-./demo_outputs/${SCRIPT_NAME}-${TIMESTAMP}}"
mkdir -p "$OUT_DIR"

HAS_JQ=false
if command -v jq >/dev/null 2>&1; then
  HAS_JQ=true
fi

print_header() {
  echo
  echo "============================================================"
  echo "$1"
  echo "============================================================"
}

save_cmd() {
  local name="$1"
  shift
  {
    echo "+ $*"
    "$@"
  } > "${OUT_DIR}/${name}.txt" 2>&1 || true
  cat "${OUT_DIR}/${name}.txt"
}

save_json_post() {
  local name="$1"
  local url="$2"
  local payload="$3"
  printf '%s\n' "$payload" > "${OUT_DIR}/${name}_payload.json"
  curl -sS -X POST "$url" \
    -H "Content-Type: application/json" \
    -d "$payload" \
    -o "${OUT_DIR}/${name}_response.json"
  if [[ "$HAS_JQ" == true ]]; then jq . "${OUT_DIR}/${name}_response.json"; else cat "${OUT_DIR}/${name}_response.json"; fi
}

save_json_get() {
  local name="$1"
  local url="$2"
  curl -sS -X GET "$url" -o "${OUT_DIR}/${name}_response.json"
  if [[ "$HAS_JQ" == true ]]; then jq . "${OUT_DIR}/${name}_response.json"; else cat "${OUT_DIR}/${name}_response.json"; fi
}

json_field() {
  local file="$1"
  local field="$2"
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

EXPECTED_INSTANCES="${EXPECTED_INSTANCES:-5}"
DESTROY_ENABLED="${DESTROY_ENABLED:-true}"

print_header "Step 4 - Execute/status/history data collection"

EXEC_PAYLOAD=$(cat <<EOF
{
  "prompt": "Deploy a scalable Java app with ${EXPECTED_INSTANCES} instances and auto-recovery",
  "dry_run": false
}
EOF
)

print_header "Execute deployment"
save_json_post execute "${API_BASE}/deploy/execute" "${EXEC_PAYLOAD}"

DEPLOYMENT_ID="$(json_field "${OUT_DIR}/execute_response.json" "deployment_id")"
echo "${DEPLOYMENT_ID}" > "${OUT_DIR}/deployment_id.txt"
echo "DEPLOYMENT_ID=${DEPLOYMENT_ID}"

print_header "Get deployment status"
save_json_get status "${API_BASE}/deploy/status/${DEPLOYMENT_ID}"

print_header "Get deployment history"
save_json_get history "${API_BASE}/deploy/history"

print_header "Collect host state after execute"
save_cmd after_ps ansible -i "${INVENTORY_FILE}" "${TARGET_GROUP}" -b -m shell -a "ps -ef | grep -i java | grep Dcatalina.base | grep -v grep || true"
save_cmd after_dirs ansible -i "${INVENTORY_FILE}" "${TARGET_GROUP}" -b -m shell -a 'ls -1 /opt/tomcat || true'
save_cmd after_ports ansible -i "${INVENTORY_FILE}" "${TARGET_GROUP}" -b -m shell -a "ss -ltnp | egrep ':8080|:8180|:8280|:8380|:8480' || true"

echo "Saved outputs to: ${OUT_DIR}"
