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
KILL_INSTANCE="${KILL_INSTANCE:-app3}"
HEALTH_PATH="${HEALTH_PATH:-/}"

print_header "Step 5 - Verify/recover data collection"

VERIFY_PAYLOAD=$(cat <<EOF
{
  "expected_instances": ${EXPECTED_INSTANCES},
  "health_path": "${HEALTH_PATH}",
  "timeout_seconds": 10
}
EOF
)

print_header "Verify healthy state"
save_json_post verify_before "${API_BASE}/deploy/verify" "${VERIFY_PAYLOAD}"

print_header "Kill instance ${KILL_INSTANCE}"
save_cmd kill_instance ansible -i "${INVENTORY_FILE}" "${TARGET_GROUP}" -b -m shell -a "pgrep -af 'Dcatalina.base=/opt/tomcat/${KILL_INSTANCE}' | awk '{print \$1}' | xargs -r kill -9"
save_cmd killed_check ansible -i "${INVENTORY_FILE}" "${TARGET_GROUP}" -b -m shell -a "ps -ef | grep -v grep | grep 'Dcatalina.base=/opt/tomcat/${KILL_INSTANCE}' || true"

print_header "Verify degraded state"
save_json_post verify_after_kill "${API_BASE}/deploy/verify" "${VERIFY_PAYLOAD}"

RECOVER_PAYLOAD=$(cat <<EOF
{
  "instances": ["${KILL_INSTANCE}"],
  "health_path": "${HEALTH_PATH}",
  "timeout_seconds": 20
}
EOF
)

print_header "Recover ${KILL_INSTANCE}"
save_json_post recover "${API_BASE}/deploy/recover" "${RECOVER_PAYLOAD}"

RECOVERY_ID="$(json_field "${OUT_DIR}/recover_response.json" "recovery_id")"
echo "${RECOVERY_ID}" > "${OUT_DIR}/recovery_id.txt"
echo "RECOVERY_ID=${RECOVERY_ID}"

print_header "Get recovery status"
save_json_get recover_status "${API_BASE}/deploy/recover/status/${RECOVERY_ID}"

print_header "Verify healthy again"
save_json_post verify_after_recovery "${API_BASE}/deploy/verify" "${VERIFY_PAYLOAD}"

print_header "Get recovery history"
save_json_get recover_history "${API_BASE}/deploy/recover/history"

print_header "Collect final host state"
save_cmd final_ps ansible -i "${INVENTORY_FILE}" "${TARGET_GROUP}" -b -m shell -a "ps -ef | grep -i java | grep Dcatalina.base | grep -v grep || true"
save_cmd final_logs ansible -i "${INVENTORY_FILE}" "${TARGET_GROUP}" -b -m shell -a 'for i in 1 2 3 4 5; do echo ==== app$i ====; tail -n 50 /opt/tomcat/app$i/logs/catalina.out 2>/dev/null || true; done'

echo "Saved outputs to: ${OUT_DIR}"
