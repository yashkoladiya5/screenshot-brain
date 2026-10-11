# Screenshot Brain

An offline-first Android/iOS app that reads your screenshot gallery, runs OCR on
every screenshot **on-device**, sorts it into categories, pulls structured
expenses out of payment receipts, and makes all of it searchable.

No network, no accounts, no cloud: `google_mlkit_text_recognition` does the
reading, Isar is the only store, and everything the app knows comes from text
that never leaves the phone.

Feature-level detail (every service, rule and screen) lives in
[`docs/APP_DOCUMENTATION.md`](docs/APP_DOCUMENTATION.md). This file is the
working overview: what the app does, how the code is laid out, and how to build
and test it.

## What it does

- **Gallery scan** — walks screenshot albums through `photo_manager`, paginated
  (100 assets per page), deduplicated by asset id and path, newest first, with
  already-persisted paths filtered out before any file is resolved.
- **OCR** — ML Kit text recognition per file; a screenshot that fails OCR is
  still imported and stays in the unprocessed queue.
- **Categorization** — weighted-keyword scoring over 10 categories
  (`Payments`, `UPI Receipts`, `Shopping`, `Travel Tickets`, `Bills`,
  `Documents`, `OTP Screenshots`, `Addresses`, `Notes`, `Social Media`, plus
  `Other`) with a confidence threshold and a fixed tie-break priority.
- **Expense tracking** — expense cues decide whether a screenshot is a payment;
  amount (multi-currency token aware), merchant and date are extracted into an
  `ExpenseModel`. The dashboard shows totals, month series, category shares,
  top merchants and spending streaks.
- **Search** — debounced full-text search over extracted text, category and
  file path, with suggestion chips.
- **Browse** — home dashboard, screenshot grid with category filter chips,
  detail view with expandable OCR text, full-screen viewer, category buckets.
- **Settings** — theme mode, auto-scan toggle, Wi-Fi-only OCR flag, scan
  interval (6/12/24/48/72 hours).
- **Permissions** — explicit gallery permission state machine
  (`granted`/`limited`/`denied`/`permanentlyDenied`/`error`) with per-state
  purpose copy and an "open system settings" escape hatch.

## Tech stack

| Concern | Choice |
| --- | --- |
| UI | Flutter (Material 3), `lib/core/theme` light/dark themes, `lib/core/design/tokens.dart` spacing/radius/z scales |
| State / DI | `flutter_riverpod` 2 — `Provider`, `FutureProvider`, `FutureProvider.family`, `StateProvider`, `AsyncNotifierProvider` |
| Routing | `go_router` 14, single `AppRouter.router`, `errorBuilder` fallback |
| Persistence | Isar 3 — two collections, `ScreenshotModel` and `ExpenseModel` |
| OCR | `google_mlkit_text_recognition` (on-device text recognizer) |
| Gallery / permissions | `photo_manager`, `permission_handler` |
| Formatting | `intl` — dates via `DateTimeExtensions`, money via the `en_IN`/₹ formats in `ExpenseItem` |
| Misc | `path_provider`, `image_picker`, `share_plus` |

Dart SDK `^3.10.3`. Lints come from `flutter_lints` via `analysis_options.yaml`.

## Layout

```
lib/
  main.dart            runZonedGuarded bootstrap; FlutterError/PlatformDispatcher
                       hooks; DatabaseService.init() before runApp (non-fatal)
  app.dart             ScreenshotBrainApp: MaterialApp.router + themeMode from settings
  core/
    router/            GoRouter configuration and route table
    theme/, design/     themes and design tokens
    widgets/           LoadingWidget, AppErrorWidget, EmptyStateWidget
    utils/             extensions (date, string, int, num, file size, color…),
                       DateUtils, validators, platform/theme utils, constants
    components/        the `sb_*` custom widget library
  features/<slice>/
    screens/           one Consumer(State)Widget per route
    providers/         Riverpod wiring for the slice
    repositories/      Isar queries, model -> view-model mapping
    models/            slice-facing view models
  services/            DatabaseService, OcrService, ScreenshotScannerService,
                       CategorizationService, ExpenseExtractionService,
                       PermissionService, AnalyticsService
  shared/models/       Isar collections (+ committed *.g.dart) and the richer
                       ScreenshotItem / ExpenseItem view models
```

Feature slices: `screenshots`, `expenses`, `categories`, `search`, `home`,
`permissions`, `settings`, `splash`.

## The scan pipeline

`ScanScreenshotsNotifier.scan()` (`lib/features/screenshots/providers/`) is the
only writer into the screenshot table from a gallery scan:

1. **Ready guard** — if `DatabaseService.isInitialized` is false the scan aborts
   immediately instead of letting the `DatabaseService.db` getter throw.
2. `scanningProvider` flips to `true` (the UI disables the FAB and shows a
   spinner).
3. Already-persisted paths are collected and handed to
   `ScreenshotScannerService.scanScreenshots(knownPaths: …)`.
4. One `OcrService` is created for the whole batch.
5. Per file: stat → duplicate check → insert `ScreenshotModel` (via
   `ScreenshotRepository.saveScreenshot`) → OCR → `updateExtractedText` →
   `updateCategory` → if `CategorizationService.isExpense`, `markAsExpense` plus
   an `ExpenseModel` write inside `writeTxn`.
6. Errors are isolated twice: a throwing file is logged, counted and skipped;
   an OCR/categorization failure keeps the row (still `isProcessed == false`) so
   a later scan retries it.
7. `screenshotListProvider` and `homeStatsProvider` are invalidated only when
   something was actually inserted.
8. `finally` disposes the ML Kit recognizer **and** resets `scanningProvider`,
   on every exit path including a failed scan.

