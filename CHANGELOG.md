# Changelog

All notable user-facing changes to Compman Mobile are documented here. This file is
published as the "What's New" text on the Google Play Store listing.

## Unreleased

### Added

- Fly XCSoar button on task cards to launch a downloaded task straight into XCSoar
- "New" badge on tasks that changed since you last downloaded them
- Show today's flight logs on the competition screen, with a one-tap way to email them to
  organizers for scoring

### Changed

- Show the on-device filename when an airspace or waypoints file finishes downloading
- Hide airspace and waypoint download options until you pick your competition class

## 0.2.0 - 2026-05-10

### Added

- About screen with app icon, author info, and data source credits
- Download airspace and waypoint files straight to XCSoar from the competition screen
- XCSoar flavor picker that shows which XCSoar variant (XCSoar, XCSoar 7, ...) is
  currently active, with guidance when folder access is blocked
- App remembers the last competition you viewed and opens it automatically next time

### Changed

- Renamed the task download button to "Download task"
- Storage access setup now opens automatically when needed, then resumes your download

### Fixed

- Back button now returns to the competition list instead of exiting the app when
  reopening a remembered competition
- Flavor picker now correctly detects which XCSoar variants are installed
- Flavor picker now closes automatically after granting folder access
