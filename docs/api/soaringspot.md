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
| `id` | Last path segment of `<a href>` | e.g. `"barron-2024"` |
| `title` | Text content of `<a>` inside `<h3>` | e.g. `"Barron 2024"` |
| `url` | `https://www.soaringspot.com` + `href` attribute | Full URL |
| `description` | Text content of `.info` div | Dates and location |

### Implementation File

`lib/features/competitions/data/datasources/soaringspot_remote_datasource.dart`

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
