# SplitSum backend

## Current increment

The NestJS scaffold is preserved. The authoritative equal-split calculation
and its unit tests are implemented in [src/bills/](./src/bills/).
NestJS now connects to local PostgreSQL through Prisma, with an initial
account-table migration and real persistence/rollback integration tests.
Authentication, group/bill APIs, and the Flutter manual workflow are not
implemented yet. There is no AI integration.

Run the calculation tests with `npm test -- --runInBand equal-split`.

## Financial rules

- HKD only. API amounts will be integer cents, never decimal money values.
  Positive bill totals may range from 1 to 2,147,483,647 cents, matching a
  PostgreSQL `integer`. Zero-cent shares are valid when a positive total is
  smaller than the number of selected participants.
- At least one participant must be selected, without duplicates. NestJS will
  also verify that the payer and every selected participant belong to the
  owner's group and are not archived before saving.
- A participant has an immutable, unique position within their group.
  Remainder cents go to selected participants in ascending position order,
  independent of selection order, renaming, or gaps left by archiving.
- The payer is separate from the split selection and may be excluded.
  The payer's own share, if present, is not a debt to themselves.
- **Direct debts, not net balances:** each non-payer's share is owed to that
  bill's payer. Do not offset opposite-direction debts or reroute payments
  between participants. Displayed balances will be derived from financial
  records, not independently editable totals.
- Later, manual settlements will reduce a specific debtor-to-creditor
  obligation. Partial and full settlements are allowed; overpayments are
  rejected. They are not expenses or verified payments.
- Once any settlement is recorded in a group, block bill editing/deletion
  in that group. Removing a settlement must not implicitly unlock history;
  retain the fact that settlements have existed.
- Referenced participants may be archived, not hard-deleted. Archived
  participants remain visible in historical bills and obligations but cannot
  participate in new bills. Identifying the owner's participant does not
  change calculations.

## Proposed persistence model

Use Prisma with one PostgreSQL database and feature-organized Nest modules.
Only `Account` is migrated so far; the remaining entities are planned:

| Entity | Essential fields |
| --- | --- |
| Account | ID, unique normalized email, password hash |
| Group | ID, owner account ID, name, optional self-participant ID |
| Participant | ID, group ID, name, immutable position, archived flag |
| Bill | ID, group ID, payer participant ID, description, bill date, total cents, creation time |
| BillShare | Bill ID, participant ID, amount cents; unique bill/participant pair |
| IdempotencyRequest | Owner, operation, retry key, canonical request payload, resulting resource ID |

Every protected read/write must check ownership. Group-scoped participant
references must also be enforced by database constraints. Save a bill, all
shares, and its idempotency record in one transaction. An identical retried
request returns the existing resource; reusing a key with a different payload
must fail. Database integration tests must verify concurrency and rollback,
not just mocked persistence.

## Local PostgreSQL and backend setup

Use **Podman with Compose**, not Docker Desktop. From the repository root:

```bash
podman machine list
# Start the existing machine only if it is stopped:
podman machine start
podman compose version
podman compose up -d postgres
podman compose exec -T postgres pg_isready -U splitsum -d splitsum
```

The Compose project is named `splitsum`. PostgreSQL 17 publishes only
`127.0.0.1:5433` and stores data in the `splitsum_postgres_data` volume.
HireFlow's containers and port 5432 are not modified. Do not run
`podman compose down -v`: it deletes this project's database volume.

Local credentials have been generated into the root `.env`, `backend/.env`,
and `backend/.env.test`, all Git-ignored with private file permissions.
Do not print, commit, or share their contents. On a fresh checkout:

1. Copy the root `.env.example`, `backend/.env.example`, and
   `backend/.env.test.example` to their corresponding names without `.example`.
   Do not overwrite existing files.
2. Generate a local password (for example, `openssl rand -hex 32`).
   Set the same password in the root `POSTGRES_PASSWORD` and both backend
   connection URLs. These example URLs are templates, not working credentials.
3. Start PostgreSQL using the commands above.

On first initialization, PostgreSQL creates `splitsum` and the separate
`splitsum_test` database. The initialization SQL does not rerun when reusing an
existing volume. Changing `.env` alone does not change an existing database's
password; retain the existing credentials.

From `backend/`:

```bash
npm install
npm run db:deploy          # Apply committed migrations to the development DB
npm run db:test:deploy     # Apply migrations to the isolated test DB
npm run start:dev          # http://localhost:3000/ still returns Hello World!
```

For future schema changes, use `npm run db:migrate -- --name descriptive_name`
and commit the generated migration. `npm run build` regenerates Prisma Client.
Generated client files are ignored; the schema and migrations are committed.
Do not use development migration commands or local Compose credentials for
production. The built app accepts `DATABASE_URL` and `PORT` from the deployment
environment; local `.env` files are not required when those variables are set.

### Connection behavior and tests

