import csv
import sys
from collections import defaultdict
from pathlib import Path

import matplotlib.pyplot as plt

if len(sys.argv) < 3:
    print("Usage: python3 generate_plots.py <results.csv> <output_dir>")
    sys.exit(1)

csv_path = Path(sys.argv[1])
output_dir = Path(sys.argv[2])
output_dir.mkdir(parents=True, exist_ok=True)

rows = list(csv.DictReader(csv_path.open()))
durations = defaultdict(list)
successes = defaultdict(lambda: {"success": 0, "total": 0})

for row in rows:
    scenario = row["scenario"]
    try:
        durations[scenario].append(float(row["duration_seconds"]))
    except Exception:
        pass
    successes[scenario]["total"] += 1
    if row["status"].lower() == "success":
        successes[scenario]["success"] += 1

scenarios = list(durations.keys())
avg_durations = [sum(durations[s]) / len(durations[s]) for s in scenarios]

plt.figure(figsize=(10, 6))
plt.bar(scenarios, avg_durations)
plt.ylabel("Average duration (seconds)")
plt.title("InfraPilot experiment average duration by scenario")
plt.xticks(rotation=20, ha="right")
plt.tight_layout()
plt.savefig(output_dir / "avg_duration_by_scenario.png")
plt.close()

scenarios2 = list(successes.keys())
success_rates = [
    (successes[s]["success"] / successes[s]["total"] * 100) if successes[s]["total"] else 0
    for s in scenarios2
]

plt.figure(figsize=(10, 6))
plt.bar(scenarios2, success_rates)
plt.ylabel("Success rate (%)")
plt.title("InfraPilot experiment success rate by scenario")
plt.xticks(rotation=20, ha="right")
plt.tight_layout()
plt.savefig(output_dir / "success_rate_by_scenario.png")
plt.close()

print(f"Saved plots to {output_dir}")
