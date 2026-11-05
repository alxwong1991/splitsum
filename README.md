# SplitSum

SplitSum is a Hong Kong-friendly mobile bill-splitting app being built with
Flutter, NestJS, and PostgreSQL. It is a personal product and portfolio project
focused on a small, complete, tested manual workflow before adding
AI-assisted receipt entry.

**Status: early development.** Mobile registration, login, and a private editable
display name connect to NestJS and PostgreSQL. Groups and bills remain
synthetic-data previews; the complete Stage 1 workflow is not available yet.

---

## Tech Stack

### Mobile

- Flutter / Dart
- Material UI
- Flutter widget tests and analyzer

### Backend

- NestJS 12 / TypeScript 6
- Prisma 7 with the PostgreSQL driver adapter
- npm
- Jest / Supertest
- oxlint / Prettier

### Database / Tools

- PostgreSQL 17
- Podman with a Compose provider
- Git

The architecture is one feature-organized NestJS backend, not microservices.
Flutter will communicate with REST APIs over HTTPS in production.
Authentication and account REST APIs are documented with OpenAPI.

---

## Current Progress

### Implemented

- NestJS and Flutter scaffolds running with their existing tooling.
- Isolated local PostgreSQL with a persistent volume.
- Prisma connection and initial `Account` migration.
- Database readiness endpoint for Postman or command-line checks.
- Integer-cent equal splitting with deterministic rounding.
- Backend unit tests and real database persistence/rollback tests.
- Backend email/password registration, login, and protected current-user API.
- OpenAPI documentation, default-deny authentication, and auth rate limits.
- Flutter registration/login, session restoration/expiry, and sign-out.
- Private account screen with an editable display name saved in PostgreSQL.
- Secure native token storage; browser previews keep tokens in memory only.

### Next: First Vertical Slice

1. Create an owner-managed group.
2. Add named participants, without requiring their registration.
3. Enter a bill with one payer and select its split participants.
4. Calculate equal shares in NestJS and save them atomically in PostgreSQL.
5. Display the saved bill and shares in Flutter.

Group/participant/bill APIs are not implemented yet.

After signing in, Flutter lands on your real private account. The explicit
**Explore demo groups** action opens sample groups, participants, bill entry,
and bill details. Demo screens do not persist financial records.
The UI uses Flutter's built-in Material 3 components; no third-party UI library
is needed for the current layouts.
Every screen's app bar has an **Appearance** menu with System, Light, and Dark.
System is the default. The selection is app-wide for the current session and
resets to System after restarting; it is not persisted yet.

---

## Product Roadmap

### Stage 1: Manual Workflow

- Authentication and owner-only access.
- Groups and named participants, including identifying yourself.
- HKD bills with one payer and equal splitting.
- Bill history and details.
- Outstanding direct debts and manually recorded settlements.
- Plain-text summaries through the device share sheet.
- Clear loading, empty, validation, and error states.

### Stage 2: AI Receipt Entry

Only after Stage 1 works end to end:

- Photograph or import one receipt.
- Extract suggested merchant, date, currency, and final total through the backend.
- Review and edit suggestions before saving a bill.
- Keep manual entry available when extraction fails.

Receipt extraction is **not implemented**. No accuracy claims are made.
AI must not create confirmed financial records without user review.

### Out of Scope Initially

Itemized/custom splits, multiple payers, collaborative accounts, invitations,
multi-currency conversion, budgeting, bank integrations, payment processing,
automatic FPS verification, and general AI chat.

SplitSum does not transfer money or verify payments.

---

## Financial Decisions

- **Integer HKD cents:** no floating-point money calculations.
- **Exact totals:** all shares sum to the bill total.
- **Stable rounding:** leftover cents go to selected participants by immutable
  group position, not checkbox order. HKD 100.00 among three participants is
  allocated as HKD 33.34, 33.33, and 33.33.
- **Independent payer:** the payer may be excluded from the split.
- **Direct debts:** each non-payer owes their share to the payer. Opposite debts
  are not automatically offset or rerouted between participants.
