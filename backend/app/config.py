from __future__ import annotations
from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://postgres:dev_password_sih2026@localhost:5432/sainik_saathi"

    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"

    # JWT
    JWT_SECRET_KEY: str = "CHANGE_ME_in_production"
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRY_MINUTES: int = 60
    JWT_REFRESH_EXPIRY_DAYS: int = 30

    # Encryption (AES-256 master key — 32 hex bytes = 64 hex chars)
    ENCRYPTION_MASTER_KEY: str = "CHANGE_ME_32_bytes_hex"

    # CORS
    CORS_ORIGINS: str = "http://localhost:3000,http://localhost:8080,http://localhost:19006"

    # App
    APP_ENV: str = "development"
    DEBUG: bool = True

    @property
    def cors_origins_list(self) -> list[str]:
        return [o.strip() for o in self.CORS_ORIGINS.split(",")]


@lru_cache
def get_settings() -> Settings:
    return Settings()
