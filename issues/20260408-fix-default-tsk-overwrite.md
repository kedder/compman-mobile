# Fix: Overwrite Default.tsk Instead of Creating a Duplicate

## Feature Summary

The "Install as XCSoar Default Task" button writes a `Default.tsk` file into the
user's XCSoar SAF folder via the Kotlin `handleWriteFile` method in `MainActivity.kt`.
XCSoar only recognises `Default.tsk` as the default task; any other name (e.g.
`Default (1).tsk`) is ignored.

## Problem

`handleWriteFile` currently uses a **delete-then-create** strategy:

1. Query the folder for an existing document whose display name matches `filename`.
2. Delete it with `DocumentsContract.deleteDocument`.
3. Create a fresh document with `DocumentsContract.createDocument`.

When step 2 silently fails — for example because the cursor is `null`, the query
returns no rows, or `deleteDocument` returns `false` — step 3 creates a second
file. The Android SAF provider deduplicates the name by appending ` (1)`, resulting
in `Default (1).tsk`. XCSoar never picks up this file.

## Task

Replace the delete-then-create pattern in `handleWriteFile` with an
**overwrite-if-exists, create-if-new** strategy:

1. Query the child documents URI for an existing document matching `filename`
   (same query as today).
2. **If found**: open its output stream with mode `"rwt"` (read-write-truncate)
   via `contentResolver.openOutputStream(existingDocUri, "rwt")` and write the
   bytes directly — no delete, no create.
3. **If not found**: call `DocumentsContract.createDocument` as today, then write
   to the returned URI.

This guarantees that when `Default.tsk` already exists, its content is replaced
in-place rather than a sibling file being created.

## Files to Read

- `android/app/src/main/kotlin/lt/lebedev/compman_mobile/MainActivity.kt` —
  `handleWriteFile` (~line 98) and `writeHelloFile` (~line 150) for the existing
  pattern; only `handleWriteFile` needs to change.
- `lib/core/platform/xcsoar_saf_service.dart` — Dart wrapper (no changes needed
  unless you find the layer needs an update).
- `CLAUDE.md` — project rules.

## Acceptance Criteria

- Tapping "Install as XCSoar Default Task" a **second** time (when `Default.tsk`
  already exists in the folder) replaces the file in place; no `Default (1).tsk`
  is created.
- Tapping for the **first** time (no previous file) still creates `Default.tsk`
  successfully.
- Existing unit tests pass (`make test`). No new tests are required for this
  Kotlin-only change unless a test scaffold already exists for the SAF bridge.
- `make analyze` reports no new warnings.
