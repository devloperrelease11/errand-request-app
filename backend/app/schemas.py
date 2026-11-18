from datetime import datetime
from enum import Enum

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

MAX_PASSWORD_BYTES = 72


class Role(str, Enum):
    requester = "requester"
    runner = "runner"


class Status(str, Enum):
    Open = "Open"
    Accepted = "Accepted"
    InProgress = "In Progress"
    Completed = "Completed"
    Cancelled = "Cancelled"


def _trimmed_nonempty(value: str, field_name: str) -> str:
    cleaned = value.strip()
    if not cleaned:
        raise ValueError(f"{field_name} must not be blank")
    return cleaned


def _password_byte_limit(value: str) -> str:
    if len(value.encode("utf-8")) > MAX_PASSWORD_BYTES:
        raise ValueError("Password must be at most 72 bytes")
    return value


class RegisterRequest(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    email: EmailStr
    password: str = Field(min_length=8, max_length=72)
    role: Role

    @field_validator("name")
    @classmethod
    def clean_name(cls, value: str) -> str:
        return _trimmed_nonempty(value, "Name")

    @field_validator("password")
    @classmethod
    def check_password_bytes(cls, value: str) -> str:
        return _password_byte_limit(value)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=72)

    @field_validator("password")
    @classmethod
    def check_password_bytes(cls, value: str) -> str:
        return _password_byte_limit(value)


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    name: str
    email: str
    role: Role
    created_at: datetime


class ErrandCreate(BaseModel):
    title: str = Field(min_length=1, max_length=120)
    description: str = Field(min_length=1, max_length=2000)
    pickup_address: str = Field(min_length=1, max_length=500)
    dropoff_address: str = Field(min_length=1, max_length=500)

    @field_validator("title", "description", "pickup_address", "dropoff_address")
    @classmethod
    def clean_text(cls, value: str) -> str:
        return _trimmed_nonempty(value, "Field")


class ErrandOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    requester_id: str
    runner_id: str | None
    title: str
    description: str
    pickup_address: str
    dropoff_address: str
    status: Status
    created_at: datetime
    updated_at: datetime
    accepted_at: datetime | None
    completed_at: datetime | None


class MessageResponse(BaseModel):
    message: str
