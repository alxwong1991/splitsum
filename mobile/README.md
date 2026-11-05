# SplitSum mobile

The app currently displays the Flutter starter counter screen.
Authentication and the manual bill workflow will be added incrementally.
There is no mobile API integration yet.

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

The current widget test covers the starter counter behavior. Product forms,
API access, and their tests will be added with the manual workflow.

## Future API integration

Flutter will call NestJS, never PostgreSQL directly. Production APIs will use
HTTPS. Development configuration will account for Android emulators using
`10.0.2.2`, iOS simulators using the Mac's `localhost`, and physical devices
requiring a reachable backend host. Browser CORS and platform networking
permissions will be configured when product API integration is implemented.
