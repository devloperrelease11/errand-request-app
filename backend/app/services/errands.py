from sqlalchemy import update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..errors import ApiError
from ..models import Errand, User, utcnow


def visible_to(user: User, errand: Errand) -> bool:
    if user.role == "requester":
        return errand.requester_id == user.id
    return errand.status == "Open" or errand.runner_id == user.id


def list_open(db: Session, limit: int, offset: int) -> list[Errand]:
    return (
        db.query(Errand)
        .filter(Errand.status == "Open")
        .order_by(Errand.created_at.desc(), Errand.id.desc())
        .limit(limit)
        .offset(offset)
        .all()
    )


def list_requested(db: Session, requester_id: str, limit: int, offset: int) -> list[Errand]:
    return (
        db.query(Errand)
        .filter(Errand.requester_id == requester_id)
        .order_by(Errand.created_at.desc(), Errand.id.desc())
        .limit(limit)
        .offset(offset)
        .all()
    )


def list_assigned(db: Session, runner_id: str, limit: int, offset: int) -> list[Errand]:
    return (
        db.query(Errand)
        .filter(Errand.runner_id == runner_id)
        .order_by(Errand.created_at.desc(), Errand.id.desc())
        .limit(limit)
        .offset(offset)
        .all()
    )


def _not_found_or_busy(db: Session, errand_id: str, code: str) -> ApiError:
    errand = db.get(Errand, errand_id)
    if errand is None:
        return ApiError(404, "NOT_FOUND", "Errand not found")
    return ApiError(
        409,
        code,
        "This errand is no longer open; another runner may have accepted it.",
    )


def accept(db: Session, runner: User, errand_id: str) -> Errand:
    now = utcnow()
    try:
        result = db.execute(
            update(Errand)
            .where(Errand.id == errand_id, Errand.status == "Open")
            .values(status="Accepted", runner_id=runner.id, accepted_at=now, updated_at=now)
        )
        if result.rowcount != 1:
            raise _not_found_or_busy(db, errand_id, "ERRAND_NOT_OPEN")
        db.commit()
    except IntegrityError:
        db.rollback()
        raise ApiError(
            409,
            "RUNNER_ACTIVE_ERRAND",
            "You already have an active errand. Finish it before accepting another.",
        ) from None
    errand = db.get(Errand, errand_id)
    db.refresh(errand)
    return errand


def transition(
    db: Session,
    runner: User,
    errand_id: str,
    expected_status: str,
    next_status: str,
) -> Errand:
    values = {"status": next_status, "updated_at": utcnow()}
    if next_status == "Completed":
        values["completed_at"] = utcnow()

    result = db.execute(
        update(Errand)
        .where(
            Errand.id == errand_id,
            Errand.runner_id == runner.id,
            Errand.status == expected_status,
        )
        .values(**values)
    )
    if result.rowcount != 1:
        errand = db.get(Errand, errand_id)
        if errand is None or (errand.runner_id is not None and errand.runner_id != runner.id):
            raise ApiError(404, "NOT_FOUND", "Errand not found")
        raise ApiError(
            409,
            "INVALID_TRANSITION",
            f"Errand is '{errand.status}', but this action requires '{expected_status}'.",
        )
    db.commit()
    errand = db.get(Errand, errand_id)
    db.refresh(errand)
    return errand


def cancel(db: Session, requester: User, errand_id: str) -> Errand:
    result = db.execute(
        update(Errand)
        .where(
            Errand.id == errand_id,
            Errand.requester_id == requester.id,
            Errand.status == "Open",
        )
        .values(status="Cancelled", updated_at=utcnow())
    )
    if result.rowcount != 1:
        errand = db.get(Errand, errand_id)
        if errand is None or errand.requester_id != requester.id:
            raise ApiError(404, "NOT_FOUND", "Errand not found")
        raise ApiError(
            409,
            "INVALID_TRANSITION",
            f"Only an Open errand can be cancelled; this one is '{errand.status}'.",
        )
    db.commit()
    errand = db.get(Errand, errand_id)
    db.refresh(errand)
    return errand
