# SplitSum

A Hong Kong-friendly mobile app for splitting shared expenses, built as a
**personal portfolio and learning project**. The goal is a small, tested manual
bill workflow before introducing AI-assisted receipt entry.

**Early development:** authentication and group/participant management connect
the mobile app to the backend. Equal-split bills, direct balances, and manual
settlements and registered-user invitations are backend-only; mobile bill
screens remain synthetic previews. Receipt scanning is not implemented.

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
- **PostgreSQL:** stores accounts, groups, and backend financial records. Prisma migrations
  track schema changes. NestJS remains authoritative for money calculations.

### Project Structure

```text
backend/
  src/          # Feature modules: auth, groups, bills, balances, settlements, etc.
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

### View the Database

Prisma Studio provides a local browser interface, similar to Adminer. With
PostgreSQL running, open a separate terminal from the project root:

```bash
cd backend
npx prisma studio --port 5555
```

Open [http://localhost:5555](http://localhost:5555) and select **Account** to
view registered users. Studio uses `DATABASE_URL` from `backend/.env`, normally
the development database (`splitsum`), not `splitsum_test`.

Studio can edit data, so use care and keep it local. Passwords are stored as
hashes; don't edit or share them. Press `Ctrl+C` in the Studio terminal to stop it.
If you see a Prisma version error, ensure the CLI and client versions in
`backend/package.json` match, then run `npm install` in `backend/`.

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
flutter run -d <device-id>
```

Choose the iPhone device ID, not the `macos` target. Debug builds default to
`http://localhost:3000`, which reaches your Mac from the iOS simulator.
Restart Flutter after changing the backend address.

### Other Targets

| Target | Development backend URL |
| --- | --- |
| iOS simulator | `http://localhost:3000` |
| Android emulator | `http://10.0.2.2:3000` |
| Physical phone | `http://<Mac-LAN-IP>:3000` on the same trusted network |

For Android or a physical phone, override the default with its URL above:

```bash
flutter run -d <device-id> --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

Use your Mac's LAN address instead of `10.0.2.2` for a physical phone.
For Chrome, stop the existing backend and restart it from `backend/` with:

```bash
CORS_ORIGIN=http://localhost:7357 npm run start:dev
```

Then, from `mobile/`:

```bash
flutter run -d chrome --web-hostname=localhost --web-port=7357 \
  --dart-define=API_BASE_URL=http://localhost:3000
```

HTTP is for local development only; profile and release builds have no default
URL. Supply `--dart-define=API_BASE_URL=https://your-backend.example` for release;
release API configuration requires HTTPS.
Do not expose the development server to the public internet.

## Try the App

1. Register with a synthetic email and an **8-128 character** password.
2. Save a private display name, sign out, and sign in again.
3. Try incorrect credentials to see the error state.
4. Open **Your groups** to create and rename real groups, add or rename
   participants, select yourself, and archive participants.
5. Open **Explore demo groups** separately to explore synthetic sample layouts.

Postman endpoints:

| Method | Path | Input / authentication |
| --- | --- | --- |
| POST | `/auth/register` | JSON `email`, `password` |
| POST | `/auth/login` | Same JSON; returns `accessToken` |
| GET | `/users/me` | Authorization: Bearer Token |
| PATCH | `/users/me` | Bearer token; `{"displayName":"Alex"}` |

Account display names are private. Group participant names are visible to the
group owner and accepted members, trimmed, and 1-80 characters.

### Groups and Participants API

These backend endpoints require a bearer token. Owners manage the group;
accepted members can read it. The mobile app still uses the original owner-only
interface and does not yet support invitations or member permissions.

| Method | Path | JSON body |
| --- | --- | --- |
| POST | `/groups` | `{"name":"Friday Dinner"}` |
| GET | `/groups` | — |
| GET | `/groups/{groupId}` | — |
| PATCH | `/groups/{groupId}` | `{"name":"Dinner"}` |
| POST | `/groups/{groupId}/participants` | `{"name":"Alex"}` |
| PATCH | `/groups/{groupId}/participants/{participantId}` | `{"name":"Alex Wong"}` |
| PATCH | `/groups/{groupId}/participants/{participantId}/archive` | — |
| PUT | `/groups/{groupId}/self` | `{"participantId":"<participant-uuid>"}` or `{"participantId":null}` |

Group and participant names are trimmed and must be 1-80 characters; duplicate
names are allowed. Group details include active and archived participants in
stable creation order. Archiving is permanent for now and clears the self
selection when applicable; archived participants cannot be renamed or selected
as self. Archiving an account-linked participant revokes group access but retains
their financial history; rejoining is not supported yet. A joined member chooses
their own group name on acceptance, and the owner cannot rename that participant.
Group deletion is deferred. Inaccessible groups and participants return 404.

The manual participant endpoint remains temporarily for the existing mobile
app and is not an invitation. Existing named participants and their financial
history are not automatically linked to registered accounts.

