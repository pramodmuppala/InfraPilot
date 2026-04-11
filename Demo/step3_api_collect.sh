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

print_header "Step 3 - API/control-plane data collection"

save_cmd api_health curl -sS "${API_BASE}/health"
save_cmd api_root curl -sS "${API_BASE}/"

PARSE_PAYLOAD='{"prompt":"Deploy a scalable Java app with 5 instances and auto-recovery"}'
VALIDATE_PAYLOAD='{"spec":{"application":{"type":"java","artifact_source":"sample-war"},"runtime":{"platform":"tomcat","port":8080},"deployment":{"instances":5,"auto_recovery":true,"target_group":"tomcat"},"health_check":{"path":"/","interval_seconds":30}}}'
PLAN_PAYLOAD='{"prompt":"Deploy a scalable Java app with 5 instances and auto-recovery"}'

print_header "Parse intent"
save_json_post parse "${API_BASE}/intent/parse" "${PARSE_PAYLOAD}"

print_header "Validate spec"
save_json_post validate "${API_BASE}/spec/validate" "${VALIDATE_PAYLOAD}"

print_header "Generate plan"
save_json_post plan "${API_BASE}/deploy/plan" "${PLAN_PAYLOAD}"

echo "Saved outputs to: ${OUT_DIR}"
