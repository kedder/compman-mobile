package lt.lebedev.compman_mobile

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
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
                result.success("cancelled")
                return@registerForActivityResult
            }

            contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
            )

            getSharedPreferences("compman_prefs", Context.MODE_PRIVATE)
                .edit()
                .putString("xcsoar_tree_uri", uri.toString())
                .apply()

            writeHelloFile(uri, result)
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "xcsoar.saf")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "tryWriteHelloFile" -> handleTryWriteHelloFile(result)
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
                        if (stored != null) {
                            val treeUri = Uri.parse(stored)
                            try {
                                contentResolver.releasePersistableUriPermission(
                                    treeUri,
                                    Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
                                )
                            } catch (_: SecurityException) { /* already released */ }
                            prefs.edit().remove("xcsoar_tree_uri").apply()
                        }
                        result.success("ok")
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun handleTryWriteHelloFile(result: MethodChannel.Result) {
        val prefs = getSharedPreferences("compman_prefs", Context.MODE_PRIVATE)
        val storedUri = prefs.getString("xcsoar_tree_uri", null)

        if (storedUri != null) {
            val treeUri = Uri.parse(storedUri)
            val hasGrant = contentResolver.persistedUriPermissions.any { perm ->
                perm.uri == treeUri &&
                    perm.isReadPermission &&
                    perm.isWritePermission
            }
            if (hasGrant) {
                writeHelloFile(treeUri, result)
                return
            }
        }

        pendingResult = result
        safLauncher.launch(Uri.parse("content://org.xcsoar.allfiles/document/root:"))
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
            val childDocUri = DocumentsContract.buildChildDocumentsUriUsingTree(
                treeUri,
                DocumentsContract.getTreeDocumentId(treeUri),
            )
            val cursor = contentResolver.query(
                childDocUri,
                arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID),
                "${DocumentsContract.Document.COLUMN_DISPLAY_NAME} = ?",
                arrayOf(filename),
                null,
            )
            val fileUri: Uri? = cursor?.use {
                if (it.moveToFirst()) {
                    val docId = it.getString(0)
                    DocumentsContract.buildDocumentUriUsingTree(treeUri, docId)
                } else {
                    null
                }
            }
            if (fileUri != null) {
                // File exists — truncate and overwrite in place to avoid duplicate names.
                contentResolver.openOutputStream(fileUri, "rwt").use { it!!.write(bytes) }
            } else {
                val newUri = DocumentsContract.createDocument(
                    contentResolver,
                    childDocUri,
                    "application/octet-stream",
                    filename,
                )
                contentResolver.openOutputStream(newUri!!).use { it!!.write(bytes) }
            }
            result.success("ok")
        } catch (e: Exception) {
            result.error("SAF_ERROR", e.message, null)
        }
    }

    private fun writeHelloFile(treeUri: Uri, result: MethodChannel.Result) {
        try {
            val childDocUri = DocumentsContract.buildChildDocumentsUriUsingTree(
                treeUri,
                DocumentsContract.getTreeDocumentId(treeUri),
            )

            // Delete existing file to avoid duplicates
            val cursor = contentResolver.query(
                childDocUri,
                arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID),
                "${DocumentsContract.Document.COLUMN_DISPLAY_NAME} = ?",
                arrayOf("hello-from-compman.txt"),
                null,
            )
            cursor?.use {
                if (it.moveToFirst()) {
                    val docId = it.getString(0)
                    val existingDocUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, docId)
                    DocumentsContract.deleteDocument(contentResolver, existingDocUri)
                }
            }

            val fileUri = DocumentsContract.createDocument(
                contentResolver,
                childDocUri,
                "text/plain",
                "hello-from-compman.txt",
            )

            contentResolver.openOutputStream(fileUri!!).use {
                it!!.write("Hello from Compman Mobile!".toByteArray())
            }

            result.success("ok")
        } catch (e: Exception) {
            result.error("SAF_ERROR", e.message, null)
        }
    }
}
