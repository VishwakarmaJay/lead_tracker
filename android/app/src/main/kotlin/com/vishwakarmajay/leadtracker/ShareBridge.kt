package com.vishwakarmajay.leadtracker

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.StatFs
import android.provider.OpenableColumns
import android.util.Log
import android.webkit.MimeTypeMap
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileNotFoundException
import java.io.FileOutputStream
import java.io.IOException
import java.util.UUID
import java.util.concurrent.Executors

/**
 * Receives files shared into the app (Google Phone call recordings) and copies
 * them into app-private cache while the temporary content:// grant is valid.
 *
 * Shares are queued process-wide until Dart takes them, so a cold-start share
 * is never lost before Flutter is listening. Every share produces a payload;
 * failures carry an `error` instead of being dropped.
 *
 * Native code: any change here needs a new Shorebird release, not a patch.
 */
object ShareIntake {
    private const val TAG = "LeadTrackerShare"
    private const val CACHE_DIR = "shared_imports"

    /** Upper bound for one shared file. Call recordings are far smaller. */
    private const val MAX_BYTES = 200L * 1024 * 1024

    /** Free space kept in reserve after a copy. */
    private const val RESERVE_BYTES = 50L * 1024 * 1024

    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private val queue = mutableListOf<Map<String, Any?>>()

    /** Called on the main thread whenever the queue gains items. */
    @Volatile
    var onQueued: (() -> Unit)? = null

    fun shareDir(context: Context): File = File(context.cacheDir, CACHE_DIR)

    fun handle(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        if (action != Intent.ACTION_SEND && action != Intent.ACTION_SEND_MULTIPLE) {
            return
        }
        val uris = extractUris(intent)
        val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
        val fallbackMime = intent.type

        executor.execute {
            val payloads =
                if (uris.isEmpty()) {
                    listOf(failure("No file was included in the share.", null, fallbackMime, sharedText))
                } else {
                    uris.map { copy(context, it, fallbackMime, sharedText) }
                }
            synchronized(queue) { queue.addAll(payloads) }
            mainHandler.post { onQueued?.invoke() }
        }
    }

    fun takePending(): List<Map<String, Any?>> =
        synchronized(queue) {
            val items = queue.toList()
            queue.clear()
            items
        }

    fun hasPending(): Boolean = synchronized(queue) { queue.isNotEmpty() }

    /** Deletes a cached copy. Refuses anything outside the share cache. */
    fun deleteCached(context: Context, path: String): Boolean {
        val dir = shareDir(context).canonicalFile
        val file = File(path).canonicalFile
        if (file.parentFile != dir) {
            return false
        }
        return !file.exists() || file.delete()
    }

