from functools import lru_cache
from pathlib import Path

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

BASE_DIR = Path(__file__).resolve().parents[1]
ROOT_DIR = BASE_DIR.parent


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=(ROOT_DIR / ".env", BASE_DIR / ".env"),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    environment: str = Field(default="development", pattern="^(development|production)$")
    database_url: str = "sqlite:///./erand.db"
    jwt_secret: str = Field(min_length=16)
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = Field(default=60, ge=1, le=10080)
    cors_origins: str = "http://localhost:3000,http://localhost:8080"

    @field_validator("jwt_secret")
    @classmethod
    def reject_placeholder_secret(cls, value: str) -> str:
        if "change-me" in value.lower() or "change_me" in value.lower():
            raise ValueError("Replace the placeholder JWT_SECRET with a random value")
        return value

    @property
    def cors_origin_list(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]

    @property
    def cors_origin_regex(self) -> str | None:
        if self.environment == "development":
            return r"http://(localhost|127\.0\.0\.1)(:\d+)?"
        return None


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
