from conftest import auth, create_errand


def detail(client, token, errand_id):
    return client.get(f"/errands/{errand_id}", headers=auth(token))


def action(client, token, errand_id, name):
    return client.post(f"/errands/{errand_id}/{name}", headers=auth(token))


def test_happy_path_lifecycle(client, users):
    errand = create_errand(client, users["requester"])
    errand_id = errand["id"]
    assert errand["status"] == "Open"
    assert errand["runner_id"] is None

    accepted = action(client, users["runner"], errand_id, "accept")
    assert accepted.status_code == 200, accepted.text
    assert accepted.json()["status"] == "Accepted"
    assert accepted.json()["runner_id"] is not None

    assert all(item["id"] != errand_id for item in client.get("/errands/open", headers=auth(users["runner"])).json())

    started = action(client, users["runner"], errand_id, "start")
    assert started.status_code == 200, started.text
    assert started.json()["status"] == "In Progress"

    completed = action(client, users["runner"], errand_id, "complete")
    assert completed.status_code == 200, completed.text
    assert completed.json()["status"] == "Completed"
    assert completed.json()["completed_at"] is not None

    assert detail(client, users["requester"], errand_id).json()["status"] == "Completed"


def test_lifecycle_cannot_skip_or_repeat(client, users):
    errand_id = create_errand(client, users["requester"])["id"]

    assert action(client, users["runner"], errand_id, "complete").status_code == 409
    assert action(client, users["runner"], errand_id, "start").status_code == 409
    assert action(client, users["requester"], errand_id, "cancel").json()["status"] == "Cancelled"

    assert action(client, users["runner"], errand_id, "accept").json()["code"] == "ERRAND_NOT_OPEN"
    assert action(client, users["requester"], errand_id, "cancel").status_code == 409

    errand_id = create_errand(client, users["requester"], "Second")["id"]
    action(client, users["runner"], errand_id, "accept")
    assert action(client, users["runner"], errand_id, "complete").status_code == 409
    action(client, users["runner"], errand_id, "start")
    assert action(client, users["runner"], errand_id, "accept").status_code == 409
    action(client, users["runner"], errand_id, "complete")
    for name in ("accept", "start", "complete", "cancel"):
        token = users["requester"] if name == "cancel" else users["runner"]
        assert action(client, token, errand_id, name).status_code == 409


def test_only_assigned_runner_can_progress(client, users):
    errand_id = create_errand(client, users["requester"])["id"]
    action(client, users["runner"], errand_id, "accept")
    for name in ("start", "complete"):
        response = action(client, users["runner2"], errand_id, name)
        assert response.status_code == 404
        assert response.json()["code"] == "NOT_FOUND"


def test_cancel_permissions_and_finality(client, users):
    errand_id = create_errand(client, users["requester"])["id"]
    assert action(client, users["runner"], errand_id, "cancel").status_code == 403
    assert action(client, users["requester2"], errand_id, "cancel").status_code == 404
    assert action(client, users["requester"], errand_id, "cancel").status_code == 200
    assert detail(client, users["requester"], errand_id).json()["status"] == "Cancelled"
