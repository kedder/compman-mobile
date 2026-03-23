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

All SDKs are in Docker — nothing to install on your machine except Docker and `make`.

```bash
# 1. Build the development Docker image (one-time, takes a few minutes)
make build-image

# 2. Install Dart dependencies
make deps

# 3. Run tests to verify everything works
make test
```

For running on a device, opening in VS Code, or updating SDK versions see [docs/dev-environment.md](docs/dev-environment.md).

## Architecture

The app follows Clean Architecture with a feature-based folder structure. See [docs/architecture.md](docs/architecture.md) for a full overview.

## Documentation

| Document | Description |
|---|---|
| [docs/dev-environment.md](docs/dev-environment.md) | Docker dev environment: setup, commands, updating SDKs |
| [docs/architecture.md](docs/architecture.md) | Layers, folder structure, dependency rules |
| [docs/plan.md](docs/plan.md) | Living implementation plan |
| [docs/features/competitions.md](docs/features/competitions.md) | Competitions feature: entities, use cases, screens |
| [docs/api/soaringspot.md](docs/api/soaringspot.md) | SoaringSpot scraping: HTML structure, models |
| [docs/adr/](docs/adr/) | Architecture Decision Records |

## Related Projects

- [openvario-compman](https://github.com/kedder/openvario-compman) — the original, for OpenVario flight computer (Python, text-mode)

## License

GPL-3.0 — same as openvario-compman.
