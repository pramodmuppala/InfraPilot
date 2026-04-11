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

print_header "Step 1 - Base install data collection"

save_cmd env_pwd pwd
save_cmd api_health curl -sS "${API_BASE}/health"
save_cmd ansible_ping ansible -i "${INVENTORY_FILE}" "${TARGET_GROUP}" -m ping

print_header "Run base install script"
save_cmd base_install /bin/bash -lc 'cd "/home/parallels/Desktop/Parallels Shared Folders/Home/Desktop/Automation/InfraPilot" && ./scripts/run_base_install.sh'

print_header "Collect host state after base install"
save_cmd tomcat_dirs ansible -i "${INVENTORY_FILE}" "${TARGET_GROUP}" -b -m shell -a 'ls -ld /opt/products/tomcat /opt/products/tomcat/tomcat10 /opt/tomcat /opt/tomcat/app1 || true'
save_cmd tomcat_bin ansible -i "${INVENTORY_FILE}" "${TARGET_GROUP}" -b -m shell -a 'ls -l /opt/products/tomcat/tomcat10/bin/startup.sh /opt/products/tomcat/tomcat10/bin/catalina.sh || true'
save_cmd java_ps ansible -i "${INVENTORY_FILE}" "${TARGET_GROUP}" -b -m shell -a "ps -ef | grep -i java | grep Dcatalina.base | grep -v grep || true"
save_cmd ports ansible -i "${INVENTORY_FILE}" "${TARGET_GROUP}" -b -m shell -a "ss -ltnp | egrep ':8080|:8005|:10003' || true"
save_cmd app1_logs ansible -i "${INVENTORY_FILE}" "${TARGET_GROUP}" -b -m shell -a 'tail -n 100 /opt/tomcat/app1/logs/catalina.out 2>/dev/null || true'

echo "Saved outputs to: ${OUT_DIR}"
