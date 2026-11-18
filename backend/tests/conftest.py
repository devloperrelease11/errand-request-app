import os
import tempfile
from pathlib import Path

_TEST_DIR = tempfile.mkdtemp(prefix="erand-tests-")
os.environ["DATABASE_URL"] = f"sqlite:///{Path(_TEST_DIR) / 'test.db'}"
os.environ["JWT_SECRET"] = "test-only-secret-0123456789abcdef"
os.environ["ACCESS_TOKEN_EXPIRE_MINUTES"] = "60"
os.environ["ENVIRONMENT"] = "development"

import pytest
from fastapi.testclient import TestClient

from app.database import Base, engine
from app.main import app

PASSWORD = "Passw0rd!"


@pytest.fixture(autouse=True)
def fresh_db():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    yield


@pytest.fixture
def client():
    with TestClient(app) as test_client:
        yield test_client


def auth(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def register(client: TestClient, name: str, email: str, role: str, password: str = PASSWORD):
    response = client.post(
        "/auth/register",
        json={"name": name, "email": email, "password": password, "role": role},
    )
    assert response.status_code == 201, response.text
    return response.json()


def login(client: TestClient, email: str, password: str = PASSWORD) -> str:
    response = client.post("/auth/login", json={"email": email, "password": password})
    assert response.status_code == 200, response.text
    return response.json()["access_token"]


@pytest.fixture
def users(client):
    register(client, "Requester One", "one@example.com", "requester")
    register(client, "Requester Two", "two@example.com", "requester")
    register(client, "Runner One", "runner1@example.com", "runner")
    register(client, "Runner Two", "runner2@example.com", "runner")
    return {
        "requester": login(client, "one@example.com"),
        "requester2": login(client, "two@example.com"),
        "runner": login(client, "runner1@example.com"),
        "runner2": login(client, "runner2@example.com"),
    }


def create_errand(client: TestClient, token: str, title: str = "Groceries") -> dict:
    response = client.post(
        "/errands",
        headers=auth(token),
        json={
            "title": title,
            "description": "Please collect the parcel.",
            "pickup_address": "Pickup street 1",
            "dropoff_address": "Dropoff street 2",
        },
    )
    assert response.status_code == 201, response.text
    return response.json()
