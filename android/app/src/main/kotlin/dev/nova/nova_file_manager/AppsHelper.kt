package dev.nova.nova_file_manager

import android.app.Activity
import android.app.AppOpsManager
import android.app.usage.StorageStatsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Process
import android.os.storage.StorageManager
import android.provider.Settings

/// Installed-apps screen + cleanup helpers.
///
/// Note on caches: Android lets no regular app clear another app's
/// cache. What is possible (and done here): read cache sizes (needs
/// "Usage access"), ask the system to clear ALL apps' caches at once
/// (Android 11+, system confirmation), and open an app's settings page
/// where the user can clear one app. Uninstalling removes the app's
/// cache and private data automatically.
class AppsHelper(private val activity: Activity) {
    private val pm: PackageManager get() = activity.packageManager

    fun hasUsageAccess(): Boolean {
        val ops = activity.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= 29) {
            ops.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                activity.packageName,
            )
        } else {
            @Suppress("DEPRECATION")
            ops.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                activity.packageName,
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    fun openUsageAccess() {
        val i = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        try {
            i.data = Uri.parse("package:${activity.packageName}")
            activity.startActivity(i)
        } catch (e: Exception) {
            activity.startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
        }
    }

    private fun installed(): List<ApplicationInfo> =
        if (Build.VERSION.SDK_INT >= 33) {
            pm.getInstalledApplications(PackageManager.ApplicationInfoFlags.of(0))
        } else {
            @Suppress("DEPRECATION")
            pm.getInstalledApplications(0)
        }

    /// Every installed package name (system apps included) — used to spot
    /// folders left behind by apps that are gone.
    fun allPackages(): List<String> = installed().map { it.packageName }

    /// User-installed apps with version, sizes and last-used time.
    fun userApps(): List<Map<String, Any?>> {
        val usage = hasUsageAccess()
        val lastUsed = mutableMapOf<String, Long>()
        if (usage) {
            try {
                val usm = activity.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
                val now = System.currentTimeMillis()
                usm.queryAndAggregateUsageStats(now - 1000L * 60 * 60 * 24 * 730, now)
                    .forEach { (pkg, st) -> lastUsed[pkg] = st.lastTimeUsed }
            } catch (_: Exception) {
            }
        }
        val ssm = if (Build.VERSION.SDK_INT >= 26 && usage) {
            activity.getSystemService(Context.STORAGE_STATS_SERVICE) as StorageStatsManager
        } else {
            null
        }
        val out = mutableListOf<Map<String, Any?>>()
        for (ai in installed()) {
            if (ai.flags and ApplicationInfo.FLAG_SYSTEM != 0) continue
            if (ai.packageName == activity.packageName) continue
            val info = try {
                if (Build.VERSION.SDK_INT >= 33) {
                    pm.getPackageInfo(ai.packageName, PackageManager.PackageInfoFlags.of(0))
                } else {
                    @Suppress("DEPRECATION")
                    pm.getPackageInfo(ai.packageName, 0)
                }
            } catch (_: Exception) {
                continue
            }
            var appBytes: Long? = null
            var dataBytes: Long? = null
            var cacheBytes: Long? = null
            if (ssm != null && Build.VERSION.SDK_INT >= 26) {
                try {
                    val st = ssm.queryStatsForPackage(
                        ai.storageUuid,
                        ai.packageName,
                        Process.myUserHandle(),
                    )
                    appBytes = st.appBytes
                    dataBytes = st.dataBytes
                    cacheBytes = st.cacheBytes
                } catch (_: Exception) {
                }
            }
            val apk = try {
                java.io.File(ai.sourceDir).length() +
                    (ai.splitSourceDirs?.sumOf { java.io.File(it).length() } ?: 0L)
            } catch (_: Exception) {
                0L
            }
            val lu = lastUsed[ai.packageName]
            out.add(
                mapOf(
                    "pkg" to ai.packageName,
                    "name" to pm.getApplicationLabel(ai).toString(),
                    "version" to (info.versionName ?: ""),
                    "installed" to info.firstInstallTime,
                    "updated" to info.lastUpdateTime,
                    "apkBytes" to apk,
                    "appBytes" to appBytes,
                    "dataBytes" to dataBytes,
                    "cacheBytes" to cacheBytes,
                    "lastUsed" to (if (lu != null && lu > 0) lu else null),
                ),
            )
        }
        return out
    }

    fun appIcon(pkg: String, size: Int): ByteArray? = try {
        val d = pm.getApplicationIcon(pkg)
        val bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp)
        d.setBounds(0, 0, size, size)
        d.draw(c)
        val out = java.io.ByteArrayOutputStream()
        bmp.compress(Bitmap.CompressFormat.PNG, 100, out)
        out.toByteArray()
    } catch (_: Exception) {
        null
    }

    fun isInstalled(pkg: String): Boolean = try {
        pm.getApplicationInfo(pkg, 0)
        true
    } catch (_: Exception) {
        false
    }

    /// System uninstall dialog (the system asks the user to confirm).
    fun uninstall(pkg: String) {
        val i = Intent(Intent.ACTION_DELETE, Uri.parse("package:$pkg"))
        activity.startActivity(i)
    }

    fun openAppInfo(pkg: String) {
        val i = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$pkg"))
        activity.startActivity(i)
    }

    /// Android 11+: system dialog that clears the cache of every app.
    /// Needs "All files access". Returns false when unavailable.
    fun clearAllCaches(): Boolean {
        if (Build.VERSION.SDK_INT < 30) return false
        return try {
            @Suppress("DEPRECATION")
            activity.startActivityForResult(Intent(StorageManager.ACTION_CLEAR_APP_CACHE), 4711)
            true
        } catch (_: Exception) {
            false
        }
    }

    private var multicast: WifiManager.MulticastLock? = null

    /// Many phones drop LAN broadcast packets unless a multicast lock is
    /// held — without it other devices' discovery probes never arrive.
    fun holdMulticast(on: Boolean) {
        try {
            if (on) {
                if (multicast == null) {
                    val wm = activity.applicationContext
                        .getSystemService(Context.WIFI_SERVICE) as WifiManager
                    multicast = wm.createMulticastLock("nova-lan").apply {
                        setReferenceCounted(false)
                        acquire()
                    }
                }
            } else {
                multicast?.release()
                multicast = null
            }
        } catch (_: Exception) {
        }
    }
}
