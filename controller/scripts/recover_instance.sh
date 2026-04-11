#!/usr/bin/env bash
set -euo pipefail

INSTANCE_NAME="${INSTANCE_NAME:-}"
HEALTH_PATH="${HEALTH_PATH:-/}"
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-20}"

if [[ -z "${INSTANCE_NAME}" ]]; then
  echo "INSTANCE_NAME is required" >&2
  exit 1
fi

RUNTIME_USER="${RUNTIME_USER:-parallels}"
CATALINA_BASE_ROOT="${CATALINA_BASE_ROOT:-/opt/tomcat}"
CATALINA_HOME="${CATALINA_HOME:-/opt/products/tomcat/tomcat10}"
JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/default-java}"

INSTANCE_BASE="${CATALINA_BASE_ROOT}/${INSTANCE_NAME}"

if [[ ! -d "${INSTANCE_BASE}" ]]; then
  echo "Instance base does not exist: ${INSTANCE_BASE}" >&2
  exit 1
fi

run_as_user() {
  su - "${RUNTIME_USER}" -c "$1"
}

run_as_user "export CATALINA_BASE='${INSTANCE_BASE}'; export CATALINA_HOME='${CATALINA_HOME}'; export JAVA_HOME='${JAVA_HOME}'; '${CATALINA_HOME}/bin/shutdown.sh' || true"
sleep 3
pkill -f "Dcatalina.base=${INSTANCE_BASE}" || true
sleep 2
run_as_user "export CATALINA_BASE='${INSTANCE_BASE}'; export CATALINA_HOME='${CATALINA_HOME}'; export JAVA_HOME='${JAVA_HOME}'; '${CATALINA_HOME}/bin/startup.sh'"

echo "Recovery invoked for ${INSTANCE_NAME}"
