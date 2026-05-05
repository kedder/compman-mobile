/// Describes a known XCSoar application variant.
///
/// Each flavor has a [displayName] shown to the user and a [packageId]
/// used to detect installation and construct the data directory path.
class XcsoarFlavor {
  /// Creates an [XcsoarFlavor].
  const XcsoarFlavor({required this.displayName, required this.packageId});

  /// Human-readable name shown in the flavor picker list.
  final String displayName;

  /// Android package identifier, e.g. `com.xcsoar`.
  final String packageId;
}

/// The canonical list of known XCSoar variants, in display order.
const List<XcsoarFlavor> kKnownXcsoarFlavors = [
  XcsoarFlavor(displayName: 'XCSoar', packageId: 'com.xcsoar'),
  XcsoarFlavor(displayName: 'XCSoar Jet', packageId: 'com.zunuzoid.xcsoar_jet'),
  XcsoarFlavor(displayName: 'XCSoar Play', packageId: 'com.xcsoar.play'),
  XcsoarFlavor(displayName: 'XCSoar FOSS', packageId: 'com.xcsoar.foss'),
];
