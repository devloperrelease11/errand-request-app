# Errand Request App

Full-stack implementation of the technical assessment in `requirements.txt`.

- **Client:** Flutter (Dart), mobile only (Android/iOS), `Provider` + `ChangeNotifier` state management.
- **Backend:** FastAPI (Python), SQLAlchemy ORM, SQLite database.
- **Auth:** bcrypt password hashing, signed JWT with expiry, server-side token revocation on logout.

## Repository layout

```
.
├── requirements.txt              assessment brief (not the Python dependency file)
├── .env.example                  every required environment variable, no real values
├── backend/
│   ├── requirements.txt          Python dependencies
│   ├── app/
│   │   ├── main.py               FastAPI app, middleware, routers, error handlers
│   │   ├── config.py             environment-driven settings
│   │   ├── database.py           engine, sessions, SQLite pragmas
│   │   ├── models.py             User, Errand, RevokedToken tables + DB constraints
│   │   ├── schemas.py            request/response validation
│   │   ├── security.py           password hashing and JWT helpers
│   │   ├── deps.py               authentication and role guards
│   │   ├── errors.py             consistent API error responses
│   │   ├── seed.py               sample accounts and errands
│   │   ├── routers/              auth and errands endpoints
│   │   └── services/errands.py   lifecycle and business rules
│   └── tests/                    automated backend tests
└── client/
    ├── config.example.json       template for the API base URL
    ├── lib/                      Flutter application source
    ├── android/, ios/            mobile platform projects
    └── test/                     model tests
```

## Prerequisites

- Python 3.11+ (developed and tested on Python 3.14)
- Flutter current stable SDK (developed with Flutter 3.50.0 / Dart 3.14.0)
- Android SDK + emulator or an iOS simulator for running the mobile client
- No database server is required: SQLite is file-based

## Backend setup

Run these from the repository root:

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1          # macOS/Linux: source .venv/bin/activate
pip install -r requirements.txt
Copy-Item ..\.env.example ..\.env      # then edit JWT_SECRET (required)
python -m app.seed
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

The API is available at `http://localhost:8000`, with interactive docs at `/docs`.
Tables are created automatically on startup; `python -m app.seed` only inserts sample data and is safe to re-run.

Environment variables are read from the repository-root `.env` or `backend/.env`.

### Backend tests

```powershell
cd backend
python -m pytest -q
```

Tests use a temporary SQLite file, so they never touch the development database. Coverage includes
authentication, validation, authorization, visibility, the full lifecycle, invalid transitions,
the one-active-errand rule, logout revocation, and two runners racing to accept the same errand.

## Client setup

```powershell
cd client
flutter pub get
Copy-Item config.example.json config.json    # edit API_BASE_URL for your device
flutter run --dart-define-from-file=config.json
```

`config.json` is gitignored, so no API URL or secret is committed. Common values:

| Target | `API_BASE_URL` |
| --- | --- |
| Android emulator | `http://10.0.2.2:8000` |
| iOS simulator | `http://localhost:8000` |
| Physical device on the same Wi-Fi | `http://<your-computer-lan-ip>:8000` |

The generated Android and iOS projects allow cleartext HTTP for local development. For production,
serve the API over HTTPS and remove those exceptions (`android:usesCleartextTraffic` in
`AndroidManifest.xml` and `NSAppTransportSecurity` in `Info.plist`).

Client tests: `flutter test`. Static analysis: `flutter analyze`.

For a quick preview without an Android build, a local-only web target is available:
set `config.json` to `http://localhost:8000`, ensure `.env` includes `http://localhost:5000` in
`CORS_ORIGINS`, then run `flutter run -d chrome --web-port 5000 --dart-define-from-file=config.json`.
The `client/web/` folder is gitignored; the submitted client remains mobile-only.

## Environment variables

All variables are listed in `.env.example` without real values.

| Variable | Required | Default | Purpose |
| --- | --- | --- | --- |
| `ENVIRONMENT` | No | `development` | `development` or `production` |
| `DATABASE_URL` | No | `sqlite:///./erand.db` | SQLAlchemy database URL; run the backend from `backend/` when using the relative default |
| `JWT_SECRET` | Yes | – | Signing secret; generate with `python -c "import secrets; print(secrets.token_hex(32))"` |
| `JWT_ALGORITHM` | No | `HS256` | JWT signing algorithm |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | No | `60` | Token lifetime |
| `CORS_ORIGINS` | No | local dev origins | Comma-separated browser origins |
| `API_BASE_URL` | Yes (client) | – | Passed to Flutter through `config.json` and `--dart-define-from-file` |

## Sample data

`python -m app.seed` creates these accounts. All use password `Demo1234!`.

