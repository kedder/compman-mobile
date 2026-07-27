# Compman Mobile — Agent Instructions

This file is the canonical instruction set for automated agents working on this project.
Read this file first, then load the relevant project documentation before making changes.

Tool-specific files such as `CLAUDE.md` should defer to this document unless they need
tool-only metadata or launcher configuration.

---

## Development Environment

**All Flutter/Dart/Android SDKs run inside Docker.** Do not assume these tools are
installed on the host.

### If you are running on the host machine

Use `make` targets to run project commands. The Makefile handles Docker transparently:

```bash
make deps            # flutter pub get
make codegen         # dart run build_runner build --delete-conflicting-outputs
make test            # flutter test
make analyze         # flutter analyze
make format          # dart format lib test
make build           # flutter build apk --debug
make help            # full list of available targets
```

### If you are running inside the dev container (`.devcontainer`)

All tools are available directly. Use Flutter/Dart commands without `make`:

```bash
flutter pub get
flutter test
flutter analyze
dart run build_runner build --delete-conflicting-outputs
flutter build apk
```

Full details: [docs/dev-environment.md](docs/dev-environment.md)

---

## Quick Context Load

For any task, load these in order:

1. **[docs/dev-environment.md](docs/dev-environment.md)** — understand how to run commands (Docker / Makefile)
2. **[docs/architecture.md](docs/architecture.md)** — understand the layer structure and dependency rules
3. **[docs/plan.md](docs/plan.md)** — understand what is built, what is in progress, and what is planned
4. **Feature doc** for the area you're working in, e.g. [docs/features/competitions.md](docs/features/competitions.md)
5. **API doc** if touching network code: [docs/api/soaringspot.md](docs/api/soaringspot.md)
6. **[docs/features/overview.md](docs/features/overview.md)** — UI specification: screens, user flows, and UX requirements. Required reading for UI or presentation-layer work.
7. **[docs/ui-guidelines.md](docs/ui-guidelines.md)** — visual theme, touch targets, typography, status badges, loading/error/empty state patterns, button hierarchy, and accessibility rules. Required reading for UI or presentation-layer work.
8. **If working on an issue**: read [issues/AGENTS.md](issues/AGENTS.md) before starting, then open the assigned issue file.

---

## Project Rules

### Code Quality

- Add `///` Dart doc comments to every new public class, method, and field.
- Follow the folder structure defined in `docs/architecture.md` exactly. Do not create files outside the defined structure without updating the architecture doc.
- Use `freezed` for all domain entities and data models (immutable, `copyWith`, `==`).
- Use `Riverpod` (`AsyncNotifier` / `Notifier`) for all state management. No `setState` in feature screens.

### Architecture: Dependency Rule

```text
presentation  →  domain  ←  data
```

- `domain` must never import from `data` or `presentation`.
- `data` implements interfaces defined in `domain`.
- `presentation` depends only on `domain` entities and Riverpod providers.
- `core` may be imported by all layers.

If you need to break this rule, create an ADR first.

### Documentation Maintenance (Required)

When you make any code change, you must also:

| Change type | Documentation to update |
|---|---|
| Add / change a feature | Update or create `docs/features/<feature>.md` |
| Add / change scraping or network code | Update `docs/api/soaringspot.md` |
| Add a new architectural pattern or dependency | Update `docs/architecture.md` |
| Make a significant technology/design decision | Add a new `docs/adr/NNN-title.md` |
| Complete a planned task | Mark it ✅ in `docs/plan.md` with a brief implementation note |
| Identify new work during implementation | Add 📋 item to `docs/plan.md` |
| Make a user-visible change | Add an entry to `CHANGELOG.md` under `Unreleased` |

Documentation updates belong in the same commit as the code change.

**`docs/features/<feature>.md` style:** these describe *what* a feature does and *why*,
as functional requirements a reader can reason about without opening the source — not
*how* it's implemented. Do not paste class definitions, method signatures, or field
lists: they go stale the next time a property or method is renamed, and every past
instance of this has already caused a doc to silently drift out of sync with the code
(e.g. a use-case table that stopped being updated after a few issues). When code needs a
pointer, reference a folder or file loosely ("the competitions domain layer") rather than
an exact symbol. `docs/features/competitions.md` and `docs/features/configuration.md` are
the current reference examples of this style.

### Changelog Maintenance

`CHANGELOG.md` is published as the "What's New" text on the Google Play Store listing.
The audience is **end users (pilots), not developers**. Keep entries short, plain-language,
and focused on what changed for them — never mention class names, files, refactors, or
internal implementation details.

- **What gets an entry**: any commit that changes what a user can see or do — new
  features, UI changes, behavior changes, bug fixes a user would notice, removed
  features. Skip entries for `refactor`, `test`, `docs`, `chore`, `ci`, and `plan`
  commits, and for internal fixes with no observable effect.
- **Where**: add the entry under the `## Unreleased` heading at the top of the file, in
  the same commit as the change, grouped under `### Added`, `### Changed`, `### Fixed`,
  or `### Removed` (omit empty groups).
- **Style**: one line per entry, plain sentence a pilot would understand, capitalized,
  no trailing period, no jargon. E.g. "Show a badge on tasks that changed since you last
  downloaded them." not "Add version tracking to TaskModel."
- **Cutting a release**: versions correspond to annotated git tags (`git tag -a vX.Y.Z`).
  When tagging a release, rename `## Unreleased` to `## X.Y.Z - YYYY-MM-DD` (matching the
  tag) and add a fresh empty `## Unreleased` section above it.

### Tests

- Run tests before considering any task done: `flutter test`
- Every use case class must have a unit test.
- Every repository implementation must have a unit test with mocked data sources.
- Widget tests are required for screens that have user interaction.

### Git

- Commit messages: `<type>(<scope>): <description>` (conventional commits)
  - Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`
  - Example: `feat(competitions): add bookmark toggle to competition list`
- Each commit should be atomic: one logical change.

---

## Key File Locations

```text
lib/
  main.dart                         # Entry point
  app.dart                          # App widget and router
  core/                             # Shared: HTTP, errors, DI
  features/
    competitions/
      domain/                       # Entities, repository interface, use cases
      data/                         # Remote/local datasources, repository impl
      presentation/                 # Riverpod providers, screens, widgets
docs/
  architecture.md
  plan.md
  features/competitions.md
  api/soaringspot.md
  adr/
AGENTS.md                           # Canonical agent instructions
CLAUDE.md                           # Compatibility wrapper for Claude-specific tooling
README.md
pubspec.yaml
```

---

## Technology Stack

| Purpose | Package |
|---|---|
| UI framework | Flutter (Dart) |
| State management | `flutter_riverpod` |
| HTTP client | `dio` |
| HTML parsing (scraping) | `html` |
| Local persistence | `hive_flutter` |
| Navigation | `go_router` |
| Immutable models | `freezed` + `json_serializable` |
| Testing mocks | `mockito` |

---

## SoaringSpot Data Source

SoaringSpot does not provide a useful public REST API for competition listings. The app
scrapes HTML from `https://www.soaringspot.com` — the same approach used by
openvario-compman. See [docs/api/soaringspot.md](docs/api/soaringspot.md) for details.
