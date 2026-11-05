# SplitSum

A Hong Kong-friendly mobile app for splitting shared expenses, built as a
**personal portfolio and learning project**. The goal is a small, tested manual
bill workflow before introducing AI-assisted receipt entry.

**Early development:** registration, login, and a private editable display name
work through the backend. Groups and bills are synthetic-data previews, not
saved financial records. AI receipt scanning is not implemented.

## Tech Stack

| Area | Technologies |
| --- | --- |
| Mobile | Flutter, Dart, Material 3, light/dark themes |
| Backend | NestJS, TypeScript, REST APIs, OpenAPI |
| Database | PostgreSQL 17, Prisma ORM |
| Local development | Podman Compose, npm, Xcode Device Hub |
| Testing | Jest, Supertest, Flutter tests and analyzer |

## Architecture

One feature-organized backend serves the Flutter app. No microservices or direct
mobile database connections.

```text
Flutter UI → State → Feature API → Shared HTTP client
                                      ↓ REST / JSON
NestJS controller → Service → Prisma → PostgreSQL
```

- **Flutter:** screens render UI; state handles loading and actions; feature APIs
  call the backend through shared networking.
- **NestJS:** controllers expose routes, DTOs validate requests, guards enforce
  authentication, and services own application rules.
- **PostgreSQL:** stores accounts and, later, financial records. Prisma migrations
  track schema changes. NestJS remains authoritative for money calculations.

### Project Structure

```text
backend/
  src/          # Feature modules: auth, users, bills, database, health
  prisma/       # Database schema and versioned migrations
  test/         # HTTP/database integration tests
mobile/
  lib/
    core/       # Shared API client, secure storage, theme
    features/   # Feature data, models, state, screens, widgets as needed
    shared/     # Reusable UI widgets
    prototype/  # Synthetic demo data
  test/         # API, session, and widget tests
compose.yaml    # Local PostgreSQL
```

## Local Setup

### 1. Prerequisites

- Node.js 24.11+ LTS and npm (also tested with Node 26).
- Flutter SDK; run `flutter doctor -v` to check platform tooling.
- Podman with a Compose provider.
- For iOS on macOS: full Xcode and an iOS runtime; CocoaPods if Flutter requests it.

### 2. Clone and Configure

Clone the repository and enter it:

```bash
git clone https://github.com/alxwong1991/splitsum.git
cd splitsum
```

For a fresh checkout, copy these templates. **Do not overwrite existing files.**

| Template | Local file |
| --- | --- |
| [.env.example](./.env.example) | `.env` |
| [backend/.env.example](./backend/.env.example) | `backend/.env` |
| [backend/.env.test.example](./backend/.env.test.example) | `backend/.env.test` |

Use `openssl rand -hex 32` to generate a local database password. Set it in root
`POSTGRES_PASSWORD` and both backend `DATABASE_URL` values. Generate separate
random `JWT_SECRET` keys for development and tests. Never commit secrets.

PostgreSQL uses port **5433**, user `splitsum`, development database `splitsum`,
and test database `splitsum_test`. Both databases share one container; HireFlow's
port 5432 is unaffected.

### 3. Start PostgreSQL

From the repository root:

```bash
podman machine list
# Only if no machine exists: podman machine init
# Only if the machine is stopped: podman machine start
podman compose up -d postgres
```

## Run the Backend

From the repository root:

```bash
cd backend
npm install
npm run db:deploy
npm run db:test:deploy
npm run start:dev
```

Keep this terminal running. Dependency installation and migration deployment
are setup steps; on later runs, start the database and use `npm run start:dev`.

| Resource | Local URL |
| --- | --- |
| API | `http://localhost:3000` |
| Swagger UI | `http://localhost:3000/docs` |
| OpenAPI import for Postman | `http://localhost:3000/docs-json` |
| Database readiness | `http://localhost:3000/health/ready` |

OpenAPI endpoints are development-only.

## Run the Mobile App

### iOS on macOS

For **Xcode 27 / iOS 27**, open Device Hub from the terminal:

```bash
open -a DeviceHub
```

Or choose **Xcode > Open Developer Tool > Device Hub**. Select and start an
iPhone simulator; use **+** to add one if necessary.
See Apple's [Device Hub guide](https://developer.apple.com/documentation/xcode/managing-your-simulated-and-physical-devices-in-device-hub).

Keep the backend running. In a second terminal, from the repository root:

```bash
cd mobile
flutter pub get
flutter devices
# Replace <device-id> with the running iPhone simulator's ID:
flutter run -d <device-id> \
  --dart-define=API_BASE_URL=http://localhost:3000
```

