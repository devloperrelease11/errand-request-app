import pytest

from conftest import auth, login, register

PROTECTED = [
    ("GET", "/auth/me"),
    ("POST", "/auth/logout"),
    ("GET", "/errands/mine"),
    ("GET", "/errands/open"),
    ("GET", "/errands/assigned"),
    ("POST", "/errands"),
    ("GET", "/errands/some-id"),
    ("POST", "/errands/some-id/accept"),
    ("POST", "/errands/some-id/start"),
    ("POST", "/errands/some-id/complete"),
    ("POST", "/errands/some-id/cancel"),
]


def test_register_login_me_and_no_hash_leak(client):
    user = register(client, "Ada Lovelace", "Ada@Example.com", "requester")
    assert user["email"] == "ada@example.com"
    assert "password_hash" not in user
    assert set(user) == {"id", "name", "email", "role", "created_at"}

    token = login(client, "ADA@example.com")
    me = client.get("/auth/me", headers=auth(token))
    assert me.status_code == 200
    assert me.json()["id"] == user["id"]

    assert client.post("/auth/login", json={"email": "ada@example.com", "password": "wrong"}).status_code == 401


def test_duplicate_email_and_invalid_input(client):
    register(client, "Ada", "ada@example.com", "runner")
    duplicate = client.post(
        "/auth/register",
        json={"name": "Ada Two", "email": "ADA@example.com", "password": "Passw0rd!", "role": "runner"},
    )
    assert duplicate.status_code == 409
    assert duplicate.json()["code"] == "EMAIL_TAKEN"

    for payload in (
        {"name": "A", "email": "bad@example.com", "password": "LeakMe123!", "role": "admin"},
        {"name": "A", "email": "bad@example.com", "password": "short", "role": "runner"},
        {"name": "   ", "email": "bad@example.com", "password": "LeakMe123!", "role": "runner"},
        {"name": "A", "email": "not-an-email", "password": "LeakMe123!", "role": "runner"},
    ):
        response = client.post("/auth/register", json=payload)
        assert response.status_code == 422, response.text
        assert "LeakMe123!" not in str(response.json())


@pytest.mark.parametrize("method,path", PROTECTED)
def test_protected_endpoints_require_authentication(client, method, path):
    response = client.request(method, path, json={} if method == "POST" else None)
    assert response.status_code == 401


def test_invalid_and_revoked_tokens_are_rejected(client):
    response = client.get("/auth/me", headers=auth("not.a.jwt"))
    assert response.status_code == 401
    assert response.json()["code"] == "INVALID_TOKEN"

    register(client, "Ada", "ada@example.com", "requester")
    token = login(client, "ada@example.com")
    assert client.post("/auth/logout", headers=auth(token)).status_code == 200
    assert client.get("/auth/me", headers=auth(token)).status_code == 401