Creation requests are not yet retry-safe: after a timeout, check the group list
or details before retrying to avoid duplicate groups or participants. The app
requires a refresh after an uncertain write before allowing another change.
An earlier request may still be processing, so wait and check again before
retrying if its result is not yet visible.

### Registered-User Invitations API

The owner enters the exact email of an existing account. Invitations are shown
in the recipient's in-app inbox; no email or push notification is sent. The
recipient accepts with a group-specific name or declines. Accepting creates a
new linked participant and does not transfer existing participants' debts.

| Method | Path | Purpose |
| --- | --- | --- |
| POST | `/groups/{groupId}/invitations` | Owner invites using `{"email":"friend@example.invalid"}` |
| GET | `/groups/{groupId}/invitations` | Owner lists sent invitations and statuses |
| PATCH | `/groups/{groupId}/invitations/{invitationId}/cancel` | Owner cancels a pending invitation |
| GET | `/invitations` | Recipient lists pending invitations |
| POST | `/invitations/{invitationId}/accept` | Recipient joins using `{"name":"Sam"}` |
| POST | `/invitations/{invitationId}/decline` | Recipient declines |

Pending invitations do not expire automatically. Sending a duplicate pending
invitation returns the existing one; cancelled or declined invitations can be
sent again. A group can have only one participant per registered account.

Accepted members can read the group, participants, all bills, balances, and
settlements. Only the owner can change them. Group responses include `role`
(`owner` or `member`) and the viewer's `selfParticipantId`.

**Important:** Email addresses are not verified. An account email does not prove
the person owns that address, and the invitation endpoint can reveal whether an
email is registered despite its basic rate limit. Do not rely on this for
sensitive data or public deployment. Invitation flow and role enforcement have
not yet been tested. The mobile invitation inbox and role-aware controls are
not implemented; members using the current UI may see owner-only actions that
the backend rejects.

### Bills API

These endpoints require a bearer token. Owners create bills; owners and accepted
members can read them. Create participants first; their IDs are returned in
group details.

| Method | Path | Purpose |
| --- | --- | --- |
| POST | `/groups/{groupId}/bills` | Save an equally split HKD bill |
| GET | `/groups/{groupId}/bills` | List bill history, newest bill date first |
| GET | `/groups/{groupId}/bills/{billId}` | View a bill and its shares |

For `POST`, set `Content-Type: application/json` and a unique
`Idempotency-Key` header, for example `dinner-2026-11-24-1`. The key must be
1-128 letters, digits, or `.`, `_`, `:`, `-`. Example body:

```json
{
  "description": "Dinner",
  "billDate": "2026-11-24",
  "totalCents": 10000,
  "payerId": "<payer-uuid>",
  "participantIds": ["<participant-uuid>", "<another-participant-uuid>"]
}
```

Replace the placeholders with active participants from the same group. The
payer does not have to be included in the split. NestJS saves cents and
calculates shares in participant creation order. Retrying the same request with
the same key returns the existing bill; reusing that key for different input
returns 409. Use a new key for each new bill. Names in history reflect current
participant names, including archived participants.

Bill editing/deletion is not available yet.

### Balances and Settlements API

Owners can record settlements; owners and accepted members can read balances
and settlements:

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/groups/{groupId}/balances` | List outstanding direct debts in HKD cents |
| GET | `/groups/{groupId}/settlements` | List manually recorded settlements |
| POST | `/groups/{groupId}/settlements` | Record a payment made outside the app |

For `POST`, provide a unique `Idempotency-Key` header using the same rules as
bill creation, plus this JSON body:

```json
{
  "fromParticipantId": "<person-who-owes-uuid>",
  "toParticipantId": "<person-owed-uuid>",
  "amountCents": 5000
}
```

Only the debt from the payer to the recipient is reduced; opposite debts are
not offset. Partial and full settlements are allowed, but overpayments and
payments to the same person are rejected. Archived participants can settle
existing debts. A retry with the same key and payload returns the existing
settlement; different input with that key returns 409. Editing or deleting
settlements is deferred. Once a settlement has existed, the group is permanently
marked for the future bill editing/deletion lock.

These APIs record payments; they do not transfer money or verify payment. The
new group, bill, balance, and settlement endpoints and mobile group integration
have not yet been tested. Add financial and ownership tests before relying on
them.

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

**Stage 1 next:** test financial and access rules, connect invitations, bills,
balances and settlements to mobile, then add text sharing.
**Stage 2 later:** receipt-total extraction with user review and manual fallback.
No payment processing, public profile directory, collaborative editing, or
currency conversion initially.

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

`Group`, ordered `Participant`, `Bill`, `BillShare`, `Settlement`, and
`IdempotencyRequest` records are implemented in the backend. Balances are
derived from bills and settlements rather than saved separately.

</details>
