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

Airspace and waypoint files available for download are listed as:

```html
<ul class="contest-downloads">
  <li><a href="/downloads/barron-2024/airspace.txt">airspace.txt</a></li>
  <li><a href="/downloads/barron-2024/waypoints.cup">waypoints.cup</a></li>
</ul>
```

### File Type Detection

| Extension | Type |
|---|---|
| `.txt` | Airspace |
| `.cup` | Waypoints |

> **Note:** This feature is planned for Phase 2. This section documents the intended scraping approach.

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

> **Note:** This feature is planned for Phase 4.

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