Choose the iPhone device ID, not the `macos` target.

### Other Targets

| Target | Development backend URL |
| --- | --- |
| iOS simulator | `http://localhost:3000` |
| Android emulator | `http://10.0.2.2:3000` |
| Physical phone | `http://<Mac-LAN-IP>:3000` on the same trusted network |

For Android or a physical phone, use its URL above in `API_BASE_URL`.
For Chrome, stop the existing backend and restart it from `backend/` with:

```bash
CORS_ORIGIN=http://localhost:7357 npm run start:dev
```

Then, from `mobile/`:

```bash
flutter run -d chrome --web-hostname=localhost --web-port=7357 \
  --dart-define=API_BASE_URL=http://localhost:3000
```

HTTP is for local development only; release API configuration requires HTTPS.
Do not expose the development server to the public internet.

## Try the App

1. Register with a synthetic email and an **8-128 character** password.
2. Save a private display name, sign out, and sign in again.
3. Try incorrect credentials to see the error state.
4. Open **Explore demo groups** to explore the sample layouts.

Postman endpoints:

| Method | Path | Input / authentication |
| --- | --- | --- |
| POST | `/auth/register` | JSON `email`, `password` |
| POST | `/auth/login` | Same JSON; returns `accessToken` |
| GET | `/users/me` | Authorization: Bearer Token |
| PATCH | `/users/me` | Bearer token; `{"displayName":"Alex"}` |

Names are private, trimmed, and 1-80 characters. Participants currently remain
group-local names, not connected accounts.

<details>
<summary>Authentication and security notes</summary>

Passwords use Argon2id; longer unique passphrases are still recommended.
The 8-character minimum is a learning-project choice, not a production-security
claim. JWTs expire after 30 minutes, without refresh tokens, password recovery,
or email verification. Native tokens use secure storage; Chrome uses memory only
and loses its session on reload. Sign-out deletes the local token, but copied
tokens remain valid until expiry. Auth endpoints have basic IP rate limits.

</details>

## Tests

```bash
# From backend/
npm test -- --runInBand
npm run test:e2e
npm run build
npm run lint

# From mobile/
flutter analyze
flutter test
```

Backend integration tests require migrated `splitsum_test` and refuse other
database names. Use synthetic data; never run tests against production.
Coverage includes split rounding, authentication, ownership boundaries,
database rollback, API errors, session handling, forms, and layouts.

### Stop Local Services

Stop Flutter with `q` and the backend with `Ctrl+C`. From the root,
`podman compose stop postgres` preserves data. **Do not use `down -v`** unless
you intend to delete the database volume. Changing an environment password does
not change an existing database's password.

## macOS Troubleshooting

<details>
<summary>Node/npm missing in a new terminal</summary>

If using fnm, add this once to `~/.zshrc` after Homebrew PATH setup:

```zsh
eval "$(fnm env --use-on-cd --shell zsh)"
```

Run `source ~/.zshrc`, `fnm use default`, and `node --version`.
If using another Node manager, use its setup instead.

</details>

<details>
<summary>Simulator missing or backend unreachable</summary>

Start an iPhone in Device Hub, then check `flutter doctor -v` and
`xcrun simctl list devices available`. Check the readiness URL on your Mac if
login cannot reach the backend. iOS simulators use `localhost`; physical phones
need your Mac's reachable LAN address. Native requests do not require CORS.

</details>

## Next Steps and Financial Rules

**Stage 1 next:** create a group → add participants → save an equal-split bill →
display shares, then balances, manual settlements, and text sharing.
**Stage 2 later:** receipt-total extraction with user review and manual fallback.
No payment processing, public profiles, collaborative groups, or currency
conversion initially.

<details>
<summary>Agreed financial rules and planned data model</summary>

- HKD integer cents; deterministic remainders by immutable participant order.
  Shares sum exactly to the total; the payer may be excluded.
- Direct debts, without offsetting or rerouting. Derive balances from bills,
  shares, and settlements rather than editable balance totals.
- Partial/full settlements reduce obligations; reject overpayments.
- Any historical settlement locks bill editing/deletion in that group.
  Removing a settlement must not unlock history.
- Archive referenced participants; exclude archived names from new bills.
- Enforce ownership and group-scoped references. Save related writes and retry
  records transactionally; reject retry-key reuse with different input.
- Bills range from 1 to 2,147,483,647 cents; zero-cent shares are allowed.

Planned entities: owner-managed `Group`, ordered `Participant`, `Bill`,
`BillShare`, `Settlement`, and `IdempotencyRequest`, linked to `Account`.
Only equal-split calculation exists so far; financial persistence is next.

</details>