- **Derived balances:** future balances come from bills, shares, and settlements,
  not independently editable totals.
- **Manual settlements:** partial/full payments will reduce obligations;
  overpayments will be rejected.
- **Safe history:** once any settlement has been recorded in a group, bill
  editing/deletion will be blocked in that group.
- **Participant history:** referenced participants will be archived rather
  than deleted and cannot be selected for new bills while archived.

Only the split calculation is implemented at present. Persistence rules,
ownership enforcement, retry-safe writes, and settlement rules will be wired
into the product APIs incrementally.

### Proposed Data Model

`Account` supports backend authentication; the remaining entities are planned:

| Entity | Essential fields |
| --- | --- |
| Account | ID, unique normalized email, password hash, optional private display name |
| Group | ID, owner account ID, name, optional self-participant ID |
| Participant | ID, group ID, name, immutable position, archived flag |
| Bill | ID, group ID, payer participant ID, description, bill date, total cents, creation time |
| BillShare | Bill ID, participant ID, amount cents; unique bill/participant pair |
| IdempotencyRequest | Owner, operation, retry key, canonical request payload, resulting resource ID |

Every protected read/write must check ownership. Group-scoped participant
references must also be enforced by database constraints. A bill, its shares,
and its retry record must be saved in one transaction. Reusing a retry key with
different request contents must fail.

Bill totals range from 1 to 2,147,483,647 cents. Zero-cent shares are valid when
the total is smaller than the number of selected participants. Archiving does
not reorder participants, and removing a settlement must not implicitly unlock
historical bill editing.

---

## Project Structure

```text
splitsum/
  backend/
    prisma/             # Schema, migrations, test database initialization
    src/
      bills/            # Equal-split calculation and tests
      auth/             # Register/login controller, service, module, constants
        dto/            # Credential request and token response
        decorators/     # Public-route and current-user metadata
        guards/         # JWT authentication
      users/            # Current-user controller, service, module
        dto/            # Safe user response
      database/         # Prisma service and NestJS module
      health/           # Live PostgreSQL readiness check
    test/               # HTTP and PostgreSQL integration tests
  mobile/
    lib/
      main.dart         # App entry point
      core/theme/       # Central colors, inputs, cards, and button styles
      core/api/         # Shared HTTP client, configuration, and API errors
      core/auth/        # Secure native and ephemeral browser token stores
      shared/widgets/   # Page layout, headers, cards, notes, person rows
      features/
        auth/
          data/         # Authentication/account endpoints and response parsing
          models/       # Account and authentication response
          state/        # Session controller and inherited scope
          screens/      # Authentication gate and login/register
        account/screens/
        groups/screens/
        bills/
          screens/
          widgets/      # Bill-specific fields and summary card
      prototype/        # Synthetic in-memory demo data only
    test/               # Flutter widget tests
    android/
    ios/
    web/
  compose.yaml          # Local PostgreSQL only
```

### Backend Folder Convention

Organize code by feature. Keep each feature's controller, service, module,
and small constants at its root. Group DTOs, decorators, and guards in named
subfolders when those roles are present; use one DTO class per file.
Keep unit tests beside the implementation they test, with HTTP/database
integration tests in `backend/test/`.

Do not introduce one-file `controllers/`, `services/`, or `modules/` folders
in every feature. Small features such as health and database can remain flat.
Only put genuinely cross-feature utilities in a shared folder; authentication
decorators stay owned by auth even when other features import them.
Follow this pattern as groups, bills, and settlements are added.

### Maintaining Flutter Layouts

Edit a screen in `mobile/lib/features/` to change its layout or interactions.
Edit `mobile/lib/shared/widgets/` for components reused across features, and
`mobile/lib/core/theme/app_theme.dart` for app-wide visual styles. Widgets that
are specific to bills stay in that feature's `widgets/` folder rather than
making the shared folder a catch-all.

