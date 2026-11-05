# SplitSum mobile

The app is a navigable Material 3 UI prototype with a teal theme:
welcome/account-layout switching, demo groups, participant management,
bill-entry layout, draft preview, and synthetic bill details.

Tap **Explore demo** to navigate. Demo groups/participants exist only in memory
and reset when leaving the demo. Credential fields are read-only; do not enter
real credentials. Bills are not saved, and draft shares are not calculated.
The example bill contains fixed synthetic shares, not live backend data.
Authentication and product API integration will follow in Stage 1.

Database readiness is a backend diagnostic, not a mobile product feature.
Use Postman to call `GET http://localhost:3000/health/ready` as described in the
[backend README](../backend/README.md).

## Run locally

From `mobile/`:

```bash
flutter pub get
flutter devices
flutter run
```

## Validation

```bash
flutter analyze
flutter test
```

Widget tests cover prototype screen navigation and input validation.
Real API access and persistence tests will be added with the manual workflow.

## Future API integration

Flutter will call NestJS, never PostgreSQL directly. Production APIs will use
HTTPS. Development configuration will account for Android emulators using
`10.0.2.2`, iOS simulators using the Mac's `localhost`, and physical devices
requiring a reachable backend host. Browser CORS and platform networking
permissions will be configured when product API integration is implemented.
