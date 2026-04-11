#!/usr/bin/env bash
set -euo pipefail

API_BASE="${API_BASE:-http://10.211.55.38:8000}"
RUNS_PER_TESTCASE="${RUNS_PER_TESTCASE:-3}"
OUT_BASE="${OUT_BASE:-./testcase_results}"

mkdir -p "$OUT_BASE"
OUT_BASE="$(cd "$OUT_BASE" && pwd)"
RESULTS_CSV="${OUT_BASE}/results.csv"

echo "Checking API health at ${API_BASE}..."
curl -sS "${API_BASE}/health" > "${OUT_BASE}/api_health.json"
python3 - <<PY
import json
with open("${OUT_BASE}/api_health.json", "r", encoding="utf-8") as f:
    data = json.load(f)
print(data)
PY

for i in $(seq 1 "$RUNS_PER_TESTCASE"); do
  RUN_ID="run$(date +%Y%m%d-%H%M%S)-${i}"
  RUN_ID="$RUN_ID" RESULTS_CSV="$RESULTS_CSV" OUT_BASE="$OUT_BASE" ./tc01_scenario_base_deploy_1.sh

  RUN_ID="run$(date +%Y%m%d-%H%M%S)-${i}"
  RUN_ID="$RUN_ID" RESULTS_CSV="$RESULTS_CSV" OUT_BASE="$OUT_BASE" ./tc02_scenario_scale_up_5.sh

  RUN_ID="run$(date +%Y%m%d-%H%M%S)-${i}"
  RUN_ID="$RUN_ID" RESULTS_CSV="$RESULTS_CSV" OUT_BASE="$OUT_BASE" ./tc03_scenario_scale_down_1.sh

  RUN_ID="run$(date +%Y%m%d-%H%M%S)-${i}"
  RUN_ID="$RUN_ID" RESULTS_CSV="$RESULTS_CSV" OUT_BASE="$OUT_BASE" ./tc04_scenario_kill_and_recover_app3.sh
done

echo "All test cases completed."
echo "Results CSV: ${RESULTS_CSV}"