Each screen owns its small local UI state and navigation. Demo data remains
explicitly separate from future API models. There is no global state-management
or routing package yet; standard Flutter widgets and `Navigator` cover the
prototype without adding dependencies. Future API/state integration can be
introduced within each feature when the real manual workflow is implemented.

### Flutter API Convention

Keep shared HTTP transport in `mobile/lib/core/api/`: backend origin validation,
HTTPS enforcement in release builds, JSON encoding/decoding, bearer headers,
timeouts, and common HTTP errors. Feature `data/` files use the shared `ApiClient`
and own endpoint paths, typed response parsing, and feature-specific messages.
Models belong in the feature's `models/` folder; state coordinates API calls,
loading, and errors without putting networking into screen widgets.
Do not add a separate top-level `lib/api/` folder or empty feature layers.

---

## Prerequisites

- Git
- Node.js 24.11+ LTS recommended (development also verified with Node.js 26)
- npm
- Flutter stable with Dart 3.13.7 or compatible with the mobile SDK constraint
- Platform tooling for your Flutter target, such as Xcode or Android SDK
- Podman and a working Compose provider

Check your tools:

```bash
node --version
npm --version
flutter --version
podman --version
podman compose version
```

### macOS Terminal Setup

If Node.js is installed through **fnm**, initialize it in `~/.zshrc` so new
Terminal and VS Code terminal sessions can find `node` and `npm`:

```zsh
# Add once to ~/.zshrc, after any Homebrew PATH setup:
eval "$(fnm env --use-on-cd --shell zsh)"
```

Reload the configuration and select your installed default Node version:

```zsh
source ~/.zshrc
fnm list
fnm use default
node --version
npm --version
```

If no default is configured, use `fnm default <installed-version>` to choose
one from `fnm list`. If `fnm` itself cannot be found, check your Homebrew/PATH
setup first. Do not reinstall Node just because a new shell cannot find it.
Users of other Node managers should use that manager's shell initialization
instead; do not initialize multiple managers together.

Ensure your Flutter SDK's `bin` directory is also on your shell PATH, then run:

```bash
flutter doctor -v
xcode-select -p
xcodebuild -version
```

For iOS, install the full Xcode application, open it to finish first-launch
setup, and install an iOS simulator runtime when prompted. Follow Flutter
Doctor's guidance for any missing iOS tooling, including CocoaPods if required.
If `xcode-select -p` points only to Command Line Tools, select your installed
Xcode under **Xcode > Settings > Locations > Command Line Tools**.

On macOS, Podman needs its Linux virtual machine:

```bash
podman machine list
# Only if no machine exists:
podman machine init
# Only if the existing machine is stopped:
podman machine start
```

---

## Local Setup Guide

### 1. Clone the Repository

```bash
git clone https://github.com/alxwong1991/splitsum.git
cd splitsum
```

### 2. Configure Local Credentials

On a fresh checkout, copy these templates to the corresponding local names:

| Template | Local file |
| --- | --- |
| [.env.example](./.env.example) | `.env` |
| [backend/.env.example](./backend/.env.example) | `backend/.env` |
| [backend/.env.test.example](./backend/.env.test.example) | `backend/.env.test` |

Do not overwrite existing environment files. Generate a random local password,
for example with `openssl rand -hex 32`, and set it in:

- Root `.env`: `POSTGRES_PASSWORD`.
- Both backend files: the password portion of `DATABASE_URL`.

Generate a separate random signing key for each backend environment using
`openssl rand -hex 32`; set `JWT_SECRET` in `backend/.env` and
`backend/.env.test`. Use different keys for development, tests, and production.
Never copy the signing key into Flutter or Postman. Local keys were generated
during development; preserve existing environment files instead of overwriting.

The development URL uses `127.0.0.1:5433/splitsum`; the test URL uses
`127.0.0.1:5433/splitsum_test`. The templates show the complete URL format.
Keep all working credentials private. Environment files are Git-ignored.

### 3. Start PostgreSQL

From the repository root:

```bash
podman compose up -d postgres
podman compose ps
podman compose exec -T postgres pg_isready -U splitsum -d splitsum
```

