# XCSoar SAF Integration — Proof of Concept

## Feature

Integrate Android's Storage Access Framework (SAF) to write files into XCSoar's data directory. This PoC establishes the **reference implementation** for all future SAF-based file delivery features (waypoints, airspace, etc.).

**This ticket** delivers a "Try SAF" menu item on the home screen that, when tapped, asks the user to grant folder access to XCSoar's data directory (once), then writes a `hello-from-compman.txt` file into it.

Read `docs/xcsoar-saf.md` before starting — it documents the XCSoar `DocumentsProvider` authority, supported operations, and the Flutter integration approach.

---

## Context

- `lib/app.dart` — GoRouter config; add a `/saf-test` route here
- `lib/features/competitions/presentation/screens/bookmarks_screen.dart` — home screen; replace the `more_vert` `IconButton` with a `PopupMenuButton`
- `android/app/src/main/kotlin/lt/lebedev/compman_mobile/MainActivity.kt` — currently an empty `FlutterActivity` stub; add the Kotlin bridge here
- `android/app/src/main/AndroidManifest.xml` — no new permissions needed (SAF is intent-based)
- `docs/xcsoar-saf.md` — integration reference

Architecture constraint: this is platform infrastructure. It lives under `lib/core/platform/` and does **not** involve the domain layer.

---

## Tasks

### 1. Kotlin bridge — `MainActivity.kt`

Implement a `MethodChannel` named `xcsoar.saf` with one method: `tryWriteHelloFile`.

**Use `ActivityResultLauncher` (not the deprecated `onActivityResult`).** This is the reference pattern for all future SAF work in this project.

The method must:

1. Check `SharedPreferences` (key `xcsoar_tree_uri`) for a previously stored tree URI. If one exists, verify it still has a persisted read+write grant via `contentResolver.persistedUriPermissions`. If valid, skip the picker and go straight to writing.
2. If no valid URI: launch the registered `ActivityResultLauncher<Uri?>` with hint URI `Uri.parse("content://org.xcsoar.allfiles/document/root:")`, and hold the `MethodChannel.Result` reference in a `pendingResult` field for the async callback.
3. In the launcher callback:
   - If the result URI is null (user cancelled): invoke `result.success("cancelled")` and return.
   - Call `contentResolver.takePersistableUriPermission(treeUri, FLAG_GRANT_READ_URI_PERMISSION or FLAG_GRANT_WRITE_URI_PERMISSION)`.
   - Persist `treeUri.toString()` to `SharedPreferences`.
   - Proceed to write the file.
4. Write the file (shared logic for both cached-URI and new-URI paths):
   - Build the child documents URI: `DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, DocumentsContract.getTreeDocumentId(treeUri))`
   - **Overwrite if existing**: query the child documents URI for a document named `hello-from-compman.txt` (projection `[DocumentsContract.Document.COLUMN_DOCUMENT_ID]`, selection `"${DocumentsContract.Document.COLUMN_DISPLAY_NAME} = ?"`, selectionArgs `["hello-from-compman.txt"]`). If a match is found, call `DocumentsContract.deleteDocument(contentResolver, existingDocUri)`.
   - Create the document: `DocumentsContract.createDocument(contentResolver, childDocUri, "text/plain", "hello-from-compman.txt")`
   - Write content: `contentResolver.openOutputStream(fileUri!!).use { it!!.write("Hello from Compman Mobile!".toByteArray()) }`
   - Invoke `result.success("ok")`.
5. Wrap the entire file-write block in a try/catch; on exception invoke `result.error("SAF_ERROR", e.message, null)`.

**Launcher registration:** `ActivityResultLauncher` must be registered before the activity starts. Declare it as a `lateinit var` field and register it in `configureFlutterEngine` (or `onCreate`) using `registerForActivityResult(ActivityResultContracts.OpenDocumentTree()) { uri -> ... }`. Hold a `private var pendingResult: MethodChannel.Result? = null` field to bridge the async gap.

### 2. Dart platform service — `lib/core/platform/xcsoar_saf_service.dart`

Create class `XcsoarSafService` with:
- `static const _channel = MethodChannel('xcsoar.saf')`
- `Future<String> tryWriteHelloFile()` — calls `_channel.invokeMethod<String>('tryWriteHelloFile')`, returns the result string, re-throws `PlatformException` on error

Add `///` doc comments to the class and method.

### 3. SAF test screen — `lib/core/platform/saf_test_screen.dart`

Create `SafTestScreen` (`ConsumerStatefulWidget`):

- `AppBar` titled `"Try SAF"`
- Body: centered `Column` with:
  - Descriptive text: `"Writes hello-from-compman.txt into XCSoar's data folder."`
  - `ElevatedButton` labelled `"Write file to XCSoar"` — calls `XcsoarSafService().tryWriteHelloFile()`
  - While the future is running: show a `CircularProgressIndicator` in place of the button
  - On success: show a green `SnackBar` with the result string
  - On `PlatformException`: show a red `SnackBar` with the error message

Add `///` doc comments to the class.

### 4. Router — `lib/app.dart`

Add a `GoRoute` for path `/saf-test` that builds `SafTestScreen()`.

### 5. Home screen menu — `bookmarks_screen.dart`

Replace the `IconButton(icon: Icon(Icons.more_vert), ...)` in `BookmarksScreen`'s `AppBar.actions` with a `PopupMenuButton<String>`:
- Item `"Try SAF"` → `context.push('/saf-test')`
- Item `"About"` → `context.push('/about')`

---

## Acceptance Criteria

1. `make build` succeeds with no errors.
2. `make analyze` passes with no issues.
3. Tapping the three-dot icon on the home screen shows a popup with "Try SAF" and "About".
4. First use: tapping "Write file to XCSoar" opens the system SAF folder picker pre-navigated to XCSoar's data folder; after the user taps Allow, a green snackbar confirms success.
5. Second use: tapping "Write file to XCSoar" again writes the file without re-showing the picker (tree URI is cached in `SharedPreferences`).
6. If `hello-from-compman.txt` already exists it is replaced — no duplicate files.
7. The file is present at `/sdcard/Android/data/org.xcsoar/files/hello-from-compman.txt` and contains `Hello from Compman Mobile!`.

---

Do not add widget tests — this is a PoC.
Do not update documentation files.
