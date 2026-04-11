#!/usr/bin/env bash
set -euo pipefail

INSTANCE_NAME="${INSTANCE_NAME:?INSTANCE_NAME is required}"
HEALTH_PATH="${HEALTH_PATH:-/}"
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-20}"

RUNTIME_USER="${RUNTIME_USER:-parallels}"
CATALINA_BASE_ROOT="${CATALINA_BASE_ROOT:-/opt/tomcat}"
CATALINA_HOME="${CATALINA_HOME:-/opt/products/tomcat/tomcat10}"
JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/default-java}"

CATALINA_BASE="${CATALINA_BASE_ROOT}/${INSTANCE_NAME}"

if [[ ! -d "${CATALINA_BASE}" ]]; then
  echo "Instance base does not exist: ${CATALINA_BASE}" >&2
  exit 2
fi

INSTANCE_NUMBER="${INSTANCE_NAME#app}"
if [[ ! "${INSTANCE_NUMBER}" =~ ^[0-9]+$ ]]; then
  echo "Unsupported instance name: ${INSTANCE_NAME}" >&2
  exit 3
fi

HTTP_PORT=$((8080 + ((INSTANCE_NUMBER - 1) * 100)))

echo "[INFO] Recovering ${INSTANCE_NAME}"
echo "[INFO] CATALINA_BASE=${CATALINA_BASE}"
echo "[INFO] CATALINA_HOME=${CATALINA_HOME}"
echo "[INFO] HTTP_PORT=${HTTP_PORT}"

run_as_user() {
  su - "${RUNTIME_USER}" -c "$1"
}

run_as_user "export CATALINA_BASE='${CATALINA_BASE}'; export CATALINA_HOME='${CATALINA_HOME}'; export JAVA_HOME='${JAVA_HOME}'; '${CATALINA_HOME}/bin/shutdown.sh' || true"

sleep 3

pgrep -af "Dcatalina.base=${CATALINA_BASE}" | awk '{print $1}' | xargs -r kill -9 || true

sleep 2

run_as_user "export CATALINA_BASE='${CATALINA_BASE}'; export CATALINA_HOME='${CATALINA_HOME}'; export JAVA_HOME='${JAVA_HOME}'; '${CATALINA_HOME}/bin/startup.sh'"

for _ in $(seq 1 "${TIMEOUT_SECONDS}"); do
  if curl -fsS --max-time 2 "http://127.0.0.1:${HTTP_PORT}${HEALTH_PATH}" >/dev/null; then
    echo "[INFO] Recovery succeeded for ${INSTANCE_NAME}"
    exit 0
  fi
  sleep 1
done

echo "[ERROR] Recovery health check failed for ${INSTANCE_NAME}" >&2
exit 4