| Setting | Value |
| --- | --- |
| Host | `127.0.0.1` |
| Published port | `5433` |
| Development database | `splitsum` |
| Test database | `splitsum_test` |
| Database user | `splitsum` |
| Persistent volume | `splitsum_postgres_data` |

The databases share one local PostgreSQL container. Port 5433 avoids conflicting
with HireFlow on port 5432; SplitSum commands do not modify HireFlow containers.

Database initialization runs only for a new volume. Changing an environment
file alone does not change an existing database's password.
**Do not run `podman compose down -v` unless you intend to delete local data.**

### 4. Run the Backend

```bash
cd backend
npm install
npm run db:deploy
npm run db:test:deploy
npm run start:dev
```

The backend runs at `http://localhost:3000` by default.
It checks PostgreSQL at startup and fails startup if the database is unavailable.

### 5. Check the Connection in Postman

Send a request with no body or authentication:

```http
GET http://localhost:3000/health/ready
```

Connected: **HTTP 200**

```json
{"status":"ok","database":"up"}
```

Failed database query while the backend is running: **HTTP 503**

```json
{"status":"error","database":"down"}
```

Each request executes a live `SELECT 1` through Prisma.
This verifies database reachability/query execution, not the entire app or
schema completeness. If the backend cannot start, Postman shows a connection
error rather than a 503 response.

### 6. Test Registration and Login in Postman

Start the backend, then use **Body -> raw -> JSON** with
`Content-Type: application/json`. For local-only testing:

```http
POST http://localhost:3000/auth/register
```

```json
{
  "email": "alex@example.invalid",
  "displayName": null,
  "password": "Synthetic demo passphrase only!"
}
```

This creates a real row in your local development database. The example is
synthetic and publicly documented; never reuse its password for real accounts.
Use a new synthetic email for each successful registration test.

Registration returns **201**, with this shape:

```json
{
  "accessToken": "<JWT returned by the backend>",
  "tokenType": "Bearer",
  "expiresIn": 1800,
  "user": {
    "id": "<account UUID>",
    "email": "alex@example.invalid",
    "createdAt": "<ISO timestamp>"
  }
}
```

Log in with the same JSON at:

```http
POST http://localhost:3000/auth/login
```

Login returns **200** and the same response shape. Email is trimmed and
lowercased; passwords are not trimmed or otherwise normalized.
Passwords must be 15-128 characters; passphrases are encouraged, without
mandatory symbol/uppercase rules. Unexpected fields such as `role` or `id`
are rejected rather than applied to the account.

Copy the returned `accessToken` into Postman's **Authorization -> Bearer Token**
for this request:

```http
GET http://localhost:3000/users/me
```

It returns **200** with only your `id`, `email`, `displayName`, and `createdAt`.
Do not include the word `Bearer` in Postman's token input; Postman adds it.
There is no public user list, profile directory, or account-by-ID endpoint.
Do not sync tokens/passwords into shared Postman workspaces or export them.

With the same bearer token, update your private display name:

```http
PATCH http://localhost:3000/users/me
Content-Type: application/json

{"displayName":"Alex"}
```

The trimmed name must contain 1-80 characters. Other account fields cannot be
changed here. This name is visible only to you, not a public username or profile,
and does not automatically rename group participants.

| Check | Expected status |
| --- | --- |
| Register valid new account | 201 |
| Register duplicate email, including changed case | 409, generic registration error |
| Login with correct credentials | 200 |
| Login with wrong password or unknown email | 401, same generic error |
| Invalid email, short password, extra fields | 400 |
| `/users/me` without a token, with a modified token, or after expiry | 401 |
| Login exceeds 5 attempts in 60 seconds from the same IP | 429 |
| Registration exceeds 3 attempts in 60 seconds from the same IP | 429 |

Invalid submissions count toward rate limits. Wait for `Retry-After` before
trying again. Limits are separate per endpoint. Auth responses and current-user
responses use `Cache-Control: no-store`.

Local OpenAPI UI: `http://localhost:3000/docs`

