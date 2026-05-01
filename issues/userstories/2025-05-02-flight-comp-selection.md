Users are having trouble navigating the right XCSoar data directory. Right now the
selection is placed in the Settings screen, which is also not obvious to users: right
now they need to go to Settings and configure the directory before they can download any
tasks, airspace, or waypoints. This is a major friction point and barrier to entry.

Also, there are sevral flavors of XCSoar software (the flight computer) available to
install. Each uses a different data folder (but compatible file formats, so this app can
support all of them).

The flavors I'm aware of are:

- Original XCSoar: `com.xcsoar`
- XCSoar Jet: `com.zunuzoid.xcsoar_jet`
- XCSoar Play: `com.xcsoar.play`
- XCSoar FOSS: `com.xcsoar.foss`

User may have installed one or more of these. We need to allow user to pick which flavor
he wants to use with this app and automatically configure the directory for them.

There are few gotchas surfaced from real-life testing:

- Some old XCSoar versions use Android/data folder that is not easily accessible on
  modern Android versions. Newer XCSoars use Android/media/, but fall back to
  Android/data when that directory already exist (and contains user configs and files).
  We either need a way to write files to that `Android/data/` folder (e.g.
  `Android/data/com.xcsoar`), or guide user how to switch to `Android/media`.
- We should still let user pick arbitrary directory, but it should be reserved for
  advanced users.