package com.waterman_iattandance

import io.flutter.embedding.android.FlutterActivity

import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.BatteryManager
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "mytime/native_battery"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getBatteryStatus" -> result.success(getBatteryStatus())
                "getUnusedAppSettingStatus" -> result.success(getUnusedAppSettingStatus())
                else -> result.notImplemented()
            }
        }
    }

    private fun getBatteryStatus(): Map<String, Any> {
        val intent = registerReceiver(
            null,
            IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        )

        val level = intent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale = intent?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        val status = intent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1

        val percentage =
            if (level >= 0 && scale > 0) (level * 100) / scale else -1

        val state = when (status) {
            BatteryManager.BATTERY_STATUS_CHARGING -> "charging"
            BatteryManager.BATTERY_STATUS_DISCHARGING -> "discharging"
            BatteryManager.BATTERY_STATUS_FULL -> "full"
            BatteryManager.BATTERY_STATUS_NOT_CHARGING -> "not_charging"
            else -> "unknown"
        }

        return mapOf(
            "level" to percentage,
            "state" to state
        )
    }

    /**
     * Returns whether the system's "Remove permissions if app is unused"
     * setting is active for this app (Android 12+ / API 32+).
     * Returns false on older Android versions.
     */
    private fun getUnusedAppSettingStatus(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            try {
                val pm = packageManager
                val appInfo = pm.getApplicationInfo(packageName, 0)
                // AUTO_REVOKE_PERMISSIONS_IF_UNUSED was added in API 30
                // getUnusedAppRestrictionsStatus is available in PackageManager on API 32+
                val flags = pm.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
                // If auto-revoke is not explicitly disabled, it is considered active
                (flags.flags and android.content.pm.ApplicationInfo.FLAG_ALLOW_BACKUP) == 0
            } catch (e: Exception) {
                false
            }
        } else {
            false
        }
    }
}

