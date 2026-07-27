package lt.lebedev.compman_mobile

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import android.util.Log
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    private lateinit var safLauncher: ActivityResultLauncher<Uri?>
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        safLauncher = registerForActivityResult(ActivityResultContracts.OpenDocumentTree()) { uri: Uri? ->
            val result = pendingResult ?: return@registerForActivityResult
            pendingResult = null

            if (uri == null) {
                Log.d("CompmanSAF", "safLauncher: user cancelled")
                result.success("cancelled")
                return@registerForActivityResult
            }

            Log.d("CompmanSAF", "safLauncher: user selected URI: $uri")

            contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
            )

            getSharedPreferences("compman_prefs", Context.MODE_PRIVATE)
                .edit()
                .putString("xcsoar_tree_uri", uri.toString())
                .apply()

            Log.d("CompmanSAF", "safLauncher: permission granted and stored")
            result.success("ok")
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "xcsoar.saf")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickDirectory" -> handlePickDirectory(result)
                    "writeFile" -> {
                        val bytes = call.argument<ByteArray>("bytes")!!
                        val filename = call.argument<String>("filename")!!
                        handleWriteFile(bytes, filename, result)
                    }
                    "getSafDirectoryUri" -> {
                        val uri = getSharedPreferences("compman_prefs", Context.MODE_PRIVATE)
                            .getString("xcsoar_tree_uri", null)
                        result.success(uri)
                    }
                    "clearSafPermission" -> {
                        val prefs = getSharedPreferences("compman_prefs", Context.MODE_PRIVATE)
                        val stored = prefs.getString("xcsoar_tree_uri", null)
                        Log.d("CompmanSAF", "clearSafPermission: stored URI before clear: $stored")
                        if (stored != null) {
                            val treeUri = Uri.parse(stored)
                            Log.d("CompmanSAF", "clearSafPermission: releasing permission for $treeUri")
                            try {
                                contentResolver.releasePersistableUriPermission(
                                    treeUri,
                                    Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
                                )
                                Log.d("CompmanSAF", "clearSafPermission: permission released")
                            } catch (_: SecurityException) { /* already released */ }
                            prefs.edit().remove("xcsoar_tree_uri").apply()
                            Log.d("CompmanSAF", "clearSafPermission: URI removed from prefs")
                        }
                        result.success("ok")
                    }
                    "isPackageInstalled" -> {
                        val pkg = call.argument<String>("packageId")!!
                        val installed = try {
                            packageManager.getPackageInfo(pkg, 0)
                            true
                        } catch (_: android.content.pm.PackageManager.NameNotFoundException) {
                            false
                        }
                        result.success(installed)
                    }
                    "canWriteToMediaDir" -> {
                        val pkg = call.argument<String>("packageId")!!
                        result.success(checkMediaDirWritable(pkg))
                    }
                    "pickDirectoryForPackage" -> {
                        val pkg = call.argument<String>("packageId")!!
                        pendingResult = result
                        safLauncher.launch(externalStorageDocUri(mediaPath(pkg)))
                    }
                    "resolveFlavorPackageId" -> {
                        val uri = call.argument<String>("uri")!!
                        @Suppress("UNCHECKED_CAST")
                        val candidates = call.argument<List<String>>("candidates")!!
                        result.success(candidates.firstOrNull { pkg ->
                            externalStorageTreeUri(mediaPath(pkg)).toString()
                                .equals(uri, ignoreCase = true)
                        })
                    }
                    "launchPackage" -> {
                        val packageId = call.argument<String>("packageId")!!
                        val intent = packageManager.getLaunchIntentForPackage(packageId)
                        if (intent != null) {
                            try {
                                startActivity(intent)
                                result.success(null)
                            } catch (e: android.content.ActivityNotFoundException) {
                                result.error("LAUNCH_FAILED", "No launcher activity for $packageId", null)
                            }
                        } else {
                            result.error("LAUNCH_FAILED", "No launcher activity for $packageId", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /** Returns the `primary:Android/media/<pkg>` document path for [pkg]. */
    private fun mediaPath(pkg: String) = "primary:Android/media/$pkg"

    /** Returns a SAF document URI for [path] on the external storage provider. */
    private fun externalStorageDocUri(path: String): Uri =
        Uri.parse("content://com.android.externalstorage.documents/document/${Uri.encode(path)}")

    /** Returns a SAF tree URI for [path] on the external storage provider. */
    private fun externalStorageTreeUri(path: String): Uri =
        Uri.parse("content://com.android.externalstorage.documents/tree/${Uri.encode(path)}")

    private fun checkMediaDirWritable(pkg: String): Boolean {
        // Android/media is readable without SAF permission (unlike Android/data).
        // We just check the directory exists; if it does, the user can grant SAF
        // access to it via the folder picker.
        val dir = java.io.File(getExternalFilesDir(null)?.parentFile?.parentFile?.parentFile, "media/$pkg")
        return dir.exists() && dir.isDirectory
    }

    private fun getXcsoarMediaPath(): String {
        val possiblePackages = listOf("org.xcsoar", "org.xcsoar.play", "org.xcsoar.foss")
        val externalMediaDir = java.io.File("/sdcard/Android/media")
        for (pkg in possiblePackages) {
            val dir = java.io.File(externalMediaDir, pkg)
            if (dir.exists() && dir.isDirectory) {
                Log.d("CompmanSAF", "getXcsoarMediaPath: found XCSoar at $pkg")
                return mediaPath(pkg)
            }
        }
        Log.d("CompmanSAF", "getXcsoarMediaPath: no XCSoar directory found, using fallback")
        return mediaPath("org.xcsoar")
    }

    private fun handlePickDirectory(result: MethodChannel.Result) {
        pendingResult = result
        val prefs = getSharedPreferences("compman_prefs", Context.MODE_PRIVATE)
        val storedUri = prefs.getString("xcsoar_tree_uri", null)
        val initialUri = if (storedUri != null) {
            Log.d("CompmanSAF", "handlePickDirectory: using stored URI: $storedUri")
            Uri.parse(storedUri)
        } else {
            Log.d("CompmanSAF", "handlePickDirectory: no stored URI, detecting XCSoar path")
            externalStorageDocUri(getXcsoarMediaPath())
        }
        Log.d("CompmanSAF", "handlePickDirectory: launching with URI: $initialUri")
        safLauncher.launch(initialUri)
    }

    private fun handleWriteFile(bytes: ByteArray, filename: String, result: MethodChannel.Result) {
        val prefs = getSharedPreferences("compman_prefs", Context.MODE_PRIVATE)
        val storedUri = prefs.getString("xcsoar_tree_uri", null)
        if (storedUri == null) {
            result.error("SAF_NOT_CONFIGURED", "XCSoar directory not set", null)
            return
        }
        val treeUri = Uri.parse(storedUri)
        val hasGrant = contentResolver.persistedUriPermissions.any { perm ->
            perm.uri == treeUri && perm.isReadPermission && perm.isWritePermission
        }
        if (!hasGrant) {
            result.error("SAF_NOT_CONFIGURED", "XCSoar directory not set", null)
            return
        }
        try {
            val treeDocId = DocumentsContract.getTreeDocumentId(treeUri)
            val parentDocUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, treeDocId)
            val childDocUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, treeDocId)
            Log.d("CompmanSAF", "writeFile: treeUri=$treeUri bytes=${bytes.size}")
            // ExternalStorageProvider ignores selection args, so we fetch all children
            // and filter by display name in-process.
            val cursor = contentResolver.query(
                childDocUri,
                arrayOf(
                    DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                    DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                ),
                null, null, null,
            )
            val fileUri: Uri? = cursor?.use {
                val idCol = it.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DOCUMENT_ID)
                val nameCol = it.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
                var found: Uri? = null
                while (it.moveToNext()) {
                    if (it.getString(nameCol) == filename) {
                        found = DocumentsContract.buildDocumentUriUsingTree(treeUri, it.getString(idCol))
                        break
                    }
                }
                found
            }
            if (fileUri != null) {
                // File exists — truncate and overwrite in place to avoid duplicate names.
                Log.d("CompmanSAF", "writeFile: overwriting existing $fileUri")
                contentResolver.openOutputStream(fileUri, "rwt").use { it!!.write(bytes) }
            } else {
                val newUri = DocumentsContract.createDocument(
                    contentResolver,
                    parentDocUri,
                    "application/octet-stream",
                    filename,
                )
                Log.d("CompmanSAF", "writeFile: created $newUri")
                contentResolver.openOutputStream(newUri!!).use { it!!.write(bytes) }
            }
            result.success("ok")
        } catch (e: Exception) {
            result.error("SAF_ERROR", e.message, null)
        }
    }
}
