from pathlib import Path

from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles

from infrapilot.api.routes_dashboard import router as dashboard_router
from infrapilot.api.routes_execute import router as execute_router
from infrapilot.api.routes_health import router as health_router
from infrapilot.api.routes_history import router as history_router
from infrapilot.api.routes_intent import router as intent_router
from infrapilot.api.routes_latest import router as latest_router
from infrapilot.api.routes_plan import router as plan_router
from infrapilot.api.routes_recover import router as recover_router
from infrapilot.api.routes_recover_history import router as recover_history_router
from infrapilot.api.routes_recover_status import router as recover_status_router
from infrapilot.api.routes_status import router as status_router
from infrapilot.api.routes_validate import router as validate_router
from infrapilot.api.routes_verify import router as verify_router
from infrapilot.core.config import settings

app = FastAPI(
    title=settings.app_name,
    version="0.6.0",
    description="InfraPilot control plane with dashboard for deployment, scaling, verification, and recovery.",
)

app.include_router(health_router, tags=["health"])
app.include_router(intent_router, prefix="/intent", tags=["intent"])
app.include_router(validate_router, prefix="/spec", tags=["spec"])
app.include_router(plan_router, prefix="/deploy", tags=["deploy"])
app.include_router(execute_router, prefix="/deploy", tags=["deploy"])
app.include_router(status_router, prefix="/deploy", tags=["deploy"])
app.include_router(history_router, prefix="/deploy", tags=["deploy"])
app.include_router(latest_router, prefix="/deploy", tags=["deploy"])
app.include_router(verify_router, prefix="/deploy", tags=["deploy"])
app.include_router(recover_router, prefix="/deploy", tags=["deploy"])
app.include_router(recover_status_router, prefix="/deploy", tags=["deploy"])
app.include_router(recover_history_router, prefix="/deploy", tags=["deploy"])
app.include_router(dashboard_router, tags=["dashboard"])

STATIC_DIR = Path(__file__).resolve().parents[2] / "static"
app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")


@app.get("/", tags=["root"])
def root() -> dict[str, str]:
    return {
        "app": settings.app_name,
        "status": "ok",
        "docs": "/docs",
        "dashboard": "/dashboard",
    }