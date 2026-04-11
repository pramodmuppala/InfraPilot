#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# InfraPilot lab cleanup
# Safe version
# ============================================================

INVENTORY_FILE="${INVENTORY_FILE:-/home/parallels/Desktop/Parallels Shared Folders/Home/Desktop/Automation/InfraPilot/inventory/lab.ini}"
TARGET_GROUP="${TARGET_GROUP:-tomcat}"
INSTANCE_PREFIX="${INSTANCE_PREFIX:-app}"
INSTANCE_START="${INSTANCE_START:-1}"
INSTANCE_END="${INSTANCE_END:-5}"

CATALINA_BASE_ROOT="${CATALINA_BASE_ROOT:-/opt/tomcat}"
CATALINA_HOME="${CATALINA_HOME:-/opt/products/tomcat/tomcat10}"
JAVA_HOME_PATH="${JAVA_HOME_PATH:-/usr/lib/jvm/default-java}"
RUNTIME_USER="${RUNTIME_USER:-parallels}"

# Set to true if you want to remove shared Tomcat install too
REMOVE_SHARED_HOME="${REMOVE_SHARED_HOME:-false}"

# Set this to your controller folder if you want runtime JSON logs cleaned too
CONTROLLER_ROOT="${CONTROLLER_ROOT:-/home/parallels/Desktop/Parallels Shared Folders/Home/Desktop/Automation/InfraPilot/controller}"
REMOVE_CONTROLLER_RUNTIME="${REMOVE_CONTROLLER_RUNTIME:-true}"

print_header() {
  echo
  echo "============================================================"
  echo "$1"
  echo "============================================================"
}

run_ansible_strict() {
  ansible -i "$INVENTORY_FILE" "$TARGET_GROUP" -b -m shell -a "$1"
}

run_ansible_safe() {
  ansible -i "$INVENTORY_FILE" "$TARGET_GROUP" -b -m shell -a "$1" || true
}

build_instance_list() {
  local items=()
  local i
  for ((i=INSTANCE_START; i<=INSTANCE_END; i++)); do
    items+=("${INSTANCE_PREFIX}${i}")
  done
  printf "%s " "${items[@]}"
}

INSTANCES="$(build_instance_list)"

print_header "Pre-checks"
echo "INVENTORY_FILE=$INVENTORY_FILE"
echo "TARGET_GROUP=$TARGET_GROUP"
echo "INSTANCES=$INSTANCES"
echo "CATALINA_BASE_ROOT=$CATALINA_BASE_ROOT"
echo "CATALINA_HOME=$CATALINA_HOME"
echo "REMOVE_SHARED_HOME=$REMOVE_SHARED_HOME"
echo "CONTROLLER_ROOT=$CONTROLLER_ROOT"
echo "REMOVE_CONTROLLER_RUNTIME=$REMOVE_CONTROLLER_RUNTIME"

command -v ansible >/dev/null 2>&1 || { echo "ansible is required"; exit 1; }

print_header "Current Java processes before cleanup"
run_ansible_safe "ps -ef | grep -i java | grep Dcatalina.base | grep -v grep || true"

print_header "Attempt graceful shutdown of known instances"
for inst in $INSTANCES; do
  echo "Stopping $inst ..."
  run_ansible_safe "export CATALINA_BASE='${CATALINA_BASE_ROOT}/${inst}'; export CATALINA_HOME='${CATALINA_HOME}'; export JAVA_HOME='${JAVA_HOME_PATH}'; su - ${RUNTIME_USER} -c '${CATALINA_HOME}/bin/shutdown.sh' || true"
done

print_header "Wait briefly after shutdown"
sleep 5

print_header "Force kill stray Java processes for known instances"
for inst in $INSTANCES; do
  echo "Killing stray Java processes for $inst ..."
  run_ansible_safe "ps -eo pid,args | grep '[j]ava' | grep 'Dcatalina.base=${CATALINA_BASE_ROOT}/${inst}' | awk '{print \$1}' | xargs -r kill -9 || true"
done

print_header "Force kill any remaining Tomcat Java processes under ${CATALINA_BASE_ROOT}"
run_ansible_safe "ps -eo pid,args | grep '[j]ava' | grep 'Dcatalina.base=${CATALINA_BASE_ROOT}/' | awk '{print \$1}' | xargs -r kill -9 || true"

print_header "Remove instance directories"
for inst in $INSTANCES; do
  echo "Removing ${CATALINA_BASE_ROOT}/${inst} ..."
  run_ansible_safe "rm -rf '${CATALINA_BASE_ROOT}/${inst}'"
done

print_header "Show remaining instance directories"
run_ansible_safe "ls -1 '${CATALINA_BASE_ROOT}' 2>/dev/null || true"

if [[ "${REMOVE_SHARED_HOME}" == "true" ]]; then
  print_header "Remove shared Tomcat home"
  run_ansible_safe "rm -rf '${CATALINA_HOME}' '${CATALINA_HOME%/*}/apache-tomcat-'* 2>/dev/null || true"
  run_ansible_safe "ls -ld '${CATALINA_HOME%/*}' 2>/dev/null || true"
fi

if [[ "${REMOVE_CONTROLLER_RUNTIME}" == "true" ]]; then
  print_header "Remove controller runtime execution/recovery records"
  rm -f "${CONTROLLER_ROOT}/runtime/executions"/*.json 2>/dev/null || true
  rm -f "${CONTROLLER_ROOT}/runtime/recoveries"/*.json 2>/dev/null || true
  mkdir -p "${CONTROLLER_ROOT}/runtime/executions"
  mkdir -p "${CONTROLLER_ROOT}/runtime/recoveries"
  echo "Controller runtime cleaned under ${CONTROLLER_ROOT}/runtime"
fi

print_header "Final Java processes after cleanup"
run_ansible_safe "ps -ef | grep -i java | grep Dcatalina.base | grep -v grep || true"

print_header "Cleanup complete"
echo "Known instances removed: $INSTANCES"
echo "Shared Tomcat removed: $REMOVE_SHARED_HOME"
echo "Controller runtime cleaned: $REMOVE_CONTROLLER_RUNTIME"