[DatabaseModule](./src/database/database.module.ts) exports
[PrismaService](./src/database/prisma.service.ts) for feature modules. It uses
Prisma 7's PostgreSQL driver adapter and checks the connection with `SELECT 1`
at startup. Missing/invalid configuration or an unavailable database prevents
successful startup rather than silently falling back to another database.
Shutdown hooks disconnect the database client.
The PostgreSQL driver has three-second connection and query timeouts so an
unavailable database does not leave checks waiting indefinitely.

### Check PostgreSQL from Postman

Start the backend with `npm run start:dev`, then send:

```text
GET http://localhost:3000/health/ready
```

No body or authentication is required. Each request executes a live `SELECT 1`
through Prisma; it does not just check whether the HTTP server is running.
Responses use `Cache-Control: no-store`.

- HTTP **200**: `{"status":"ok","database":"up"}`
- HTTP **503**: `{"status":"error","database":"down"}`

Database errors are logged with a generic message, without connection details.
This endpoint only checks database reachability/query execution, not schema
completeness, write permissions, or the entire financial workflow.
The original `GET /` remains unchanged.

If PostgreSQL is already down when NestJS starts, startup fails and Postman
will show a connection error, not a 503 response. The 503 response applies
when the backend is running but its database check fails.

The initial [schema](./prisma/schema.prisma) contains only the account fields
needed by the next authentication increment. No real accounts or credentials
are seeded. Integration fixtures use synthetic data and clean up only their
own rows.

```bash
npm test -- --runInBand
npm run db:test:deploy
npm run test:e2e
npm run build
npm run lint
```

Test migrations and integration tests refuse any database not named
`splitsum_test`. Keep the test URL on the isolated local server; do not supply
production connection variables when running tests. Both URLs normally point
to the same PostgreSQL container, not separate backend database infrastructure.
Jest maps relative `.js` imports to source files so Prisma's generated
TypeScript works with the existing ts-jest setup.

The readiness endpoint is backend-only for Postman and operational checks.
Flutter product APIs are not wired yet. Future mobile integration will use
explicit development configuration and HTTPS in production; Flutter will
never connect directly to PostgreSQL. See [mobile setup](../mobile/README.md).
Android emulators normally reach a Mac backend through
`10.0.2.2`, while physical devices need a reachable development host rather
than their own `localhost`.

## Next milestones

1. Add minimal email/password authentication with ownership checks on the
   verified Podman/PostgreSQL foundation.
2. Implement group and participant creation, transactional retry-safe bill
   creation/read, and OpenAPI documentation.
3. Connect Flutter forms and saved bill details, with explicit loading,
   validation, and error/retry states.
4. Verify the real persisted manual workflow before implementing balances,
   settlements, or any receipt extraction.

## Original NestJS scaffold documentation

<p align="center">
  <a href="http://nestjs.com/" target="blank"><img src="https://nestjs.com/img/logo-small.svg" width="120" alt="Nest Logo" /></a>
</p>

[circleci-image]: https://img.shields.io/circleci/build/github/nestjs/nest/master?token=abc123def456
[circleci-url]: https://circleci.com/gh/nestjs/nest

  <p align="center">A progressive <a href="http://nodejs.org" target="_blank">Node.js</a> framework for building efficient and scalable server-side applications.</p>
    <p align="center">
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/v/@nestjs/core.svg" alt="NPM Version" /></a>
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/l/@nestjs/core.svg" alt="Package License" /></a>
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/dm/@nestjs/common.svg" alt="NPM Downloads" /></a>
<a href="https://circleci.com/gh/nestjs/nest" target="_blank"><img src="https://img.shields.io/circleci/build/github/nestjs/nest/master" alt="CircleCI" /></a>
<a href="https://discord.gg/G7Qnnhy" target="_blank"><img src="https://img.shields.io/badge/discord-online-brightgreen.svg" alt="Discord"/></a>
<a href="https://opencollective.com/nest#backer" target="_blank"><img src="https://opencollective.com/nest/backers/badge.svg" alt="Backers on Open Collective" /></a>
<a href="https://opencollective.com/nest#sponsor" target="_blank"><img src="https://opencollective.com/nest/sponsors/badge.svg" alt="Sponsors on Open Collective" /></a>
  <a href="https://paypal.me/kamilmysliwiec" target="_blank"><img src="https://img.shields.io/badge/Donate-PayPal-ff3f59.svg" alt="Donate us"/></a>
    <a href="https://opencollective.com/nest#sponsor"  target="_blank"><img src="https://img.shields.io/badge/Support%20us-Open%20Collective-41B883.svg" alt="Support us"></a>
  <a href="https://twitter.com/nestframework" target="_blank"><img src="https://img.shields.io/twitter/follow/nestframework.svg?style=social&label=Follow" alt="Follow us on Twitter"></a>
