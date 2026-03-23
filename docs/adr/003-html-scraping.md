# ADR 003 — HTML Scraping Instead of REST API

**Status:** Accepted  
**Date:** 2026-03-23

## Context

Compman Mobile needs competition data from SoaringSpot (https://soaringspot.com). The question is whether to use a public API or scrape the website HTML.

## Decision

Scrape **HTML from the SoaringSpot website** using the `html` Dart package and CSS selectors.

## Alternatives Considered

| Option | Reason rejected |
|---|---|
| SoaringSpot public REST API | The API exists but is limited — it does not expose the competition listing page in a usable machine-readable form for public consumers without authentication |
| Third-party API aggregators | None identified; would add an uncontrolled dependency |

## Rationale

This is the same approach used by [openvario-compman](https://github.com/kedder/openvario-compman), which has worked reliably in production. The HTML structure of SoaringSpot's competition list is stable and simple (CSS class `contest`).

## Consequences

**Positive:**
- Works without API keys or registration.
- Consistent with the desktop app — HTML parsing logic can be ported directly.

**Negative:**
- Fragile: if SoaringSpot changes their HTML structure, parsing breaks.
- Mitigation: the scraping layer is isolated in `data/datasources/soaringspot_remote_datasource.dart`. A change in HTML only requires updating this one file.
- The `docs/api/soaringspot.md` documents the exact HTML structure relied on, making regressions easier to diagnose.

## Review Trigger

If SoaringSpot publishes a usable authenticated or public REST API for competition listings, migrate to it and update this ADR.
