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
