# Download Latest Task — Issue 2: Extend SAF Bridge for File Writing

## Feature

Extend the Android SAF MethodChannel bridge (built in the XCSoar SAF PoC) to support writing arbitrary file bytes, querying the stored directory URI, and clearing the stored permission. These are the primitives needed by the task download flow.

## Scope

Kotlin changes to `MainActivity.kt` and Dart changes to `lib/core/platform/xcsoar_saf_service.dart` only. No UI, no domain layer.

## Dependencies

Requires the SAF PoC (issue `20260330-xcsoar-saf-poc.md`, already done). Can be started immediately.

---

## Background

The existing SAF bridge (`xcsoar.saf` MethodChannel) supports one method: `tryWriteHelloFile`. We need three new generic operations:

| Method | Purpose |
|---|---|
| `writeFile` | Write arbitrary bytes to a named file in the stored SAF tree |
| `getSafDirectoryUri` | Return the stored tree URI string (for display in settings) |
| `clearSafPermission` | Remove the stored tree URI from SharedPreferences and release the persisted grant |

Read `docs/architecture.md` — Platform Services section — for the established bridge pattern.

---

## Tasks

### 1. Kotlin — `MainActivity.kt`

Add three new method handlers to the existing `MethodChannel` handler switch. All logic goes in the same class, following the existing pattern.

#### `writeFile`

```kotlin
"writeFile" -> {
    val bytes = call.argument<ByteArray>("bytes")!!
    val filename = call.argument<String>("filename")!!
    handleWriteFile(bytes, filename, result)
}
```

`handleWriteFile(bytes: ByteArray, filename: String, result: MethodChannel.Result)`:
- Read stored tree URI from SharedPreferences (`xcsoar_tree_uri`). If absent or no persisted grant, return `result.error("SAF_NOT_CONFIGURED", "XCSoar directory not set", null)`.
- Use the same delete-then-create pattern as `writeHelloFile`, but parameterised by `filename`.
- Write `bytes` to the new document's output stream.
- Return `result.success("ok")`.
- Wrap in try/catch; on exception return `result.error("SAF_ERROR", e.message, null)`.

#### `getSafDirectoryUri`

```kotlin
"getSafDirectoryUri" -> {
    val uri = getSharedPreferences("compman_prefs", Context.MODE_PRIVATE)
        .getString("xcsoar_tree_uri", null)
    result.success(uri)  // null if not set
}
```

#### `clearSafPermission`

```kotlin
"clearSafPermission" -> {
    val prefs = getSharedPreferences("compman_prefs", Context.MODE_PRIVATE)
    val stored = prefs.getString("xcsoar_tree_uri", null)
    if (stored != null) {
        val treeUri = Uri.parse(stored)
        try {
            contentResolver.releasePersistableUriPermission(
                treeUri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
            )
        } catch (_: SecurityException) { /* already released */ }
        prefs.edit().remove("xcsoar_tree_uri").apply()
    }
    result.success("ok")
}
```

### 2. Dart — `lib/core/platform/xcsoar_saf_service.dart`

Add three methods to `XcsoarSafService`:

```dart
/// Writes [bytes] to a file named [filename] in the stored XCSoar SAF directory.
///
/// Throws [PlatformException] with code `SAF_NOT_CONFIGURED` if no directory
/// has been granted yet, or `SAF_ERROR` on write failure.
Future<void> writeFile(Uint8List bytes, String filename) async {
  await _channel.invokeMethod<void>('writeFile', {
    'bytes': bytes,
    'filename': filename,
  });
}

/// Returns the stored SAF tree URI string, or null if not yet configured.
Future<String?> getSafDirectoryUri() =>
    _channel.invokeMethod<String>('getSafDirectoryUri');

/// Releases the stored SAF permission and clears the cached tree URI.
Future<void> clearSafPermission() =>
    _channel.invokeMethod<void>('clearSafPermission');
```

Import `dart:typed_data`. Add `///` doc comments.

---

## Acceptance Criteria

1. `make build` succeeds (Kotlin compiles).
2. `flutter analyze` passes.
3. `XcsoarSafService` exposes `writeFile`, `getSafDirectoryUri`, and `clearSafPermission`.
4. `getSafDirectoryUri()` returns null before any directory is granted, and the URI string after granting.
5. `clearSafPermission()` causes the next `writeFile` call to return a `SAF_NOT_CONFIGURED` error instead of writing.
6. `writeFile` correctly writes arbitrary bytes to the named file (verified manually on device or emulator).
7. `docs/plan.md` updated.
