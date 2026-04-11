from __future__ import annotations

import json
from pathlib import Path
from typing import Any


def _store_dir() -> Path:
    path = Path(__file__).resolve().parents[3] / "runtime" / "executions"
    path.mkdir(parents=True, exist_ok=True)
    return path


def _record_path(deployment_id: str) -> Path:
    return _store_dir() / f"{deployment_id}.json"


def _to_dict(record: Any) -> dict[str, Any]:
    if isinstance(record, dict):
        return record
    if hasattr(record, "model_dump"):
        return record.model_dump()
    if hasattr(record, "dict"):
        return record.dict()
    raise TypeError(f"Unsupported record type for execution store: {type(record)!r}")


def save_execution(record: Any) -> Path:
    record_dict = _to_dict(record)
    deployment_id = record_dict["deployment_id"]
    path = _record_path(deployment_id)
    path.write_text(json.dumps(record_dict, indent=2, default=str), encoding="utf-8")
    return path


def load_execution(deployment_id: str) -> dict[str, Any] | None:
    path = _record_path(deployment_id)
    if not path.exists():
        return None
    return json.loads(path.read_text(encoding="utf-8"))


def get_execution(deployment_id: str) -> dict[str, Any] | None:
    return load_execution(deployment_id)


def list_execution_records(limit: int | None = None) -> list[dict[str, Any]]:
    files = sorted(
        _store_dir().glob("*.json"),
        key=lambda p: p.stat().st_mtime,
        reverse=True,
    )

    records: list[dict[str, Any]] = []
    for path in files:
        try:
            records.append(json.loads(path.read_text(encoding="utf-8")))
        except Exception:
            continue

    if limit is not None:
        return records[:limit]
    return records


def list_executions(limit: int | None = None) -> list[dict[str, Any]]:
    return list_execution_records(limit=limit)