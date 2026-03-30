# ADR 005: SoarScore HTML Scraping for Task File Downloads

**Status:** Accepted
**Date:** 2026-03-30

---

## Context

Compman Mobile needs to fetch XCSoar `.tsk` task files for active competitions.

SoarScore (`soarscore.com`) is the established source used by the TUI version (openvario-compman). SoarScore has no public API. The only machine-readable output is the `#Downloads` tab on competition pages, which contains `<a download href="...">` links with structured text descriptions.

The `.tsk` file URL and metadata (class name, day, task number, timestamp) are only available by parsing this HTML tab.

---

## Decision

Scrape the `#Downloads` tab at `https://soarscore.com/competitions/{id}/` using the `html` package. Parse task metadata from link text using a regular expression. Download `.tsk` file bytes directly from the extracted URL.

---

## Alternatives Considered

| Option | Reason rejected |
|---|---|
| SoarScore REST API | Does not exist |
| User manually downloads `.tsk` and copies to device | Poor UX; defeats the purpose of the app |
| SoaringSpot task download | SoaringSpot serves tasks in a different format (not `.tsk` directly); SoarScore already generates XCSoar-compatible `.tsk` XML |

---

## Rationale

- Same approach as openvario-compman, proven in production.
- The HTML structure is simple and has been stable across competition seasons.
- SoarScore scraping is isolated to `data/datasources/soarscore_remote_datasource.dart`.
- The `#Downloads` tab is specifically intended for pilot download tooling — it is intentionally machine-friendly.

---

## Consequences

- Fragile if SoarScore changes HTML structure; mitigated by isolation and `docs/api/soarscore.md` documenting the exact structure.
- SoarScore may have no competition page for a given event (especially older or non-scoring competitions); this is a normal `[]` empty-list result, not an error.
- The competition ID passed to SoarScore is the same SoaringSpot URL slug stored on `BookmarkedCompetition.id`. This coupling is documented in `docs/api/soarscore.md`.

---

## Review Trigger

If SoarScore publishes a public API, migrate to it and update this ADR.