</p>
  <!--[![Backers on Open Collective](https://opencollective.com/nest/backers/badge.svg)](https://opencollective.com/nest#backer)
  [![Sponsors on Open Collective](https://opencollective.com/nest/sponsors/badge.svg)](https://opencollective.com/nest#sponsor)-->

## Description

[Nest](https://github.com/nestjs/nest) framework TypeScript starter repository.

## Project setup

```bash
$ npm install
```

## Compile and run the project

```bash
# development
$ npm run start

# watch mode
$ npm run start:dev

# production mode
$ npm run start:prod
```

## Run tests

```bash
# unit tests
$ npm run test

# e2e tests
$ npm run test:e2e

# test coverage
$ npm run test:cov
```

## Deployment

When you're ready to deploy your NestJS application to production, there are some key steps you can take to ensure it runs as efficiently as possible. Check out the [deployment documentation](https://docs.nestjs.com/deployment) for more information.

If you are looking for a cloud-based platform to deploy your NestJS application, check out [Mau](https://mau.nestjs.com), our official platform for deploying NestJS applications on AWS. Mau makes deployment straightforward and fast, requiring just a few simple steps:

```bash
$ npm install -g @nestjs/mau
$ mau deploy
```

With Mau, you can deploy your application in just a few clicks, allowing you to focus on building features rather than managing infrastructure.

## Observability

In production applications, observability is essential for understanding how your system behaves, detecting issues early, and maintaining reliable performance.

[NestJS Observe](https://observe.nestjs.com) automatically instruments your NestJS application, giving you deep visibility into your system with minimal setup:

- **Distributed tracing:** Follow requests across services and understand how they flow through your system.
- **Waterfall analysis:** Visualize request execution and identify slow operations, bottlenecks, and unexpected delays.
- **Performance analysis:** Analyze application performance in real time and quickly pinpoint areas that need optimization.
- **Metrics:** Track key application and infrastructure metrics to understand system health and performance trends.
- **Logging:** Centralize and correlate logs with traces and other telemetry to make debugging easier.
- **Error tracking:** Detect errors quickly and investigate their root causes with the surrounding context.
- **SLA monitoring:** Track service-level objectives and identify when your application is approaching or exceeding defined thresholds.
- **Alarms and alerts:** Set up alerts for critical errors, performance degradation, SLA violations, and other anomalies so your team can react quickly.

To add it to this project, run this and approve the code it prints at [observe.nestjs.com/link](https://observe.nestjs.com/link) - signing up for free if you have no account:

```bash
$ npx @nestjs/observe link
```

It installs `@nestjs/observe`, wires it into `AppModule` and `main.ts`, and writes the app key and secret into `.env`, which every `nest start` script (`start`, `start:dev`, `start:debug`) then loads. In production, set `OBSERVE_APP_KEY` and `OBSERVE_APP_SECRET` in the environment instead.

Or do it by hand:

```bash
$ npm install @nestjs/observe
```

Then follow the [setup guide](https://docs.nestjs.com/observability/sdk) - it takes a single import and an app key.

The free plan needs no payment details and covers 300,000 events a month. You can also browse the [live demo](https://www.observe-demo.nestjs.com/dashboard) first - the whole dashboard over a busy service's data, with nothing to install.

## Resources

Check out a few resources that may come in handy when working with NestJS:

- Visit the [NestJS Documentation](https://docs.nestjs.com) to learn more about the framework.
- For questions and support, please visit our [Discord channel](https://discord.gg/G7Qnnhy).
- To dive deeper and get more hands-on experience, check out our official video [courses](https://courses.nestjs.com/).
- Deploy your application to AWS with the help of [NestJS Mau](https://mau.nestjs.com) in just a few clicks.
- Auto-instrument your application with [NestJS Observe](https://observe.nestjs.com). Distributed tracing, metrics, and logging made easy. Error tracking and performance monitoring for your NestJS applications.
- Visualize your application graph and interact with the NestJS application in real-time using [NestJS Devtools](https://devtools.nestjs.com).
- Need help with your project (part-time to full-time)? Check out our official [enterprise support](https://enterprise.nestjs.com).
- To stay in the loop and get updates, follow us on [X](https://x.com/nestframework) and [LinkedIn](https://linkedin.com/company/nestjs).
- Looking for a job, or have a job to offer? Check out our official [Jobs board](https://jobs.nestjs.com).

## Support

Nest is an MIT-licensed open source project. It can grow thanks to the sponsors and support by the amazing backers. If you'd like to join them, please [read more here](https://docs.nestjs.com/support).

## Stay in touch

- Author - [Kamil Myśliwiec](https://twitter.com/kammysliwiec)
- Website - [https://nestjs.com](https://nestjs.com/)
- Twitter - [@nestframework](https://twitter.com/nestframework)

## License

Nest is [MIT licensed](https://github.com/nestjs/nest/blob/master/LICENSE).
