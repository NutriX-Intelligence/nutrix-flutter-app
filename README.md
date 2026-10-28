# NutriX Flutter app

Android app for NutriX (smart-scale food logging, recipes, fast food, meal planning, AI coach).
Flutter 3.44 / Dart ^3.12, Riverpod, GoRouter, Dio.

## Backend
The app talks to the NutriX API gateway, always under `/api/v1`. Set the address when building:

```
flutter pub get
flutter run --dart-define=API_BASE_URL=https://<your-backend>
flutter build apk --release --split-per-abi --dart-define=API_BASE_URL=https://<your-backend>
```

Without `--dart-define` the default in `lib/core/api/api_endpoints.dart` is used. The address can also be
changed at runtime from the login screen (useful while the backend is behind a temporary tunnel).
Test account: see the backend hand-off (`dev@nutrix.dev`).

## Notes
- Every call carries the login token; a 401 signs the user out (`lib/core/api/api_client.dart`).
- "Today" is decided by the server: the app sends no date for today, and an explicit date only for a day the user picks.
- Android native code is in `android/app/src/main/kotlin` (MainActivity and the three home-screen widget providers).
- Release builds are signed with the debug key; add your own signing config for a store release.
