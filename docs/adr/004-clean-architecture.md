# ADR 004 — Clean Architecture with Feature-Based Folders

**Status:** Accepted  
**Date:** 2026-03-23

## Context

The app will grow over multiple phases (browse competitions → download files → generate tasks). The architecture needs to support incremental development, easy testing, and AI-assisted code generation without becoming a tangled mess.

## Decision

Use **Clean Architecture** (domain / data / presentation layers) with a **feature-based folder structure**.

## Alternatives Considered

| Option | Reason rejected |
|---|---|
| Layer-based folders (`models/`, `screens/`, `services/`) | All features mixed in each folder; hard to understand or delete a single feature |
| MVVM only (ViewModel + View) | No explicit domain layer; business logic ends up in ViewModels or leaked into UI |
| Simple single-layer architecture | Fine for very small apps; will not scale to Phase 2+ |

## Consequences

**Positive:**
- Each feature is self-contained: adding Phase 2 (downloads) means adding a new `features/downloads/` folder without touching competitions code.
- Domain layer is pure Dart: use cases and entities can be unit-tested without Flutter or mocking network/storage.
- AI models can add a new feature by following the established pattern in `lib/features/competitions/`.
- The dependency rule (`presentation → domain ← data`) prevents circular dependencies and keeps business logic clean.

**Negative:**
- More files and folders than a simple flat structure.
- Requires discipline to maintain the dependency rule — enforced via `CLAUDE.md` instructions and code review.
