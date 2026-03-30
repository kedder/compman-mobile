# SoarScore API

SoarScore (`soarscore.com`) publishes XCSoar-compatible `.tsk` task files for active gliding competitions. Compman Mobile scrapes the competition page to discover and download these files.

---

## Competition Page URL

```
https://soarscore.com/competitions/{competition_id}/
```

`competition_id` is the SoaringSpot URL slug stored as `BookmarkedCompetition.id`. For example, a competition bookmarked with id `celje-cup-2020-drzavno-...` uses:

```
https://soarscore.com/competitions/celje-cup-2020-drzavno-.../
```

This coupling between the SoaringSpot slug and the SoarScore URL is intentional — SoarScore uses the same slug.

---

## Downloads Tab — CSS Selector

The competition page contains a `#Downloads` tab whose content holds one `<a download href="...">` link per available task:

```html
<div id="Downloads">
  <p>
    <a href="http://soarscore.com/competitions/{id}/club-task5-2020-07-01.tsk" download>
      <button ...>
        <span>...<strong>... Club Day6 Task5</strong></span><br>
        AAT 159/361km<br>
        .tsk generated: 01-07-2020 21:35:04
      </button>
    </a>
  </p>
  ...
</div>
```

The Dart selector used to find all download links is:

```
#Downloads a[download]
```

---

## Task Description Regex

The flattened inner text of each `<a download>` element (whitespace-normalised) matches:

```
{Class} Day{N} Task{M} {description} .tsk generated: {timestamp}
```

Dart regex (with `dotAll: true` to span newlines):

```
^(.*)\s+Day(\d+)\s+Task(\d+)\s+(.*)\s+\.tsk generated:\s+(.*)$
```

**Capture groups:**

| Group | Field | Example |
|---|---|---|
| 1 | `compClass` | `Club` |
| 2 | `dayNo` | `6` |
| 3 | `taskNo` | `5` |
| 4 | `title` | `AAT 159/361km` |
| 5 | `timestamp` | `01-07-2020 21:35:04` |

Links that do not match the regex are silently skipped.

---

## Task File Download

The `.tsk` file URL is the `href` attribute of the `<a download>` element. URLs may be relative; the implementation prepends `https://soarscore.com` when the href does not start with `http`.

The file is downloaded as raw bytes (`ResponseType.bytes`) and written to disk as `Default.tsk` inside the XCSoar data directory.

The `.tsk` format is standard XCSoar XML — no parsing or transformation is required.

---

## Known Caveats

- SoarScore may have no page for a competition (e.g. older events not scored by SoarScore). A missing or empty page yields an empty task list — this is a normal result, not an error.
- During the off-season, the `#Downloads` tab may be present but empty. Again, an empty list is the correct response.
- SoarScore serves on HTTP/2. The `dio` client handles this transparently on Android.
