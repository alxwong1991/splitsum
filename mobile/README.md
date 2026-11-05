# SplitSum mobile

The starter counter screen now includes a **Check connection** card.
It calls `GET /health/ready` and validates that NestJS and PostgreSQL are ready.
This is a connectivity diagnostic, not the bill-entry workflow.

API access lives in [health_api.dart](./lib/api/health_api.dart), separate from
the [connection-check widget](./lib/widgets/connection_check.dart). The `http`
package provides portable networking and a mock client for tests.
Requests have an eight-second timeout, explicit errors, and manual retry.
No tokens, database credentials, or automatic polling are involved.

## Run locally

Start PostgreSQL from the repository root:

```bash
podman compose up -d postgres
```

Start NestJS from `backend/`:

```bash
npm run start:dev
```

From `mobile/`, configure the backend **origin** explicitly (no `/health` path):

```bash
flutter pub get
# iOS simulator:
flutter run --dart-define=API_BASE_URL=http://localhost:3000
# Android emulator:
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

For a physical device, use the Mac's LAN address and ensure it is reachable
on the same network. `localhost` on the device means the device itself.
Android allows cleartext HTTP only in debug builds. iOS permits local
networking without disabling transport security globally. Release builds
require an HTTPS API URL. Do not broaden these exceptions for production.

### Chrome

Browsers also require CORS. Start NestJS with the exact local Flutter origin,
from `backend/`:

```bash
CORS_ORIGIN=http://localhost:7357 npm run start:dev
```

Then from `mobile/`:

```bash
flutter run -d chrome --web-hostname=localhost --web-port=7357 \
  --dart-define=API_BASE_URL=http://localhost:3000
```

CORS is opt-in through the backend environment; no wildcard origin is enabled.
Restart Flutter after changing `--dart-define` values.

Tap **Check connection**:

- **Connected** means a live backend/PostgreSQL readiness request succeeded.
- **PostgreSQL unavailable** means the backend returned HTTP 503.
- **Cannot reach backend** means a network/browser-policy failure.
- Missing URL, timeout, unexpected HTTP status, and malformed responses have
  separate errors. Retry is disabled while a request is in progress.

If PostgreSQL is down before NestJS starts, the backend fails startup, so the
mobile app reports that it cannot reach the backend rather than a 503.

## Validation

```bash
flutter analyze
flutter test
```

Tests cover request URL/response validation, timeouts, network failures,
loading/success/error/retry states, disposal during a request, and the original
counter behavior. A passing mocked widget test alone is not proof that a
physical mobile device can reach your local backend.
