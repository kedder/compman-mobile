# XCSoar XCTrack Task URI (`xctsk:`)

XCSoar registers an intent filter for the `xctsk:` URI scheme, allowing another app to send a competition task directly to XCSoar. The user is prompted to save it.

## How It Works

XCSoar's `ReceiveTaskActivity` receives `ACTION_VIEW` intents with the `xctsk:` scheme. It strips the 6-character prefix and passes the remainder directly to `boost::json::parse()` → `DecodeXCTrackTask()`.

Triggering from your app requires **no special permissions** — it is a standard implicit intent.

---

## URI Format

```
xctsk:<json-body>
```

The JSON body is inlined directly — no `//` host, no URL encoding of the body, no Base64. Example:

```
xctsk:{"taskType":"CLASSIC","version":2,"t":[...]}
```

> XCSoar **only accepts `version: 2`** (the compact QR format). Version 1 is rejected with "Unsupported XCTrack task format version".

---

## JSON Schema (version 2)

```json
{
  "taskType": "CLASSIC",
  "version": 2,
  "e": 0,
  "t": [
    {
      "z": "<polyline-encoded string>",
      "n": "Turnpoint Name",
      "d": "optional description",
      "t": 2
    }
  ],
  "s": {
    "t": 1,
    "g": ["12:00:00Z"],
    "d": 1
  },
  "g": {
    "t": 2,
    "d": "19:00:00Z"
  }
}
```

### Root Fields

| Field | Type | Required | Notes |
|---|---|---|---|
| `taskType` | string | ✅ | Must be `"CLASSIC"` |
| `version` | number | ✅ | Must be `2` |
| `e` | number | optional | `0` = WGS84 (default), `1` = FAI sphere. XCSoar **rejects** anything but `0` |
| `t` | array | ✅ | Turnpoints. First = Start, last = Finish, middle = AST |
| `s` | object | optional | Start settings |
| `g` | object | optional | Goal settings |

### Turnpoint Fields (`t[i]`)

| Field | Type | Required | Notes |
|---|---|---|---|
| `z` | string | ✅ | Polyline-encoded lon, lat, altitude (m AMSL), radius (m) |
| `n` | string | ✅ | Waypoint name — must be non-empty |
| `d` | string | optional | Description |
| `t` | number | optional | `2` = SSS (start), `3` = ESS |

### Start Fields (`s`)

| Field | Type | Notes |
|---|---|---|
| `t` | number | `1` = RACE, `2` = ELAPSED-TIME |
| `g` | array | Start gate times: `["HH:MM:SSZ", ...]` |
| `d` | number | `1` = ENTRY, `2` = EXIT (obsolete, include for compatibility) |

### Goal Fields (`g`)

| Field | Type | Notes |
|---|---|---|
| `t` | number | `1` = LINE, `2` = CYLINDER (default) |
| `d` | string | Deadline time, e.g. `"19:00:00Z"` |
| `fa` | number | Finish altitude in metres AGL (optional) |

### Time Format

All times are UTC, 9 characters: `"HH:MM:SSZ"`. The trailing `Z` is a reminder that times are UTC.

---

## The `z` Polyline Encoding

Each turnpoint's `z` field is **4 Google Polyline-encoded integers** concatenated:

```
z = encode(longitude) + encode(latitude) + encode(altitude_m) + encode(radius_m)
```

> ⚠️ Order is **longitude first**, then latitude — the reverse of standard Google Polyline (which is lat, lon).

**Google Polyline encoding steps for a single integer:**
1. Multiply by `1e5`, round to integer
2. Left-shift by 1
3. If negative, invert all bits
4. Split into 5-bit chunks, set the continuation bit (`0x20`) on all but the last
5. Add offset 63 to each chunk and emit as a character

**Validity constraints (XCSoar rejects out-of-range values):**
- altitude: −1000 to 9000 m
- radius: 1 to 500 000 m

**Example** — lat=47.1000, lon=11.3000, alt=900 m, radius=500 m:
- lon=11.3 → `11.3 × 1e5 = 1130000`
- lat=47.1 → `47.1 × 1e5 = 4710000`
- alt=900, radius=500

Use a standard Google Polyline library to encode these four values.

---

## Examples

### Minimal task (start + finish only)

```
xctsk:{"taskType":"CLASSIC","version":2,"t":[{"z":"<start_z>","n":"Start","t":2},{"z":"<goal_z>","n":"Goal"}]}
```

### Full competition task (start gate, AST, goal line)

```json
{
  "taskType": "CLASSIC",
  "version": 2,
  "e": 0,
  "t": [
    { "z": "<start_z>", "n": "StartPoint", "t": 2 },
    { "z": "<tp1_z>",   "n": "Turnpoint1" },
    { "z": "<tp2_z>",   "n": "Turnpoint2" },
    { "z": "<goal_z>",  "n": "GoalCylinder" }
  ],
  "s": {
    "t": 1,
    "g": ["13:00:00Z"],
    "d": 2
  },
  "g": {
    "t": 2,
    "d": "20:00:00Z"
  }
}
```

Prefix the minified JSON with `xctsk:` to form the full URI.

---

## Firing the Intent from Flutter

Using `url_launcher` (simplest approach, no permissions needed):

```dart
final uri = Uri.parse('xctsk:${jsonEncode(taskBody)}');
await launchUrl(uri);
```

Or via a `MethodChannel` / Kotlin bridge if you need result handling:

```kotlin
val intent = Intent(Intent.ACTION_VIEW, Uri.parse("xctsk:$json"))
startActivity(intent)
```

> **Note:** XCSoar opens with the task displayed in the task manager and prompts the user to save it. The transfer is **not silent** — user interaction is required to persist the task.

---

## Source References (XCSoar repo)

- `android/src/ReceiveTaskActivity.java` — receives intent, strips `xctsk:` prefix
- `android/src/NativeView.java` — `onReceiveXCTrackTask(String data)` native declaration
- `src/Android/ReceiveTask.cpp` — parses JSON, creates `OrderedTask`, fires `TASK_RECEIVED` event
- `src/Task/XCTrackTaskDecoder.cpp` — full JSON decoder (validates `taskType`, `version`, `e`; decodes `z` fields)
- `src/Task/PolylineDecoder.cpp` — Google Polyline decoder (lon-first variant)
- `android/AndroidManifest.xml` lines 55–64 — `ReceiveTaskActivity` intent filter for `xctsk:` scheme
- Official spec: https://xctrack.org/Competition_Interfaces.html
