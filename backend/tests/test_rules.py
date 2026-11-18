from conftest import auth, create_errand


def action(client, token, errand_id, name):
    return client.post(f"/errands/{errand_id}/{name}", headers=auth(token))


def test_role_restrictions(client, users):
    errand_id = create_errand(client, users["requester"])["id"]

    response = client.post(
        "/errands",
        headers=auth(users["runner"]),
        json={
            "title": "Nope",
            "description": "Nope",
            "pickup_address": "Nope",
            "dropoff_address": "Nope",
        },
    )
    assert response.status_code == 403

    assert action(client, users["requester"], errand_id, "accept").status_code == 403
    assert client.get("/errands/open", headers=auth(users["requester"])).status_code == 403
    assert client.get("/errands/mine", headers=auth(users["runner"])).status_code == 403
    assert client.get("/errands/assigned", headers=auth(users["requester"])).status_code == 403


def test_runner_can_hold_only_one_active_errand(client, users):
    first = create_errand(client, users["requester"], "First")["id"]
    second = create_errand(client, users["requester"], "Second")["id"]

    assert action(client, users["runner"], first, "accept").status_code == 200
    blocked = action(client, users["runner"], second, "accept")
    assert blocked.status_code == 409
    assert blocked.json()["code"] == "RUNNER_ACTIVE_ERRAND"

    action(client, users["runner"], first, "start")
    assert action(client, users["runner"], second, "accept").status_code == 409
    action(client, users["runner"], first, "complete")
    assert action(client, users["runner"], second, "accept").status_code == 200


def test_errand_visibility(client, users):
    first = create_errand(client, users["requester"], "First")["id"]
    second = create_errand(client, users["requester2"], "Second")["id"]

    assert client.get(f"/errands/{first}", headers=auth(users["requester"])).status_code == 200
    assert client.get(f"/errands/{first}", headers=auth(users["requester2"])).status_code == 404
    assert client.get(f"/errands/{second}", headers=auth(users["requester"])).status_code == 404
    assert client.get(f"/errands/{first}", headers=auth(users["runner"])).status_code == 200

    third = create_errand(client, users["requester"], "Third")["id"]
    assert action(client, users["runner2"], third, "accept").status_code == 200
    assert client.get(f"/errands/{third}", headers=auth(users["runner"])).status_code == 404
    assert client.get(f"/errands/{third}", headers=auth(users["runner2"])).status_code == 200
    assert client.get(f"/errands/{third}", headers=auth(users["requester"])).status_code == 200

    mine = client.get("/errands/mine", headers=auth(users["requester"])).json()
    assert {item["id"] for item in mine} == {first, third}
    assigned = client.get("/errands/assigned", headers=auth(users["runner2"])).json()
    assert [item["id"] for item in assigned] == [third]


def test_open_errands_are_newest_first_and_exclude_taken(client, users):
    ids = [
        create_errand(client, users["requester"], f"Errand {index}")["id"] for index in range(3)
    ]
    open_ids = [item["id"] for item in client.get("/errands/open", headers=auth(users["runner"])).json()]
    assert open_ids == list(reversed(ids))

    action(client, users["runner"], ids[1], "accept")
    open_ids = [item["id"] for item in client.get("/errands/open", headers=auth(users["runner"])).json()]
    assert open_ids == [ids[2], ids[0]]

    response = client.get("/errands/open?limit=1&offset=1", headers=auth(users["runner"]))
    assert [item["id"] for item in response.json()] == [ids[0]]


def test_create_errand_validation(client, users):
    for payload in (
        {"title": " ", "description": "x", "pickup_address": "x", "dropoff_address": "x"},
        {"title": "x", "description": "x", "pickup_address": "x", "dropoff_address": ""},
    ):
        response = client.post("/errands", headers=auth(users["requester"]), json=payload)
        assert response.status_code == 422
