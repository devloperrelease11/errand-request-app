from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import get_current_user, require_requester, require_runner
from ..errors import ApiError
from ..models import Errand, User
from ..schemas import ErrandCreate, ErrandOut
from ..services import errands as service

router = APIRouter(prefix="/errands", tags=["errands"])


@router.post("", response_model=ErrandOut, status_code=status.HTTP_201_CREATED)
def create_errand(
    payload: ErrandCreate,
    requester: User = Depends(require_requester),
    db: Session = Depends(get_db),
):
    errand = Errand(
        requester_id=requester.id,
        title=payload.title,
        description=payload.description,
        pickup_address=payload.pickup_address,
        dropoff_address=payload.dropoff_address,
        status="Open",
    )
    db.add(errand)
    db.commit()
    db.refresh(errand)
    return errand


@router.get("/mine", response_model=list[ErrandOut])
def my_errands(
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    requester: User = Depends(require_requester),
    db: Session = Depends(get_db),
):
    return service.list_requested(db, requester.id, limit, offset)


@router.get("/open", response_model=list[ErrandOut])
def open_errands(
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    runner: User = Depends(require_runner),
    db: Session = Depends(get_db),
):
    return service.list_open(db, limit, offset)


@router.get("/assigned", response_model=list[ErrandOut])
def assigned_errands(
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    runner: User = Depends(require_runner),
    db: Session = Depends(get_db),
):
    return service.list_assigned(db, runner.id, limit, offset)


@router.get("/{errand_id}", response_model=ErrandOut)
def get_errand(
    errand_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    errand = db.get(Errand, errand_id)
    if errand is None or not service.visible_to(user, errand):
        raise ApiError(404, "NOT_FOUND", "Errand not found")
    return errand


@router.post("/{errand_id}/accept", response_model=ErrandOut)
def accept_errand(
    errand_id: str,
    runner: User = Depends(require_runner),
    db: Session = Depends(get_db),
):
    return service.accept(db, runner, errand_id)


@router.post("/{errand_id}/start", response_model=ErrandOut)
def start_errand(
    errand_id: str,
    runner: User = Depends(require_runner),
    db: Session = Depends(get_db),
):
    return service.transition(db, runner, errand_id, "Accepted", "In Progress")


@router.post("/{errand_id}/complete", response_model=ErrandOut)
def complete_errand(
    errand_id: str,
    runner: User = Depends(require_runner),
    db: Session = Depends(get_db),
):
    return service.transition(db, runner, errand_id, "In Progress", "Completed")


@router.post("/{errand_id}/cancel", response_model=ErrandOut)
def cancel_errand(
    errand_id: str,
    requester: User = Depends(require_requester),
    db: Session = Depends(get_db),
):
    return service.cancel(db, requester, errand_id)
