from concurrent.futures import ThreadPoolExecutor
from threading import Barrier

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import update
from sqlalchemy.exc import IntegrityError

from app.database import SessionLocal
from app.main import app
from app.models import Errand, User

from conftest import auth, create_errand


def test_only_one_runner_accepts_an_errand(client, users):
    errand_id = create_errand(client, users["requester"], "Race")["id"]
    barrier = Barrier(2)

    def accept(token: str) -> tuple[int, dict]:
        with TestClient(app) as worker:
            barrier.wait(timeout=10)
            response = worker.post(f"/errands/{errand_id}/accept", headers=auth(token))
            return response.status_code, response.json()

    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(accept, [users["runner"], users["runner2"]]))

    assert sorted(status for status, _ in results) == [200, 409]
    loser = next(body for status, body in results if status == 409)
    assert loser["code"] == "ERRAND_NOT_OPEN"

    db = SessionLocal()
    try:
        errand = db.get(Errand, errand_id)
        assert errand.status == "Accepted"
        assert errand.runner_id is not None
    finally:
        db.close()


def test_database_enforces_one_active_errand_per_runner(client, users):
    first = create_errand(client, users["requester"], "First")["id"]
    second = create_errand(client, users["requester"], "Second")["id"]
    with TestClient(app) as worker:
        assert worker.post(f"/errands/{first}/accept", headers=auth(users["runner"])).status_code == 200

    db = SessionLocal()
    try:
        runner = db.query(User).filter(User.email == "runner1@example.com").one()
        with pytest.raises(IntegrityError):
            db.execute(
                update(Errand)
                .where(Errand.id == second)
                .values(status="Accepted", runner_id=runner.id)
            )
            db.commit()
    finally:
        db.rollback()
        db.close()