| Role | Email | Notes |
| --- | --- | --- |
| Requester | `requester@example.com` | Owns open, accepted, completed and cancelled errands |
| Runner | `runner@example.com` | Already holds one active errand, so accept the completed flow or sign in as runner2 |
| Runner | `runner2@example.com` | No active errand; use this one to accept an open errand |
| Requester | `requester2@example.com` | Owns one open errand; useful for checking access isolation |

The seed data is idempotent: users are matched by deterministic IDs and sample errands are only
inserted once.

## API summary

All endpoints except `POST /auth/register` and `POST /auth/login` require
`Authorization: Bearer <token>`.

| Method | Path | Role | Description |
| --- | --- | --- | --- |
| POST | `/auth/register` | public | Register with name, email, password, role |
| POST | `/auth/login` | public | Obtain an expiring bearer token |
| GET | `/auth/me` | any | Current user profile |
| POST | `/auth/logout` | any | Revoke the current token |
| POST | `/errands` | requester | Create an errand |
| GET | `/errands/mine` | requester | Own errands, newest first |
| GET | `/errands/open` | runner | Open errands, newest first |
| GET | `/errands/assigned` | runner | Errands assigned to the runner |
| GET | `/errands/{id}` | any | Errand details, if visible to the caller |
| POST | `/errands/{id}/accept` | runner | `Open` → `Accepted` |
| POST | `/errands/{id}/start` | assigned runner | `Accepted` → `In Progress` |
| POST | `/errands/{id}/complete` | assigned runner | `In Progress` → `Completed` |
| POST | `/errands/{id}/cancel` | owning requester | `Open` → `Cancelled` |

List endpoints accept `limit` (1–100, default 50) and `offset` (default 0). Errors use
`{"detail": "...", "code": "..."}`; validation errors add an `errors` array with field names only,
never submitted values.

## Architecture and key design decisions

- **FastAPI** gives automatic OpenAPI docs, Pydantic validation at the boundary, and dependency
  injection for database sessions and role checks. Validation and authorization live on the server;
  the Flutter app's checks are only for user experience.
- **SQLite** is persistent, zero-configuration, and supports WAL plus `PRAGMA busy_timeout`. The
  rules that must hold under concurrency are enforced by the database: a conditional
  `UPDATE ... WHERE status = 'Open'` makes acceptance atomic, and a partial unique index on
  `runner_id` for `Accepted`/`In Progress` prevents a runner holding two active errands. Application
  code maps row counts and integrity errors to clear `409` responses.
- **Provider + ChangeNotifier** was chosen for the client because it needs no code generation, keeps
  authentication and errand lists in two small stores, and is easy to reason about.
- **Session persistence:** the JWT is stored in `flutter_secure_storage`; on startup the client
  restores it and calls `/auth/me`. Logout revokes the token's `jti` server-side as well as clearing
  local storage.
- **Visibility:** inaccessible errands return `404` rather than `403` so callers cannot enumerate
  other users' errands. Requesters only see their own; runners see open errands and their assignments.
- **Fresh status:** every list supports pull-to-refresh, the app bar has a refresh action, and
  detail actions refresh the affected lists immediately.

### Business rule enforcement

| Rule | Server enforcement |
| --- | --- |
| Exactly one runner accepts | Conditional atomic `UPDATE`; losing runner gets `409 ERRAND_NOT_OPEN` |
| One active errand per runner | Partial unique index + `409 RUNNER_ACTIVE_ERRAND` |
| No skipped/backwards transitions | Every transition filters on the exact current status; completed/cancelled have no outgoing transition |
| Ownership and visibility | Role dependencies plus explicit owner/assignee filters in queries and updates |
| Role restrictions | `require_requester` / `require_runner` dependencies on every mutating endpoint |
| Input validation | Pydantic schemas for all request bodies, query constraints for pagination |
| Password safety | bcrypt hashes; password hashes never appear in response schemas |
| Authentication | Signed JWT with `sub`, `jti`, `iat`, `exp`; revoked tokens are checked on every request |

## Assumptions

- A user's role is fixed at registration; the brief specifies exactly one role per account.
- Pickup and drop-off addresses are plain text; no maps or geocoding are used.
- "Active" means `Accepted` or `In Progress`.
- A runner may view an open errand's details before accepting it.
- Logout means the current token stops working; other devices signed in with the same account
  have their own tokens.
- The client targets mobile only, as required; no web or desktop targets are configured.

## Known limitations

- SQLite has a single writer. WAL and busy timeouts make the assessed concurrency safe, but a
  high-traffic deployment should use PostgreSQL. Moving to PostgreSQL also requires replacing the
  SQLite-specific partial index definition in `models.py` with an equivalent PostgreSQL index.
- Status updates rely on pull-to-refresh and explicit refresh actions; there is no polling or push.
- Expired revoked tokens are deleted opportunistically when a user logs out; a production system
  would run a scheduled cleanup job.
- There is no password reset, refresh-token rotation, or email verification.
- Cleartext HTTP is enabled in the mobile platform configuration for local development only.
