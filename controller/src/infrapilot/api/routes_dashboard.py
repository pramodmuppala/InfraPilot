from pathlib import Path

from fastapi import APIRouter
from fastapi.responses import FileResponse

router = APIRouter()


def _static_dir() -> Path:
    # controller/src/infrapilot/api/routes_dashboard.py
    # -> controller/static
    return Path(__file__).resolve().parents[3] / "static"


@router.get("/dashboard", include_in_schema=False)
def dashboard() -> FileResponse:
    static_dir = _static_dir()
    return FileResponse(static_dir / "index.html")