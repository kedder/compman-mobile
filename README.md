# Compman Mobile

An Android application for glider pilots participating in gliding competitions. It fetches competition data from [SoaringSpot](https://soaringspot.com), lets you bookmark competitions you plan to attend, and (in future versions) automatically downloads waypoint and airspace files into [XCSoar](https://xcsoar.org)'s data folder on the same device.

This is the mobile companion to [openvario-compman](https://github.com/kedder/openvario-compman), which runs on the OpenVario flight computer.

---

## Features

- Browse all current gliding competitions listed on SoaringSpot
- Bookmark competitions you plan to participate in
- *(Planned)* Download waypoint (.cup) and airspace (.txt) files to `XCSoarData/`
- *(Planned)* Generate XCSoar task files (.tsk) from competition task data
- *(Planned)* Competition class selection and daily task refresh

## Quick Start

```bash
# 1. Install Flutter (https://flutter.dev/docs/get-started/install)

# 2. Get dependencies
flutter pub get

# 3. Run on connected Android device or emulator
flutter run
```

## Architecture

The app follows Clean Architecture with a feature-based folder structure. See [docs/architecture.md](docs/architecture.md) for a full overview.

## Documentation

| Document | Description |
|---|---|
| [docs/architecture.md](docs/architecture.md) | Layers, folder structure, dependency rules |
| [docs/plan.md](docs/plan.md) | Living implementation plan |
| [docs/features/competitions.md](docs/features/competitions.md) | Competitions feature: entities, use cases, screens |
| [docs/api/soaringspot.md](docs/api/soaringspot.md) | SoaringSpot scraping: HTML structure, models |
| [docs/adr/](docs/adr/) | Architecture Decision Records |

## Related Projects

- [openvario-compman](https://github.com/kedder/openvario-compman) — the original, for OpenVario flight computer (Python, text-mode)

## License

GPL-3.0 — same as openvario-compman.