Import `http://localhost:3000/docs-json` into Postman as an OpenAPI definition
to create requests. Use Swagger's **Authorize** button to test `/users/me`.
Docs are disabled when `NODE_ENV=production`; these are development tools.

### 7. Run Flutter

In another terminal, from the repository root:

```bash
cd mobile
flutter pub get
flutter devices
flutter run -d <device-id> --dart-define=API_BASE_URL=http://localhost:3000
```

Replace `<device-id>` with the target ID printed by `flutter devices`, and use
the target-specific backend URL below.

This connects registration, login, and the private account screen, not a persisted
bill workflow. Readiness remains backend-only. Flutter never connects directly
to PostgreSQL.

| Target | Development API URL |
| --- | --- |
| iOS simulator | `http://localhost:3000` |
| Android emulator | `http://10.0.2.2:3000` |
| Physical device | `http://<Mac-LAN-IP>:3000` on the same trusted network |

Android permits cleartext only in debug builds; iOS allows local networking.
Release API configuration requires HTTPS. Do not expose the development server
to the public internet.

For Chrome, allow its exact origin when starting NestJS:

```bash
# From backend/
CORS_ORIGIN=http://localhost:7357 npm run start:dev
```

```bash
# From mobile/
flutter run -d chrome --web-hostname=localhost --web-port=7357 \
  --dart-define=API_BASE_URL=http://localhost:3000
```

Native sessions use `flutter_secure_storage` (Keychain on iOS, secure storage on
Android). Browser previews intentionally keep bearer tokens in memory: reloading
requires signing in again. `http` provides the small typed REST client; no extra
state-management or UI framework is introduced.
Sessions expire after 30 minutes; there is no refresh token.

### macOS: Test on an iOS Simulator with Device Hub

In Xcode 27, use **Xcode > Open Developer Tool > Device Hub**, or choose
**Manage Devices...** from the run-destination menu. Device Hub manages both
simulated and physical devices; simulated iPhones are still supported.
See Apple's [Device Hub guide](https://developer.apple.com/documentation/xcode/managing-your-simulated-and-physical-devices-in-device-hub).

1. In Device Hub, select an iPhone simulator and start it. Use **+** to add one
   if needed; install the matching runtime through Xcode if it is missing.
2. Keep the Podman machine and SplitSum PostgreSQL container running.
3. Keep `npm run start:dev` running in a terminal in `backend/`.
4. In a separate terminal, from the repository root:

```bash
cd mobile
flutter pub get
flutter devices
# Replace <device-id> with the running iPhone simulator's ID:
flutter run -d <device-id> \
  --dart-define=API_BASE_URL=http://localhost:3000
```

Older Xcode versions may expose the Simulator app and **Devices and Simulators**
window instead. Do not select `macos` when you intend to test the iOS app.

If the simulator does not appear, confirm it is started, run `flutter doctor -v`,
and check the installed runtimes with `xcrun simctl list runtimes`.
If sign-in cannot reach the server, first check
`http://localhost:3000/health/ready` on your Mac. iOS simulators can use
`localhost`; physical iPhones require your Mac's reachable LAN address.
CORS configuration is needed for the Chrome preview, not native iOS requests.

#### Manual Authentication Checklist

- Register with a new synthetic email and a 15-128 character password.
- Confirm the private account screen appears.
- Save a display name, sign out, then sign back in and confirm it persists.
- On native iOS, close and reopen the app before the 30-minute expiry to check
  secure session restoration. Chrome reloads intentionally require sign-in.
- Try incorrect credentials and confirm a clear error appears.
- Open **Explore demo groups** and confirm the synthetic-data warning appears.

Registration creates real local database records. Do not use real personal data
for public demos. Groups and bills remain previews; this checklist verifies
authentication, not the full Stage 1 financial workflow. Native iOS runtime
behavior still needs device/simulator verification; a passing web build is not
proof that native secure storage works.

