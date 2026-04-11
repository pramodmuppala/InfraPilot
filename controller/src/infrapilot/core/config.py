from functools import lru_cache
from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


def _default_ansible_root() -> str:
    # .../InfraPilot/controller/src/infrapilot/core/config.py -> InfraPilot
    return str(Path(__file__).resolve().parents[4])


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    app_name: str = Field(default="InfraPilot Control Plane", alias="APP_NAME")
    environment: str = Field(default="dev", alias="ENVIRONMENT")
    log_level: str = Field(default="INFO", alias="LOG_LEVEL")
    ansible_package_root: str = Field(default_factory=_default_ansible_root, alias="ANSIBLE_PACKAGE_ROOT")
    allow_execution: bool = Field(default=False, alias="ALLOW_EXECUTION")
    default_health_path: str = Field(default="/", alias="DEFAULT_HEALTH_PATH")
    default_port: int = Field(default=8080, alias="DEFAULT_PORT")


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