Auto-scan rides on top of this: `ScanScreenshotsNotifier.scanIfDue()` reads
`settingsProvider` and runs `scan()` only when the pure `isAutoScanDue` gate
says so — `autoScanEnabled` on, no stamp yet (or the clock went backwards),
and at least `scanIntervalHours` elapsed since the notifier's last accepted
pass. The stamp is kept in the notifier, so a disabled setting never stamps
and back-to-back calls within the interval are no-ops.

## Providers worth knowing

| Provider | Kind | Purpose |
| --- | --- | --- |
| `screenshotRepositoryProvider` | `Provider` | injectable `ScreenshotRepository`; overridden wholesale in tests |
| `screenshotListProvider` | `FutureProvider<List<ScreenshotItem>>` | grid source |
| `screenshotDetailProvider(id)` | `FutureProvider.family` | single screenshot |
| `searchScreenshotsProvider(query)` | `FutureProvider.family` | ad-hoc query |
| `scanScreenshotsProvider` | `AsyncNotifierProvider<ScanScreenshotsNotifier, void>` | the scan; `state` carries `AsyncData`/`AsyncError`; `scanIfDue()` applies the settings cadence |
| `deleteScreenshotProvider(id)` | `FutureProvider.family` | cascade delete (expenses first, then row) |
| `scanningProvider` | `StateProvider<bool>` | busy flag |
| `homeStatsProvider`, `screenshotCountProvider`, `unprocessedCountProvider` | `FutureProvider` | dashboard snapshot |
| `expenseListProvider`, `expenseSnapshotProvider`, `expenseTotalProvider`, `expenseMonthlyTotalProvider`, `expenseByCategoryProvider`, `recentExpensesProvider`, `expenseSearchResultsProvider` | `FutureProvider` | money views |
| `categoryListProvider`, `categoryCountsProvider`, `screenshotsByCategoryProvider(name)` | mixed | category buckets |
| `searchQueryProvider`, `searchResultsProvider`, `searchSuggestionsProvider` | mixed | debounced search |
| `settingsProvider`, `themeModeProvider` | `StateNotifier`/derived | user preferences |

## Conventions

- **One DateTime extension.** `DateTimeExtensions` in `core/utils/date_extensions.dart`
  is the single home for date predicates and formatting (`toRelativeString`
  returns `Today at 4:30 PM`, `toStandardFormat`, `toCompactFormat`,
  `toTimeString`, `formatted`, `formattedWithTime`, `monthYear`, `isSameDayAs`,
  plus reference-pinned variants). `core/utils/extensions.dart` is a real barrel
  (`export`s) so no import site ever sees two competing extensions on `DateTime`.
- **Money is Indian-formatted.** `₹1,29,900.00` comes from
  `NumberFormat.currency(locale: 'en_IN', …)` (lakh/crore grouping is a property
  of the `en_IN` pattern, not a hand-rolled regex). `null` amounts render as
  `N/A`, never as an empty string.
- **View models are pure.** `ScreenshotItem` / `ExpenseItem` expose `fromModel`,
  `copyWith`, value equality, derived status enums (`ScreenshotStatus`,
  `ExpenseStatus`) and display getters; no Isar or `dart:io` in their render
  paths, so they are safe in widget tests.
- **Isar schemas are committed.** `*.g.dart` under `shared/models/` is checked
  in and the collection classes (`@collection`) are not to be edited casually:
  changing a field means regenerating with `build_runner` and migrating, which
  is deliberately outside the normal workflow.
- **Logging** is `debugPrint` with a `[LayerName]` prefix (`[ScanNotifier]`,
  `[ScreenshotRepo]`, `[ScannerService]`, …).
- **Errors are reported, not swallowed silently** at the boundary: services
  return typed results (`GalleryPermissionResult`, `ScanOutcome`), providers
  surface `AsyncError`, and the widget layer renders `AppErrorWidget` with retry.

## Getting a build

```bash
flutter pub get
flutter run            # a physical Android/iOS device or a real iOS simulator
```

ML Kit and `photo_manager` need a real device: OCR and gallery access do not
work on desktop/web. Android declares `READ_MEDIA_IMAGES` plus the legacy
storage permissions; iOS declares `NSPhotoLibraryUsageDescription` in
`ios/Runner/Info.plist`.

## Tests

```bash
flutter test                       # whole suite
flutter test test/models test/providers   # view models + provider seams
flutter test test/services/categorization_service_test.dart
dart analyze lib test              # must stay error-free
```

Layout: `test/components` (widget physics/geometry), `test/core` (router, theme,
color utils), `test/models` (view-model factories and formatting),
`test/providers` (Riverpod wiring), `test/repositories`, `test/screens`,
`test/services`, `test/utils`, `test/widgets`.

Unit tests avoid the native layers by design:

- `DatabaseService.db` throws until `init()` runs, so no test opens Isar.
  Repositories are replaced with `implements`-based fakes (which skip the
  `final Isar db = DatabaseService.db` field initializer) and injected through
  `screenshotRepositoryProvider.overrideWithValue`.
- Decision logic is kept in pure, `@visibleForTesting` seams —
  `knownFilePaths`, `filesNotIn`, `newScreenshotModel`, `ScanOutcome`,
  `isAutoScanDue`,
  `CategorizationService.categorize`, `ExpenseExtractionService.extractAmount`,
  `ScreenshotScannerService.selectNewAssets`/`filterDateWindow` — so behaviour
  is asserted without photo_manager or ML Kit bindings.
- Date-sensitive expectations pass an explicit `reference:` clock and use
  `DateTime.utc`, so nothing depends on the host timezone or the wall clock.
- Screens that fire a scan are tested with a `ScanScreenshotsNotifier` subclass
  overriding `Future<void> scan()`; that signature is part of the provider's API.
