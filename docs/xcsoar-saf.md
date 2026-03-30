# XCSoar SAF Integration

How to use Android's Storage Access Framework (SAF) to write `.cup`, `.txt`, and other data files into XCSoar's data directory without `MANAGE_EXTERNAL_STORAGE`.

## DocumentsProvider Details

| Property | Value |
|---|---|
| Authority | `org.xcsoar.allfiles` |
| Class | `org.xcsoar.AllFilesDocumentsProvider` |
| Exposed root | `getExternalFilesDir(null)` → `/sdcard/Android/data/org.xcsoar/files/` |
| Exported | `true` |
| Permission required | `android.permission.MANAGE_DOCUMENTS` (system permission, not enforced for SAF tree access) |

### Supported Operations

| Operation | Supported |
|---|---|
| List directory | ✅ |
| Create file | ✅ (`FLAG_DIR_SUPPORTS_CREATE`) |
| Create subdirectory | ✅ |
| Read file | ✅ |
| Write file | ✅ (`FLAG_SUPPORTS_WRITE`) |
| Delete | ✅ (`FLAG_SUPPORTS_DELETE`) |
| Rename | ✅ (`FLAG_SUPPORTS_RENAME`) |
| Search | ✅ (`FLAG_SUPPORTS_SEARCH`) |

### MIME Types Recognised

| Extension | MIME Type |
|---|---|
| `.cup` | `application/vnd.naviter.seeyou.cup` |
| `.igc` | `application/vnd.fai.igc` |
| `.wpt` | `application/vnd.oziexplorer.wpt` |
| `.gpx` | `application/gpx+xml` |
| other | `application/octet-stream` |

---

## Integration Steps

### Step 1 — One-time folder grant (user approves a system picker)

Launch `ACTION_OPEN_DOCUMENT_TREE` with an initial URI that pre-navigates to XCSoar's provider root:

```
content://org.xcsoar.allfiles/document/root:
```

The user sees the system file picker already open on XCSoar's data folder and taps **Allow**. Your app receives a persistent tree URI.

### Step 2 — Take persistent permission

```kotlin
contentResolver.takePersistableUriPermission(
    treeUri,
    Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
)
```

Persist `treeUri.toString()` to local storage (e.g. Hive) so the grant survives app restarts.

### Step 3 — Create and write a file

```kotlin
val childDocUri = DocumentsContract.buildChildDocumentsUriUsingTree(
    treeUri, DocumentsContract.getTreeDocumentId(treeUri)
)
val fileUri = DocumentsContract.createDocument(
    contentResolver,
    childDocUri,
    "application/vnd.naviter.seeyou.cup",  // or "text/plain" for .txt airspace
    "competition.cup"
)
contentResolver.openOutputStream(fileUri!!).use { stream ->
    stream!!.write(fileBytes)
}
```

### Flutter Integration

No pub.dev package handles SAF tree URIs natively. Requires a `MethodChannel` with a Kotlin bridge:

1. Dart side opens a channel and calls `openXCSoarFolder` / `writeXCSoarFile`
2. Kotlin side issues the `ACTION_OPEN_DOCUMENT_TREE` intent and handles `onActivityResult`
3. On result, Kotlin calls back to Dart with success/failure

---

## Important Caveat: Path Mismatch

XCSoar uses a **3-tier priority** for its data directory:

| Priority | Path | Condition |
|---|---|---|
| 1st | `/sdcard/Android/data/org.xcsoar/files/` | If `xcsoar.log` already exists there |
| 2nd | `/sdcard/Android/media/org.xcsoar/` | Preferred on Android 11+ |
| 3rd | `/sdcard/XCSoarData/` | Legacy fallback (Android ≤10) |

The SAF provider exposes Tier 1 (`Android/data/`). XCSoar only uses Tier 1 if `xcsoar.log` exists there — which it will after the user has run XCSoar at least once. On a fresh install, XCSoar may use Tier 2 instead and not see files written via SAF until it has been started once.

**In practice this is not a problem for active users** — `xcsoar.log` is created on first run.

---

## Source References (XCSoar repo)

- `android/src/AllFilesDocumentsProvider.java` — provider implementation
- `android/AndroidManifest.xml` lines 70–79 — provider registration
- `src/LocalPath.cpp` lines 115–160 — data directory resolution logic
