# ADR 002 — Riverpod for State Management

**Status:** Accepted  
**Date:** 2026-03-23

## Context

The app needs a state management solution that handles async data fetching (network requests), local persistence, and UI state. The solution should be easy to test and easy for AI models to reason about.

## Decision

Use **flutter_riverpod** with `AsyncNotifier` and `Notifier` classes.

## Alternatives Considered

| Option | Reason rejected |
|---|---|
| `Provider` (simple) | No built-in async state handling; deprecated in favor of Riverpod |
| `BLoC / Cubit` | More boilerplate; events/states split adds complexity without benefit at this scale |
| `setState` only | Not scalable; breaks when state needs to be shared between screens |
| `GetX` | Opinionated, mixes concerns (navigation + state + DI in one) |

## Consequences

**Positive:**
- Compile-time safety: providers are typed, no runtime key lookups.
- Easy to test: providers can be overridden in tests with mock implementations.
- `AsyncNotifier` cleanly models loading/data/error states for network calls.
- Well-documented pattern that AI models handle well.

**Negative:**
- Requires a code generation step (`build_runner`) for some provider patterns, though `AsyncNotifier` works without it.
- Team members unfamiliar with Riverpod need a learning curve.
