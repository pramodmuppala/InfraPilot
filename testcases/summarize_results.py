import csv
import json
import statistics
import sys
from collections import defaultdict
from pathlib import Path

if len(sys.argv) < 2:
    print("Usage: python3 summarize_results.py <results.csv>")
    sys.exit(1)

csv_path = Path(sys.argv[1])
rows = list(csv.DictReader(csv_path.open()))

summary = {}
by_scenario = defaultdict(list)

for row in rows:
    by_scenario[row["scenario"]].append(row)

for scenario, scenario_rows in by_scenario.items():
    durations = []
    success_count = 0
    unhealthy_counts = []
    for row in scenario_rows:
        try:
            durations.append(float(row["duration_seconds"]))
        except Exception:
            pass
        if row["status"].lower() == "success":
            success_count += 1
        try:
            unhealthy_counts.append(int(row["unhealthy_count"]))
        except Exception:
            pass

    summary[scenario] = {
        "runs": len(scenario_rows),
        "success_rate": (success_count / len(scenario_rows)) if scenario_rows else 0.0,
        "avg_duration_seconds": statistics.mean(durations) if durations else None,
        "min_duration_seconds": min(durations) if durations else None,
        "max_duration_seconds": max(durations) if durations else None,
        "avg_unhealthy_count": statistics.mean(unhealthy_counts) if unhealthy_counts else None,
    }

out_path = csv_path.parent / "summary.json"
out_path.write_text(json.dumps(summary, indent=2), encoding="utf-8")
print(json.dumps(summary, indent=2))
print(f"Saved summary to {out_path}")
