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

print_header "Step 2 - Scale workflow data collection"

save_cmd api_health curl -sS "${API_BASE}/health"
save_cmd before_dirs ansible -i "${INVENTORY_FILE}" "${TARGET_GROUP}" -b -m shell -a 'ls -1 /opt/tomcat || true'
save_cmd before_ps ansible -i "${INVENTORY_FILE}" "${TARGET_GROUP}" -b -m shell -a "ps -ef | grep -i java | grep Dcatalina.base | grep -v grep || true"

print_header "Run scale script"
save_cmd scale_run /bin/bash -lc 'cd "/home/parallels/Desktop/Parallels Shared Folders/Home/Desktop/Automation/InfraPilot" && TOMCAT_INSTANCE_COUNT='"${EXPECTED_INSTANCES}"' TOMCAT_DESTROY_ENABLED=true ./scripts/run_scale.sh'

print_header "Collect host state after scaling"
save_cmd after_dirs ansible -i "${INVENTORY_FILE}" "${TARGET_GROUP}" -b -m shell -a 'ls -1 /opt/tomcat || true'
save_cmd after_ps ansible -i "${INVENTORY_FILE}" "${TARGET_GROUP}" -b -m shell -a "ps -ef | grep -i java | grep Dcatalina.base | grep -v grep || true"
save_cmd after_ports ansible -i "${INVENTORY_FILE}" "${TARGET_GROUP}" -b -m shell -a "ss -ltnp | egrep ':8080|:8180|:8280|:8380|:8480' || true"
save_cmd sample_logs ansible -i "${INVENTORY_FILE}" "${TARGET_GROUP}" -b -m shell -a 'for i in 1 2 3 4 5; do echo ==== app$i ====; tail -n 30 /opt/tomcat/app$i/logs/catalina.out 2>/dev/null || true; done'

echo "Saved outputs to: ${OUT_DIR}"
