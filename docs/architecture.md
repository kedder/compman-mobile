# Architecture

Compman Mobile uses **Clean Architecture** with a **feature-based folder structure**. This keeps business logic independent of Flutter and the data layer, making the codebase easy to test, maintain, and extend by AI models.

---

## Layer Overview

```
┌─────────────────────────────────────────────┐
│              Presentation Layer             │
│   Flutter widgets, Riverpod providers       │
│   (lib/features/<feature>/presentation/)    │
└───────────────┬─────────────────────────────┘
                │  depends on
┌───────────────▼─────────────────────────────┐
│               Domain Layer                  │
│   Entities, repository interfaces,          │
│   use cases (pure Dart, no Flutter)         │
│   (lib/features/<feature>/domain/)          │
└───────────────▲─────────────────────────────┘
                │  implements
┌───────────────┴─────────────────────────────┐
│                Data Layer                   │
│   Repository implementations, data sources  │
│   (remote scrapers, local storage)          │
│   (lib/features/<feature>/data/)            │
└─────────────────────────────────────────────┘
```

**The dependency rule:** arrows point inward. `domain` has no dependencies on `data` or `presentation`. This is enforced by convention and verified in code review.

---

## Folder Structure

```
lib/
│
├── main.dart                        # Entry point: ProviderScope + runApp
├── app.dart                         # App widget: GoRouter configuration, MaterialApp
│
├── core/                            # Shared infrastructure (imported by all layers)
│   ├── di/
│   │   └── providers.dart           # Root Riverpod providers (Dio, Hive, etc.)
│   ├── error/
│   │   └── failures.dart            # Failure sealed class (freezed)
│   ├── network/
│   │   └── http_client.dart         # Dio instance configuration
│   ├── platform/                    # MethodChannel service classes (Android/iOS bridges)
│   └── theme/
│       └── app_theme.dart           # AppTheme factory + AppColors ThemeExtension
│
└── features/
    └── competitions/                # One folder per feature
        ├── domain/
        │   ├── entities/
        │   │   ├── competition.dart          # Competition (from SoaringSpot)
        │   │   └── bookmarked_competition.dart
        │   ├── repositories/
        │   │   └── competitions_repository.dart  # Abstract interface
        │   └── usecases/
        │       ├── fetch_competitions.dart
        │       ├── bookmark_competition.dart
        │       ├── remove_bookmark.dart
        │       └── get_bookmarked_competitions.dart
        │
        ├── data/
        │   ├── datasources/
        │   │   ├── soaringspot_remote_datasource.dart  # HTML scraping
        │   │   └── competitions_local_datasource.dart  # Hive storage
        │   ├── models/
        │   │   ├── competition_model.dart      # Parsed from HTML + toEntity()
        │   │   └── bookmarked_competition_model.dart  # Hive adapter
        │   └── repositories/
        │       └── competitions_repository_impl.dart
        │
        └── presentation/
            ├── providers/
            │   └── competitions_providers.dart  # Riverpod AsyncNotifiers
            ├── screens/
            │   ├── competition_list_screen.dart
            │   ├── bookmarks_screen.dart
            │   └── competition_detail_screen.dart
            └── widgets/
                ├── competition_card.dart
                └── bookmark_button.dart
```

New features follow the same pattern: create a new folder under `lib/features/<feature>/` with `domain/`, `data/`, and `presentation/` subfolders.

---

## Theme

All visual tokens live in `lib/core/theme/app_theme.dart`.

- `AppTheme.light()` returns the app's `ThemeData`, encoding all design tokens from `docs/ui-guidelines.md`.
- `AppColors` is a `ThemeExtension<AppColors>` carrying tokens that live outside standard `ColorScheme` / `ThemeData` slots (status badge colours, success snackbar colour).

**Rules:**
- Widgets must consume colours via `Theme.of(context).colorScheme` or `AppColors`.
- Hardcoded `Colors.*` values are not permitted in widget code except for transparent / black / white used as modifiers (e.g. shadow alpha).
- Access `AppColors` via the `BuildContext` extension: `context.appColors`.
- To add dark mode, add `AppTheme.dark()` in `app_theme.dart` — no widget code will need to change.

