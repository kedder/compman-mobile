import 'package:flutter/services.dart';

/// Service for interacting with XCSoar's data directory via the
/// Android Storage Access Framework (SAF).
///
/// Uses a [MethodChannel] to communicate with the Kotlin bridge in
/// `MainActivity.kt`. The channel handles folder-picker presentation,
/// persistent URI grants, and file I/O on the Android side.
class XcsoarSafService {
  static const _channel = MethodChannel('xcsoar.saf');

  /// Launches the Android folder picker for the XCSoar SAF directory.
  ///
  /// Returns `"ok"` when the user grants access or `"cancelled"` when the
  /// picker is dismissed. Throws [PlatformException] if the Android bridge
  /// cannot complete the request.
  Future<String> pickDirectory() async {
    final result = await _channel.invokeMethod<String>('pickDirectory');
    return result!;
  }

  /// Writes [bytes] to a file named [filename] in the stored XCSoar SAF directory.
  ///
  /// Throws [PlatformException] with code `SAF_NOT_CONFIGURED` if no directory
  /// has been granted yet, or `SAF_ERROR` on write failure.
  Future<void> writeFile(Uint8List bytes, String filename) async {
    await _channel.invokeMethod<void>('writeFile', {
      'bytes': bytes,
      'filename': filename,
    });
  }

  /// Returns the stored SAF tree URI string, or null if not yet configured.
  Future<String?> getSafDirectoryUri() =>
      _channel.invokeMethod<String>('getSafDirectoryUri');

  /// Releases the stored SAF permission and clears the cached tree URI.
  Future<void> clearSafPermission() =>
      _channel.invokeMethod<void>('clearSafPermission');

  /// Returns true if the given Android package is installed on the device.
  Future<bool> isPackageInstalled(String packageId) async {
    final result = await _channel.invokeMethod<bool>('isPackageInstalled', {
      'packageId': packageId,
    });
    return result ?? false;
  }

  /// Returns true if [Android/media/<packageId>/] exists on the filesystem.
  ///
  /// Returns false if the directory does not exist (e.g. XCSoar is using
  /// Android/data instead, or has never been launched). A true result means
  /// the user can grant SAF access via the folder picker.
  Future<bool> canWriteToMediaDir(String packageId) async {
    final result = await _channel.invokeMethod<bool>('canWriteToMediaDir', {
      'packageId': packageId,
    });
    return result ?? false;
  }

  /// Launches the Android folder picker pre-navigated to [Android/media/<packageId>/].
  ///
  /// Returns `"ok"` on success or `"cancelled"` if the user dismissed the picker.
  Future<String> pickDirectoryForPackage(String packageId) async {
    final result = await _channel.invokeMethod<String>(
      'pickDirectoryForPackage',
      {'packageId': packageId},
    );
    return result!;
  }
}