    private fun extractUris(intent: Intent): List<Uri> {
        val uris = linkedSetOf<Uri>()
        if (intent.action == Intent.ACTION_SEND_MULTIPLE) {
            val list =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM)
                }
            list?.let { uris.addAll(it) }
        } else {
            val single =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra(Intent.EXTRA_STREAM)
                }
            single?.let { uris.add(it) }
        }
        // Some apps only put the URIs in ClipData.
        intent.clipData?.let { clip ->
            for (i in 0 until clip.itemCount) {
                clip.getItemAt(i).uri?.let { uris.add(it) }
            }
        }
        return uris.toList()
    }

    private fun copy(context: Context, uri: Uri, fallbackMime: String?, sharedText: String?): Map<String, Any?> {
        val resolver = context.contentResolver
        var displayName: String? = null
        var declaredSize: Long? = null
        val mime = try {
            resolver.getType(uri) ?: fallbackMime
        } catch (e: SecurityException) {
            fallbackMime
        }

        try {
            resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE), null, null, null)
                ?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                        val sizeIndex = cursor.getColumnIndex(OpenableColumns.SIZE)
                        if (nameIndex >= 0 && !cursor.isNull(nameIndex)) displayName = cursor.getString(nameIndex)
                        if (sizeIndex >= 0 && !cursor.isNull(sizeIndex)) declaredSize = cursor.getLong(sizeIndex)
                    }
                }
        } catch (e: Exception) {
            // Metadata is optional; the copy below is what matters.
            Log.w(TAG, "Could not read file metadata: ${e.javaClass.simpleName}")
        }

        val size = declaredSize
        if (size != null && size > MAX_BYTES) {
            return failure("The file is too large (over 200 MB).", displayName, mime, sharedText)
        }

        val dir = shareDir(context)
        if (!dir.exists() && !dir.mkdirs()) {
            return failure("Could not prepare storage for the file.", displayName, mime, sharedText)
        }
        val available = StatFs(dir.path).availableBytes
        if (size != null && available - size < RESERVE_BYTES) {
            return failure("Not enough free storage to copy the file.", displayName, mime, sharedText)
        }

        val id = UUID.randomUUID().toString()
        val target = File(dir, "$id.${safeExtension(mime)}")
        return try {
            val copied =
                resolver.openInputStream(uri)?.use { input ->
                    FileOutputStream(target).use { output ->
                        val buffer = ByteArray(64 * 1024)
                        var total = 0L
                        while (true) {
                            val read = input.read(buffer)
                            if (read < 0) break
                            total += read
                            if (total > MAX_BYTES) throw IOException("too large")
                            output.write(buffer, 0, read)
                        }
                        total
                    }
                } ?: throw FileNotFoundException("no stream")

            if (copied == 0L) {
                target.delete()
                failure("The shared file is empty.", displayName, mime, sharedText)
            } else {
                payload(id, target.absolutePath, displayName, mime, copied, sharedText, null)
            }
        } catch (e: SecurityException) {
            target.delete()
            failure("Permission to read the file has expired. Share it again.", displayName, mime, sharedText)
        } catch (e: FileNotFoundException) {
            target.delete()
            failure("The shared file could not be opened.", displayName, mime, sharedText)
        } catch (e: IOException) {
            target.delete()
            val message =
                if (e.message == "too large") "The file is too large (over 200 MB)." else "Copying the file failed."
            failure(message, displayName, mime, sharedText)
        }
    }

    /** Extension from the MIME type only; never from the incoming filename. */
    private fun safeExtension(mime: String?): String {
        val ext = mime?.let { MimeTypeMap.getSingleton().getExtensionFromMimeType(it) }
        return if (ext != null && ext.matches(Regex("[a-z0-9]{1,8}"))) ext else "bin"
    }

    private fun failure(message: String, name: String?, mime: String?, sharedText: String?) =
        payload(UUID.randomUUID().toString(), null, name, mime, null, sharedText, message)

    private fun payload(
        id: String,
        path: String?,
        name: String?,
        mime: String?,
        size: Long?,
        sharedText: String?,
        error: String?,
    ): Map<String, Any?> =
        mapOf(
            "id" to id,
            "receivedAt" to System.currentTimeMillis(),
            "cachePath" to path,
            "displayName" to name,
            "mimeType" to mime,
            "sizeBytes" to size,
            "sharedText" to sharedText,
            "error" to error,
        )
}

/** Platform channels for [ShareIntake]. Dart side: lib/core/instances/share_bridge.dart. */
class ShareBridge(private val context: Context) {
    fun attach(messenger: BinaryMessenger) {
        MethodChannel(messenger, "lead_tracker/share").setMethodCallHandler { call, result ->
            when (call.method) {
                "takePending" -> result.success(ShareIntake.takePending())
                "deleteCached" -> {
                    val path = call.argument<String>("path")
                    if (path == null) {
                        result.error("bad_args", "path is required", null)
                    } else {
                        result.success(ShareIntake.deleteCached(context, path))
                    }
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(messenger, "lead_tracker/share/events").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    ShareIntake.onQueued = { events.success(null) }
                    if (ShareIntake.hasPending()) events.success(null)
                }

                override fun onCancel(arguments: Any?) {
                    ShareIntake.onQueued = null
                }
            },
        )
    }
}
