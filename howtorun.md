# How to Run — Errand Request App

## What to install (clean machine)

1. Python 3.11 or newer (tested with Python 3.14).
2. Flutter current stable SDK (tested with Flutter 3.50.0 / Dart 3.14.0).
   Install it from the official Flutter install guide and add its `bin` folder to `PATH`.
   Run `flutter doctor` to verify (Android SDK / Xcode is needed only to launch a device).
3. No database server is needed. The app uses a local SQLite file.

> If `backend\.venv` already exists, skip the venv creation step below.
> Make sure `flutter` is on `PATH` (check with `flutter --version`).

## 1. Set up the backend

Open PowerShell in the repository root and run:

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

If PowerShell blocks activation, run:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

Create the environment file once, in the repository root:

```powershell
cd ..
Copy-Item .env.example .env
```

Then open `.env` and replace `JWT_SECRET` with a random value, for example generate one with:

```powershell
python -c "import secrets; print(secrets.token_hex(32))"
```

Do not use the `CHANGE_ME` placeholder. Never commit `.env`.

## 2. Seed sample data (optional but recommended)

From the repository root:

```powershell
cd backend
python -m app.seed
```

This creates the database file `backend\erand.db` and these accounts. All of them use password `Demo1234!`.

| Email | Role | Notes |
| --- | --- | --- |
| `requester@example.com` | Requester | Owns sample errands |
| `runner@example.com` | Runner | Already has one active errand |
| `runner2@example.com` | Runner | No active errand; use this to accept one |
| `requester2@example.com` | Requester | Owns one open errand |

## 3. Start the API

From the `backend` folder, with the virtual environment activated:

```powershell
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

- API: `http://localhost:8000`
- Docs: `http://localhost:8000/docs`

Keep this terminal open while using the app. Quick check: open `http://localhost:8000/docs` in a browser.
If you skipped seeding, the API still works; tables are created on startup.
Always start from the `backend` folder so the relative SQLite path in `.env` resolves correctly.

If activation fails, use the venv Python directly:

```powershell
.\.venv\Scripts\python.exe -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## 4. Set up the Flutter client

In a second terminal:

```powershell
cd client
flutter pub get
Copy-Item config.example.json config.json
```

Open `client\config.json` and set `API_BASE_URL` to the address of the machine running the API:

| Target | `API_BASE_URL` |
| --- | --- |
| Android emulator | `http://10.0.2.2:8000` |
| iOS simulator | `http://localhost:8000` |
| Physical device | `http://<computer-LAN-IP>:8000` |

Then start the app on a connected emulator/device:

```powershell
flutter run --dart-define-from-file=config.json
```

`config.json` is gitignored. If it is missing, the app shows a configuration message.
If the backend runs on another machine, use that machine's IP and make sure port 8000 is reachable.

## 4b. Preview on web (avoids the Android/Gradle build)

A local-only web target is included so you can preview in Chrome without installing the Android SDK.

1. Make sure the API is running and `config.json` contains `"API_BASE_URL": "http://localhost:8000"`.
2. `.env` must allow the web origin: `CORS_ORIGINS=http://localhost:5000,http://localhost:8080`
   (already set on this machine; restart uvicorn after changing it).
3. From `client\`, run:

```powershell
flutter run -d chrome --web-port 5000 --dart-define-from-file=config.json
```

Or build static files with `flutter build web --dart-define-from-file=config.json` and serve `client\build\web`.

The web target is only a preview convenience and is gitignored. The submitted client remains mobile-only.

## 5. Using the app

- Register as Requester or Runner, or sign in with a sample account above.
- Requester: **My errands** tab to view/cancel, **New** tab to post an errand.
- Runner: **Open** tab to browse/accept, **Accepted** tab to start and complete.
- Pull down on a list or tap the refresh icon in the app bar to get the latest status.
- Profile tab has **Sign out**. The session is restored on app restart.

## 6. Tests and checks

Backend tests (from `backend` folder, virtual environment activated):

```powershell
python -m pytest -q
```

Flutter checks (from `client` folder):

```powershell
flutter analyze
flutter test
```

## 7. Common problems

- **"JWT_SECRET" validation error on startup:** the placeholder is still in `.env`. Replace it.
- **401 in the app:** token expired or signed out; sign in again.
- **Client cannot reach API:** check `API_BASE_URL`, that uvicorn is running, and firewall settings.
- **Port 8000 busy:** start uvicorn with a different port and update `config.json` to match.
- **Database locked:** stop other backend processes using the same database file.
