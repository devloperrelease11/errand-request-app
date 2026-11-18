from fastapi import Depends
from fastapi.security import HTTPBearer
from jwt import PyJWTError
from sqlalchemy.orm import Session

from .config import settings
from .database import get_db
from .errors import ApiError
from .models import RevokedToken, User
from .security import decode_access_token

bearer_scheme = HTTPBearer(auto_error=False)


def get_current_user(
    credentials=Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> User:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise ApiError(401, "UNAUTHORIZED", "Authentication required")

    try:
        payload = decode_access_token(credentials.credentials)
    except PyJWTError:
        raise ApiError(401, "INVALID_TOKEN", "Invalid or expired token") from None

    jti = payload.get("jti")
    if not jti or db.get(RevokedToken, jti) is not None:
        raise ApiError(401, "INVALID_TOKEN", "This session has ended")

    user = db.get(User, payload.get("sub"))
    if user is None:
        raise ApiError(401, "INVALID_TOKEN", "Account no longer exists")
    return user


def require_requester(user: User = Depends(get_current_user)) -> User:
    if user.role != "requester":
        raise ApiError(403, "FORBIDDEN", "Requester role required")
    return user


def require_runner(user: User = Depends(get_current_user)) -> User:
    if user.role != "runner":
        raise ApiError(403, "FORBIDDEN", "Runner role required")
    return user
