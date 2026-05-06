/// Describes a known XCSoar application variant.
///
/// Each flavor has a [displayName] shown to the user and a [packageId]
/// used to detect installation and construct the data directory path.
class XcsoarFlavor {
  /// Creates an [XcsoarFlavor].
  const XcsoarFlavor({required this.displayName, required this.packageId});

  /// Human-readable name shown in the flavor picker list.
  final String displayName;

  /// Android package identifier, e.g. `org.xcsoar`.
  final String packageId;
}

/// The canonical list of known XCSoar variants, in display order.
const List<XcsoarFlavor> kKnownXcsoarFlavors = [
  XcsoarFlavor(displayName: 'XCSoar', packageId: 'org.xcsoar'),
  XcsoarFlavor(displayName: 'XCSoar Jet', packageId: 'com.zinuzoid.xcsoar_jet'),
  XcsoarFlavor(displayName: 'XCSoar Play', packageId: 'org.xcsoar.play'),
  XcsoarFlavor(displayName: 'XCSoar FOSS', packageId: 'org.xcsoar.foss'),
];
