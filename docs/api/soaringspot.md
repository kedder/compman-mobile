# SoaringSpot Data Source

Compman Mobile fetches competition data by scraping HTML from [https://www.soaringspot.com](https://www.soaringspot.com). See [ADR 003](../adr/003-html-scraping.md) for the rationale.

---

## Competition Listing

**URL:** `https://www.soaringspot.com`

The homepage lists all current and recent competitions. Each competition is represented as:

```html
<div class="contest">
  <h3>
    <a href="/en/contest/barron-2024">Barron 2024</a>
  </h3>
  <div class="info">
    2024-01-15 to 2024-01-21 · Barron, Australia
  </div>
</div>
```

### Parsed Fields

| Field | Source | Notes |
|---|---|---|
| `id` | Last non-empty path segment of `<a href>` | Trailing slash stripped; e.g. `/en_gb/barron-2024/` → `"barron-2024"` |
| `title` | Text content of `<a>` inside `<h3>` | Trimmed |
| `url` | `https://www.soaringspot.com` + `href` | `href` is always relative on soaringspot.com |
| `description` | Text content of `.info` element | Whitespace-normalised: collapse `\s+` to single space, trim |
| `startDate` | First date in `.info > span` | Parsed from `d MMMM yyyy` before the en dash |
| `endDate` | Second date in `.info > span` | Parsed from `d MMMM yyyy` after the en dash |

The listing markup mixes location text, icon text, and date text inside the same `<span>`. The scraper normalises whitespace, finds the final `–` separator, parses the right-hand side as `endDate`, and extracts the trailing `d MMMM yyyy` pattern from the left-hand side as `startDate`. If parsing fails, both dates remain `null` and downstream status stays unknown.

### Selector Note

Use `.contest` (any element with that class), not `div.contest` specifically. In Dart: `document.querySelectorAll('.contest')`. Malformed entries (missing `<h3><a>`) are skipped silently. An empty result list is not an error.

### Implementation File

`lib/features/competitions/data/datasources/soaringspot_remote_datasource.dart`

---

## Testing: HTML Snapshot

Scraper tests use a **committed snapshot** of the real soaringspot.com homepage rather than hand-crafted fixture HTML. This means tests exercise real-world markup and failures are easy to diagnose.

**No network access during `flutter test`.** The snapshot is read from disk by model tests, and injected as a string via a mocked `Dio` in datasource tests. The live site is never contacted during automated test runs.

**Snapshot location:** `test/fixtures/soaringspot_home.html`

**Assertions** are intentionally loose (non-empty strings, URL prefix checks) so they don't break just because the competition list changes between snapshot refreshes.

### Refreshing the snapshot

Run this command manually when the site structure changes and tests break:

```bash
curl -L -A "Mozilla/5.0" https://www.soaringspot.com/ -o test/fixtures/soaringspot_home.html
```

Then re-run the tests. If assertions fail, adjust them to match the new structure (or fix the scraper if the HTML changed fundamentally). Commit the updated snapshot together with any code/test changes.

---

## Competition Downloads

**URL:** `{competition_url}/downloads`

Each category (Airspaces, Waypoints) renders two sibling elements with the
same class `contest-downloads` — a `<div>` (timestamp info) followed by a
`<ul>` (file list):

```html
<h3>Airspaces</h3>
<div class="contest-downloads">
    wgc2018_airspace_v5.1.cub
    <span>Updated:</span>
    <span>10/07/2018, 17:44</span>   <!-- publishedVersion -->
</div>
<ul class="contest-downloads">
    <li>
        <a href="https://archive.soaringspot.com/contest/026/2614/airspace/11439.txt">
            <i class="fa fa-download"></i> wgc2018_airspace_v5.1_openair.txt
        </a>
        (134.831 kB)   <!-- fileSize text -->
    </li>
</ul>
```

### Scraping strategy

The scraper (`fetchDownloads` on `SoaringSpotRemoteDataSourceImpl`) queries
all `.contest-downloads` elements in document order. A `div` element carries
the timestamp for the subsequent file group; a `ul` element contains the
actual file links. The last seen timestamp is applied to every file in the
following `ul`.

**Timestamp (`publishedVersion`):** The raw text of the **second `<span>`**
inside `div.contest-downloads` (e.g. `"10/07/2018, 17:44"`). Stored as an
opaque `String?` — never parsed into a `DateTime` because the server timezone
is unknown. The badge fires when this string changes between installs.

**File size (`fileSize`):** Parsed from the trailing `(NNN.NNN kB)` text node
in each `<li>`. The numeric part is treated as a decimal kB value
(`134.831 kB → 134831 bytes`). Returns `null` if the pattern is absent or
unparseable.

**Download URL:** Taken directly from `<a href>`. Absolute URLs are used
as-is; relative URLs are prefixed with `https://www.soaringspot.com`.

### File Type Detection

| Extension | Type |
|---|---|
| `.txt` | Airspace |
| `.cup` | Waypoints |

All other extensions are silently skipped.

### Implementation File

`lib/features/competitions/data/datasources/soaringspot_remote_datasource.dart` — `fetchDownloads(String competitionUrl)`

---

## Competition Classes

**URL:** `{competition_url}/results`

Competition classes (e.g. "Standard", "Club", "Open") appear as column headers in the results overview table:

```html
<table class="result-overview">
  <thead>
    <tr>
      <th>Standard</th>
      <th>Club</th>
    </tr>
  </thead>
</table>
```

### Selector and URL Pattern

The Dart CSS selector is `table.result-overview thead th`. The results URL is formed by appending `/results` to the competition's SoaringSpot URL (with any trailing slash stripped first):

```dart
final url = '${competitionUrl.endsWith('/') ? competitionUrl.substring(0, competitionUrl.length - 1) : competitionUrl}/results';
```

Empty `<th>` elements are skipped. An empty result list is not an error — the table is absent before any competition day begins.

### Implementation File

`lib/features/competitions/data/datasources/soaringspot_remote_datasource.dart` — `fetchClasses(String competitionUrl)`

---

## Error Handling

All scraping methods can fail with:

| Error type | Cause |
|---|---|
| `NetworkFailure` | No internet, DNS failure, HTTP error status |
| `ParseFailure` | HTML structure changed; expected elements not found |

If SoaringSpot changes their HTML and parsing breaks, update the selectors in the remote datasource and update this document.

---

## Reference: openvario-compman

The scraping logic mirrors the Python implementation in [soaringspot.py](https://github.com/kedder/openvario-compman/blob/master/src/compman/soaringspot.py). Consult that file when porting new scraping logic.
