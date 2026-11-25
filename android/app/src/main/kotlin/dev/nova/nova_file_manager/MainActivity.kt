package dev.nova.nova_file_manager

import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.os.StatFs
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.webkit.MimeTypeMap
import androidx.core.content.FileProvider
import be.stef.rar.Unrar5j
import com.github.junrar.Archive
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.apache.commons.compress.archivers.sevenz.SevenZFile
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.CipherInputStream
import javax.crypto.CipherOutputStream
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

// FlutterFragmentActivity is required by local_auth for the biometric prompt.
class MainActivity : FlutterFragmentActivity() {
    private val channelName = "dev.nova.nova_file_manager/storage"
    private val apps by lazy { AppsHelper(this) }

    override fun onDestroy() {
        apps.holdMulticast(false)
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "getSdkInt" -> result.success(Build.VERSION.SDK_INT)
                        "getStorageVolumes" -> result.success(getStorageVolumes())
                        "getStorageStats" -> {
                            val path = call.argument<String>("path")
                            if (path == null) {
                                result.error("ARG", "path required", null)
                            } else {
                                result.success(getStorageStats(path))
                            }
                        }
                        "getInstalledAppCount" -> result.success(getInstalledAppCount())
                        "appsUsageAccess" -> result.success(apps.hasUsageAccess())
                        "appsOpenUsageAccess" -> {
                            apps.openUsageAccess()
                            result.success(true)
                        }
                        "appsList" -> runBg(result) { apps.userApps() }
                        "appsAllPackages" -> runBg(result) { apps.allPackages() }
                        "appsIcon" -> {
                            val pkg = call.argument<String>("pkg") ?: ""
                            runBg(result) { apps.appIcon(pkg, 96) }
                        }
                        "appsIsInstalled" -> result.success(
                            apps.isInstalled(call.argument<String>("pkg") ?: ""),
                        )
                        "appsUninstall" -> {
                            apps.uninstall(call.argument<String>("pkg") ?: "")
                            result.success(true)
                        }
                        "appsOpenInfo" -> {
                            apps.openAppInfo(call.argument<String>("pkg") ?: "")
                            result.success(true)
                        }
                        "appsClearAllCaches" -> result.success(apps.clearAllCaches())
                        "multicastLock" -> {
                            apps.holdMulticast(call.argument<Boolean>("on") ?: true)
                            result.success(true)
                        }
                        "openFile" -> {
                            val path = call.argument<String>("path")
                            if (path == null) {
                                result.error("ARG", "path required", null)
                            } else {
                                result.success(openFile(path))
                            }
                        }
                        "archiveList" -> {
                            val path = call.argument<String>("path")
                            if (path == null) {
                                result.error("ARG", "path required", null)
                            } else {
                                runBg(result) { archiveList(path) }
                            }
                        }
                        "archiveExtract" -> {
                            val path = call.argument<String>("path")
                            val destDir = call.argument<String>("destDir")
                            if (path == null || destDir == null) {
                                result.error("ARG", "path and destDir required", null)
                            } else {
                                runBg(result) {
                                    archiveExtract(path, destDir)
                                    true
                                }
                            }
                        }
                        "apkIcon" -> {
                            val path = call.argument<String>("path")
                            if (path == null) {
                                result.error("ARG", "path required", null)
                            } else {
                                runBg(result) { apkIcon(path) }
                            }
                        }
                        "videoThumb" -> {
                            val path = call.argument<String>("path")
                            if (path == null) {
                                result.error("ARG", "path required", null)
                            } else {
                                runBg(result) { videoThumb(path) }
                            }
                        }
                        "imageJpeg" -> {
                            val path = call.argument<String>("path")
                            val max = call.argument<Int>("max") ?: 320
                            if (path == null) {
                                result.error("ARG", "path required", null)
                            } else {
                                runBg(result) { imageJpeg(path, max) }
                            }
                        }
                        "audioArt" -> {
                            val path = call.argument<String>("path")
                            if (path == null) {
                                result.error("ARG", "path required", null)
                            } else {
                                runBg(result) { audioArt(path) }
                            }
                        }
                        "aesGcm" -> {
                            // Hardware-backed AES-256-GCM for LAN transfer
                            // frames: data = ciphertext||tag on decrypt.
                            val enc = call.argument<Boolean>("enc") ?: true
                            val key = call.argument<ByteArray>("key")
                            val nonce = call.argument<ByteArray>("nonce")
                            val data = call.argument<ByteArray>("data")
                            val aad = call.argument<ByteArray>("aad")
                            if (key == null || nonce == null || data == null) {
                                result.error("ARG", "key, nonce, data required", null)
                            } else {
                                runBg(result) {
                                    val c = javax.crypto.Cipher.getInstance("AES/GCM/NoPadding")
                                    c.init(
                                        if (enc) javax.crypto.Cipher.ENCRYPT_MODE
                                        else javax.crypto.Cipher.DECRYPT_MODE,
                                        javax.crypto.spec.SecretKeySpec(key, "AES"),
                                        javax.crypto.spec.GCMParameterSpec(128, nonce),
                                    )
                                    if (aad != null) c.updateAAD(aad)
                                    c.doFinal(data)
                                }
                            }
                        }
                        "vaultEnsureKey" -> result.success(vaultEnsureKey())
                        "vaultEncrypt" -> {
                            val src = call.argument<String>("src")
                            val dest = call.argument<String>("dest")
                            if (src == null || dest == null) {
                                result.error("ARG", "src and dest required", null)
                            } else {
                                runBg(result) {
                                    vaultEncrypt(src, dest)
                                    true
                                }
                            }
                        }
                        "vaultDecrypt" -> {
                            val src = call.argument<String>("src")
                            val dest = call.argument<String>("dest")
                            if (src == null || dest == null) {
                                result.error("ARG", "src and dest required", null)
                            } else {
                                runBg(result) {
                                    vaultDecrypt(src, dest)
                                    true
                                }
                            }
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("NATIVE", e.message, null)
                }
            }
    }

    /// Extracts an APK/AAB icon as PNG bytes, or null when unavailable.
    private fun apkIcon(path: String): ByteArray? {
        val pm = packageManager
        val info = pm.getPackageArchiveInfo(path, 0) ?: return null
        val app = info.applicationInfo ?: return null
        app.sourceDir = path
        app.publicSourceDir = path
        val drawable = app.loadIcon(pm) ?: return null
        val bmp = Bitmap.createBitmap(
            drawable.intrinsicWidth.coerceAtLeast(1),
            drawable.intrinsicHeight.coerceAtLeast(1),
            Bitmap.Config.ARGB_8888,
        )
        val canvas = Canvas(bmp)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        val out = java.io.ByteArrayOutputStream()
        bmp.compress(Bitmap.CompressFormat.PNG, 100, out)
        return out.toByteArray()
    }

    /// Grabs a video frame (~1 s in) as a small JPEG, or null.
    /// Scaled before encoding — a full-HD PNG frame was ~3 MB and made
    /// every thumbnail slow over the LAN.
    private fun videoThumb(path: String): ByteArray? {
        return try {
            val r = android.media.MediaMetadataRetriever()
            r.setDataSource(path)
            val bmp = if (android.os.Build.VERSION.SDK_INT >= 27) {
                r.getScaledFrameAtTime(
                    1_000_000,
                    android.media.MediaMetadataRetriever.OPTION_CLOSEST_SYNC,
                    320,
                    320,
                )
            } else {
                r.getFrameAtTime(1_000_000)
            }
            r.release()
            if (bmp == null) return null
            jpeg(scaleDown(bmp, 320), 80)
        } catch (e: Exception) {
            null
        }
    }

    /// Any image Android can decode (incl. HEIC/HEIF on Android 9+) as
    /// a JPEG no larger than [max] px — thumbnails and previews for PCs
    /// that can't decode HEIC themselves.
    private fun imageJpeg(path: String, max: Int): ByteArray? {
        return try {
            val bounds = android.graphics.BitmapFactory.Options().apply {
                inJustDecodeBounds = true
            }
            android.graphics.BitmapFactory.decodeFile(path, bounds)
            var sample = 1
            while (bounds.outWidth / (sample * 2) >= max &&
                bounds.outHeight / (sample * 2) >= max) {
                sample *= 2
            }
            val opts = android.graphics.BitmapFactory.Options().apply {
                inSampleSize = sample
            }
            var bmp = android.graphics.BitmapFactory.decodeFile(path, opts)
                ?: return null
            // Respect EXIF rotation (phone photos are often rotated).
            val deg = try {
                when (android.media.ExifInterface(path).getAttributeInt(
                    android.media.ExifInterface.TAG_ORIENTATION,
                    android.media.ExifInterface.ORIENTATION_NORMAL,
                )) {
                    android.media.ExifInterface.ORIENTATION_ROTATE_90 -> 90
                    android.media.ExifInterface.ORIENTATION_ROTATE_180 -> 180
                    android.media.ExifInterface.ORIENTATION_ROTATE_270 -> 270
                    else -> 0
                }
            } catch (e: Exception) {
                0
            }
            if (deg != 0) {
                val m = android.graphics.Matrix().apply { postRotate(deg.toFloat()) }
                bmp = Bitmap.createBitmap(bmp, 0, 0, bmp.width, bmp.height, m, true)
            }
            jpeg(scaleDown(bmp, max), 85)
        } catch (e: Exception) {
            null
        }
    }

    /// Embedded cover art of an audio file as a small JPEG, or null.
    private fun audioArt(path: String): ByteArray? {
        return try {
            val r = android.media.MediaMetadataRetriever()
            r.setDataSource(path)
            val pic = r.embeddedPicture
            r.release()
            if (pic == null) return null
            val bmp = android.graphics.BitmapFactory.decodeByteArray(pic, 0, pic.size)
                ?: return null
            jpeg(scaleDown(bmp, 320), 80)
        } catch (e: Exception) {
            null
        }
    }

    private fun scaleDown(bmp: Bitmap, max: Int): Bitmap {
        val big = maxOf(bmp.width, bmp.height)
        if (big <= max) return bmp
        val f = max.toFloat() / big
        return Bitmap.createScaledBitmap(
            bmp,
            (bmp.width * f).toInt().coerceAtLeast(1),
            (bmp.height * f).toInt().coerceAtLeast(1),
            true,
        )
    }

    private fun jpeg(bmp: Bitmap, q: Int): ByteArray {
        val out = java.io.ByteArrayOutputStream()
        bmp.compress(Bitmap.CompressFormat.JPEG, q, out)
        return out.toByteArray()
    }

    private fun getStorageVolumes(): List<Map<String, Any>> {
        val volumes = mutableListOf<Map<String, Any>>()
        val dirs = getExternalFilesDirs(null)
        dirs.forEachIndexed { index, dir ->
            if (dir == null) return@forEachIndexed
            val isPrimary = index == 0
            val root: File = if (isPrimary) {
                Environment.getExternalStorageDirectory()
            } else {
                val suffix = "/Android/data/$packageName/files"
                val abs = dir.absolutePath
                if (abs.endsWith(suffix)) File(abs.removeSuffix(suffix)) else dir
            }
            val removable = try {
                Environment.isExternalStorageRemovable(dir)
            } catch (e: Exception) {
                !isPrimary
            }
            if (!volumes.any { it["path"] == root.absolutePath }) {
                volumes.add(
                    mapOf(
                        "label" to if (isPrimary) "Internal storage" else "SD card" + if (index > 1) " $index" else "",
                        "path" to root.absolutePath,
                        "isPrimary" to isPrimary,
                        "isRemovable" to removable,
                    )
                )
            }
        }
        return volumes
    }

    private fun getStorageStats(path: String): Map<String, Any> {
        val stat = StatFs(path)
        return mapOf(
            "totalBytes" to stat.totalBytes,
            "freeBytes" to stat.freeBytes,
            "availableBytes" to stat.availableBytes,
        )
    }

    private fun getInstalledAppCount(): Int {
        val pm = packageManager
        val packages = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getInstalledPackages(PackageManager.PackageInfoFlags.of(0))
        } else {
            @Suppress("DEPRECATION")
            pm.getInstalledPackages(0)
        }
        return packages.size
    }

    /// Opens a file with the best matching system app. Returns false if no
    /// app can handle it.
    private fun openFile(path: String): Boolean {
        val file = File(path)
        val ext = file.extension.lowercase()
        val mime = MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext) ?: "*/*"
        val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, mime)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        return try {
            startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }

    /// Runs [block] on a worker thread and delivers the result on the main
    /// thread (MethodChannel requirement).
    private fun runBg(result: MethodChannel.Result, block: () -> Any?) {
        Thread {
            try {
                val out = block()
                Handler(Looper.getMainLooper()).post { result.success(out) }
            } catch (e: Exception) {
                android.util.Log.e("NovaMain", "native call failed", e)
                Handler(Looper.getMainLooper()).post {
                    result.error("NATIVE", e.stackTraceToString(), null)
                }
            }
        }.start()
    }

    private fun archiveList(path: String): List<Map<String, Any>> {
        val entries = mutableListOf<Map<String, Any>>()
        val file = File(path)
        when (file.extension.lowercase()) {
            "7z" -> SevenZFile.builder().setFile(file).get().use { z ->
                var e = z.nextEntry
                while (e != null) {
                    entries.add(
                        mapOf(
                            "name" to e.name,
                            "size" to e.size,
                            "isDir" to e.isDirectory,
                        )
                    )
                    e = z.nextEntry
                }
            }
            "rar" -> if (isRar5(file)) {
                entries.addAll(listViaUnrar5j(file))
            } else {
                Archive(file).use { a ->
                    var h = a.nextFileHeader()
                    while (h != null) {
                        entries.add(
                            mapOf(
                                "name" to h.fileName,
                                "size" to h.fullUnpackSize,
                                "isDir" to h.isDirectory,
                            )
                        )
                        h = a.nextFileHeader()
                    }
                }
            }
            else -> throw IllegalArgumentException(
                "Unsupported archive type: ${file.extension}"
            )
        }
        return entries
    }

    private fun archiveExtract(path: String, destDir: String) {
        val file = File(path)
        val dest = File(destDir).canonicalFile
        when (file.extension.lowercase()) {
            "7z" -> SevenZFile.builder().setFile(file).get().use { z ->
                var e = z.nextEntry
                while (e != null) {
                    val out = safeChild(dest, e.name)
                    if (e.isDirectory) {
                        out.mkdirs()
                    } else {
                        out.parentFile?.mkdirs()
                        FileOutputStream(out).use { fos ->
                            val buf = ByteArray(64 * 1024)
                            var n = z.read(buf)
                            while (n > 0) {
                                fos.write(buf, 0, n)
                                n = z.read(buf)
                            }
                        }
                    }
                    e = z.nextEntry
                }
            }
            "rar" -> if (isRar5(file)) {
                extractViaUnrar5j(file, dest)
            } else {
                Archive(file).use { a ->
                    var h = a.nextFileHeader()
                    while (h != null) {
                        val out = safeChild(dest, h.fileName)
                        if (h.isDirectory) {
                            out.mkdirs()
                        } else {
                            out.parentFile?.mkdirs()
                            FileOutputStream(out).use { fos ->
                                a.extractFile(h, fos)
                            }
                        }
                        h = a.nextFileHeader()
                    }
                }
            }
            else -> throw IllegalArgumentException(
                "Unsupported archive type: ${file.extension}"
            )
        }
    }

    /// RAR5 signature: 52 61 72 21 1A 07 01 00 (RAR4 has 00 at byte 6).
    private fun isRar5(file: File): Boolean {
        file.inputStream().use { s ->
            val head = ByteArray(8)
            if (s.read(head) < 8) return false
            return head[6].toInt() == 1 && head[7].toInt() == 0
        }
    }

    /// unrar5j has no listing API — extract to a temp dir, collect names and
    /// sizes, then delete it. Used only for RAR5 (junrar covers RAR4).
    private fun listViaUnrar5j(file: File): List<Map<String, Any>> {
        val tmp = File(cacheDir, "rarlist_${file.hashCode()}")
        try {
            extractViaUnrar5j(file, tmp)
            val base = tmp.canonicalPath + File.separator
            return tmp.walkTopDown().drop(1).map { f ->
                mapOf(
                    "name" to f.canonicalPath.removePrefix(base)
                        .replace(File.separatorChar, '/'),
                    "size" to (if (f.isFile) f.length() else 0L),
                    "isDir" to f.isDirectory,
                )
            }.toList()
        } finally {
            tmp.deleteRecursively()
        }
    }

    private fun extractViaUnrar5j(file: File, dest: File) {
        dest.mkdirs()
        val result = Unrar5j.extract(file.absolutePath, dest.absolutePath, null)
        if (result.errorCount > 0 || result.passwordStatus == 2) {
            throw IllegalStateException(
                "RAR extract failed for ${file.name} " +
                    "(encrypted or corrupt archive)"
            )
        }
    }

    // --- Vault: AES-256-GCM with an Android Keystore key ---

    private val vaultAlias = "nova_vault_key"

    private fun vaultEnsureKey(): Boolean {
        val ks = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        if (!ks.containsAlias(vaultAlias)) {
            val kg = KeyGenerator.getInstance(
                KeyProperties.KEY_ALGORITHM_AES,
                "AndroidKeyStore",
            )
            kg.init(
                KeyGenParameterSpec.Builder(
                    vaultAlias,
                    KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
                )
                    .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                    .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                    .setKeySize(256)
                    .build()
            )
            kg.generateKey()
        }
        return true
    }

    private fun vaultKey(): SecretKey {
        val ks = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        return ks.getKey(vaultAlias, null) as SecretKey
    }

    /// Output layout: [12-byte IV][ciphertext+GCM tag].
    private fun vaultEncrypt(src: String, dest: String) {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, vaultKey())
        FileInputStream(src).use { inp ->
            FileOutputStream(dest).use { out ->
                out.write(cipher.iv)
                CipherOutputStream(out, cipher).use { c -> inp.copyTo(c) }
            }
        }
    }

    private fun vaultDecrypt(src: String, dest: String) {
        FileInputStream(src).use { inp ->
            val iv = ByteArray(12)
            if (inp.read(iv) != 12) {
                throw IllegalStateException("Vault file too short: $src")
            }
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.DECRYPT_MODE, vaultKey(), GCMParameterSpec(128, iv))
            FileOutputStream(dest).use { out ->
                CipherInputStream(inp, cipher).use { c -> c.copyTo(out) }
            }
        }
    }

    /// Guards against zip-slip: entry names must not escape [dest].
    private fun safeChild(dest: File, entryName: String): File {
        val out = File(dest, entryName).canonicalFile
        if (!out.path.startsWith(dest.path + File.separator)) {
            throw SecurityException("Archive entry escapes destination: $entryName")
        }
        return out
    }
}
