import 'package:flutter/services.dart';

/// Service for interacting with XCSoar's data directory via the
/// Android Storage Access Framework (SAF).
///
/// Uses a [MethodChannel] to communicate with the Kotlin bridge in
/// `MainActivity.kt`. The channel handles folder-picker presentation,
/// persistent URI grants, and file I/O on the Android side.
class XcsoarSafService {
  static const _channel = MethodChannel('xcsoar.saf');

  /// Writes `hello-from-compman.txt` into XCSoar's SAF data folder.
  ///
  /// On first call the Android folder picker is shown so the user can grant
  /// access. Subsequent calls reuse the persisted tree URI grant stored in
  /// Android `SharedPreferences` without re-showing the picker.
  ///
  /// Returns `"ok"` on success or `"cancelled"` if the user dismissed the
  /// picker. Throws [PlatformException] on write errors.
  Future<String> tryWriteHelloFile() async {
    final result = await _channel.invokeMethod<String>('tryWriteHelloFile');
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
}