To finish testing, press `q` in the Flutter terminal and `Ctrl+C` in the backend
terminal. Optionally run `podman compose stop postgres` from the repository root;
this preserves the database volume.

---

## Testing and Builds

### Backend

From `backend/`:

```bash
npm test -- --runInBand
npm run db:test:deploy
npm run test:e2e
npm run build
npm run lint
```

Coverage includes equal splits, readiness success/failure/recovery, real
PostgreSQL reads/writes and rollback, registration/login, password hashing,
email normalization, concurrent duplicate signups, current-user boundaries,
invalid/expired tokens, OpenAPI response shapes, and actual rate limits.
Integration tests use synthetic data and remove only their own rows.
Test commands refuse a database not named `splitsum_test`; never supply
production database credentials when running tests.

The main auth integration suite bypasses throttling to test business behavior;
a separate suite verifies the real limiter and forwarded-header behavior.

### Mobile

From `mobile/`:

```bash
flutter analyze
flutter test
```

Tests cover typed API responses/errors, session restoration and expiry, storage
failures, authentication forms, private name editing, sign-out, demo navigation,
themes, and narrow-screen layouts. An end-to-end financial workflow will receive
tests when its product APIs are implemented.

---

## Security and Privacy

- Working environment files, build outputs, dependencies, and generated Prisma
  code stay out of Git. Source, lockfiles, schema, and migrations stay in Git.
- Database errors from the readiness endpoint use generic messages, without
  exposing connection details.
- Passwords use Argon2id with 19 MiB memory, 2 iterations, and parallelism 1.
  The library generates a fresh salt. Only hashes are stored; no plaintext
  password or password hash is returned by the API.
- Access tokens use HS256 with a random 32-byte backend-only signing key.
  Verification restricts the algorithm, issuer, audience, expiry, and account
  identity. The guard checks that the account still exists and exposes only
  the signed-in user's safe fields.
- Routes are protected by default. Registration, login, the original root
  endpoint, and database readiness are explicitly public. Future group/bill
  endpoints must additionally enforce resource ownership in their services.
- Login uses a generic error for nonexistent accounts and wrong passwords.
  Unknown accounts still perform Argon2 verification. Duplicate registration
  uses generic wording but its 409 status can reveal that an email is already
  registered; email-enumeration resistance for public signup is not claimed.
- Strict DTO validation rejects extra properties, JSON bodies are limited to
  16 KiB, and Helmet adds standard HTTP security headers. No wildcard CORS or
  cookie-based authentication is enabled.
- In-memory IP throttling uses 5 login and 3 registration attempts per minute,
  plus a default 60-request/minute limit for other routes. Readiness is exempt.
  Limits reset on restart and apply to one backend process. They are a basic
  MVP defense, not distributed abuse protection; no Redis is introduced.
- Express does not trust forwarded IP headers by default. Before deployment
  behind a proxy, configure trust for the actual proxy path and add edge abuse
  limits; do not blindly trust arbitrary `X-Forwarded-For`.
- Tokens expire after 30 minutes. No refresh, password reset, email verification,
  password change, or immediate token-revocation endpoint exists yet.
  Mobile sign-out deletes the token locally, but a copied token remains
  valid until expiry. Key rotation invalidates existing tokens.
- Production must use HTTPS and properly managed environment secrets.
  HTTP is for local development only. Mobile bearer tokens use native secure
  storage; browser previews use memory-only sessions, not localStorage.
- Never log authorization headers, passwords, or complete auth response bodies.
  Operational errors must be investigated without copying credentials into logs.
- Future AI provider keys stay on the backend. Receipt content will be treated
  as untrusted input, and extracted values must pass runtime validation.
- Receipt images will not be retained by default. Public demos and fixtures
  must use synthetic or permissioned data.

Local Compose configuration is for development, not a production deployment.
Hosting is undecided; no cloud resources, paid AI services, or payment
integrations are provisioned.
This authentication increment is suitable for development testing, not a public
signup launch: add account recovery/verification, a production TLS/proxy setup,
and deployment-appropriate abuse controls before exposing it publicly.
