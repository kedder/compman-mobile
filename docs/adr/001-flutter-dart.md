# ADR 001 — Flutter + Dart for Mobile Development

**Status:** Accepted  
**Date:** 2026-03-23

## Context

Compman Mobile needs to run on Android. The primary developer is familiar with Python (openvario-compman) but wants a modern, AI-friendly mobile stack with good tooling and a rich UI.

## Decision

Use **Flutter** (Dart) as the application framework.

## Consequences

**Positive:**
- Single codebase could target iOS in the future with minimal changes.
- Rich widget library and Material Design out of the box, appropriate for a utility app.
- Strong type system (Dart) makes AI-assisted code generation more reliable and verifiable.
- Excellent hot reload speeds up development iteration.
- Large ecosystem of packages covering all needed functionality.

**Negative:**
- Dart is a different language from the Python codebase of openvario-compman; no code can be shared.
- Flutter apps have a larger binary size than native apps.