---

## UI Specification

The expected screens, user flows, visual states, and UX requirements are documented in **[docs/features/overview.md](features/overview.md)**. This is the authoritative reference for all presentation-layer work. When implementing or modifying any screen, read that document first.

---

## State Management

**Riverpod** (`flutter_riverpod`) is used throughout. Key conventions:

- **`AsyncNotifier`** for data that involves async loading (e.g., fetching competitions).
- **`Notifier`** for synchronous state (e.g., filter selections).
- Providers are defined in `features/<feature>/presentation/providers/`.
- Use cases are injected into providers via Riverpod's `ref.read(...)`.

Example flow:
```
Screen (ConsumerWidget)
  └─ watches competitionListProvider (AsyncNotifier)
       └─ calls FetchCompetitions use case
            └─ calls CompetitionsRepository interface
                 └─ implemented by CompetitionsRepositoryImpl
                      ├─ SoaringSpotRemoteDataSource (Dio + HTML parsing)
                      └─ CompetitionsLocalDataSource (Hive)
```

---

## Error Handling

All repository methods return `Either<Failure, T>` (using the `fpdart` package or a simple sealed class). Failures are domain-level — they describe *what went wrong* without leaking implementation details (e.g., `NetworkFailure`, `ParseFailure`, `StorageFailure`).

Providers translate failures into `AsyncError` states, which screens display as error messages with retry options.

---

## Local Storage

**Hive** is used for persisting bookmarked competitions. It is fast, requires no schema migrations for this use case, and works well with Flutter. Each feature that needs persistence defines its own Hive box name constant in the `data/datasources/` layer.

---

## Platform Services

`lib/core/platform/` contains Dart-side `MethodChannel` service classes that wrap Android (and future iOS) platform APIs. These classes are plain Dart — no Riverpod providers, no domain entities.

**Dependency rule:** platform services may be imported by the presentation layer and by other `core/` modules. They must not import from any feature's `domain/` or `data/` layer.

**Android bridge pattern:** The Kotlin implementation lives in `MainActivity.kt`. For operations that require an `Activity` result (e.g. SAF document tree picker), register an `ActivityResultLauncher` in `configureFlutterEngine` and store a `pendingResult: MethodChannel.Result?` field to bridge the async gap between the method call and the launcher callback:

```kotlin
override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    safLauncher = registerForActivityResult(ActivityResultContracts.OpenDocumentTree()) { uri ->
        // persist the selected tree URI and resolve pendingResult here
    }
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "xcsoar.saf")
        .setMethodCallHandler { call, result -> /* for pickDirectory, store result as pendingResult and launch */ }
}
```

**Tree URI persistence:** SAF tree URI grants are stored in Android `SharedPreferences` (not Hive) because they must be accessible from Kotlin before Flutter initialises.

---

## Navigation

**go_router** handles navigation. Routes are defined in `app.dart`. Named routes are used throughout to avoid hardcoded strings.

Current routes (Phase 1):
| Name | Path | Screen |
|---|---|---|
| `competitions` | `/` | Competition list |
| `competitionDetail` | `/competitions/:id` | Competition detail |
| `bookmarks` | `/bookmarks` | Bookmarked competitions |

The app uses a bottom navigation shell route (`ShellRoute`) to keep the bottom nav bar persistent across the two main tabs.

---

## Adding a New Feature

1. Create `lib/features/<feature>/domain/`, `data/`, `presentation/` folders.
2. Define entities in `domain/entities/`.
3. Define repository interface in `domain/repositories/`.
4. Define use cases in `domain/usecases/`.
5. Implement repository and data sources in `data/`.
6. Add Riverpod providers in `presentation/providers/`.
7. Add screens and widgets in `presentation/screens/` and `presentation/widgets/`.
8. Register new routes in `app.dart`.
9. Create `docs/features/<feature>.md` documenting the feature.
10. Update `docs/plan.md` to mark the feature as done.
