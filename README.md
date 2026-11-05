# SplitSum

SplitSum is a Hong Kong-friendly mobile bill-splitting app being built with
Flutter, NestJS, and PostgreSQL. It is a personal product and portfolio project
focused on a small, complete, tested manual workflow before adding
AI-assisted receipt entry.

**Status: early development.** The backend database foundation and equal-split
calculation work. The mobile app has a connection-check card alongside the Flutter scaffold; the complete
bill-splitting workflow is not available yet.

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
OpenAPI documentation is planned alongside the product APIs.

---

## Current Progress

### Implemented

- NestJS and Flutter scaffolds running with their existing tooling.
- Isolated local PostgreSQL with a persistent volume.
- Prisma connection and initial `Account` migration.
- Database readiness endpoint for Postman or command-line checks.
- Flutter connection-check card with configurable API URL and loading/error/retry states.
- Integer-cent equal splitting with deterministic rounding.
- Backend unit tests and real database persistence/rollback tests.

### Next: First Vertical Slice

1. Email/password registration and sign-in.
2. Create an owner-managed group.
3. Add named participants, without requiring their registration.
4. Enter a bill with one payer and select its split participants.
5. Calculate equal shares in NestJS and save them atomically in PostgreSQL.
6. Display the saved bill and shares in Flutter.

Authentication, group/participant/bill APIs, authenticated mobile API access, and mobile
credential storage are not implemented yet.

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

See the [backend documentation](./backend/README.md) for the proposed data model
and detailed financial rules.

---

## Project Structure

```text
splitsum/
  backend/
    prisma/             # Schema, migrations, test database initialization
    src/
      bills/            # Equal-split calculation and tests
      database/         # Prisma service and NestJS module
      health/           # Live PostgreSQL readiness check
    test/               # HTTP and PostgreSQL integration tests
  mobile/
    lib/                # Flutter starter screen, health API, connection widget
    test/               # Flutter widget tests
    android/
    ios/
    web/
  compose.yaml          # Local PostgreSQL only
```

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

### 6. Run Flutter

In another terminal, from the repository root:

```bash
cd mobile
flutter pub get
flutter devices
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

This displays the starter counter screen with a **Check connection** card,
not the bill workflow. The example URL works for an iOS simulator; use
`http://10.0.2.2:3000` for an Android emulator.
See [mobile setup](./mobile/README.md) for Chrome's exact-origin CORS configuration.
Android emulators normally use `10.0.2.2` to reach a Mac backend; physical
devices need a reachable development host. Flutter never connects directly
to PostgreSQL.

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

Coverage currently includes equal splits and invalid input, readiness success
and failure/recovery, real PostgreSQL reads/writes, and transaction rollback.
Integration tests use synthetic data and remove only their own rows.
Test commands refuse a database not named `splitsum_test`; never supply
production database credentials when running tests.

### Mobile

From `mobile/`:

```bash
flutter analyze
flutter test
```

Tests cover the Flutter scaffold and connection-check API/UI states. Product forms and an
end-to-end manual workflow will receive tests as they are implemented.

---

## Security and Privacy

- Working environment files, build outputs, dependencies, and generated Prisma
  code stay out of Git. Source, lockfiles, schema, and migrations stay in Git.
- Database errors from the readiness endpoint use generic messages, without
  exposing connection details.
- Authentication will use established password hashing and secure mobile
  credential storage; every protected resource will enforce ownership.
- Future AI provider keys stay on the backend. Receipt content will be treated
  as untrusted input, and extracted values must pass runtime validation.
- Receipt images will not be retained by default. Public demos and fixtures
  must use synthetic or permissioned data.

Local Compose configuration is for development, not a production deployment.
Hosting is undecided; no cloud resources, paid AI services, or payment
integrations are provisioned.
