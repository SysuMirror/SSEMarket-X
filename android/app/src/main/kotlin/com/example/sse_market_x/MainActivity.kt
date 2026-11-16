package com.susse.market

import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var mpBackGuard = false
    private var mpChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        mpChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "ssemarket/mp_lifecycle"
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        val intent = Intent(this, MiniProgramKeepAliveService::class.java)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    }
                    "stop" -> {
                        stopService(Intent(this, MiniProgramKeepAliveService::class.java))
                        result.success(true)
                    }
                    "setBackGuard" -> {
                        // 小程序打开时接管系统返回/侧滑，避免直接退出 App。
                        mpBackGuard = call.argument<Boolean>("enabled") ?: false
                        result.success(true)
                    }
                    "openActivity" -> {
                        val url = call.argument<String>("url").orEmpty()
                        if (url.isEmpty()) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        val intent = Intent(this, MiniProgramActivity::class.java).apply {
                            putExtra(MiniProgramActivity.EXTRA_URL, url)
                            putExtra(MiniProgramActivity.EXTRA_NAME, call.argument<String>("name"))
                            putExtra(MiniProgramActivity.EXTRA_APP_KEY, call.argument<String>("appKey"))
                            putExtra(MiniProgramActivity.EXTRA_TOKEN, call.argument<String>("token"))
                            addFlags(
                                Intent.FLAG_ACTIVITY_NEW_TASK or
                                    Intent.FLAG_ACTIVITY_NEW_DOCUMENT or
                                    Intent.FLAG_ACTIVITY_MULTIPLE_TASK
                            )
                        }
                        startActivity(intent)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        }
        // 通知权限被永久拒绝时，跳系统通知设置页
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "ssemarket/notifications_settings"
        ).setMethodCallHandler { call, result ->
            if (call.method == "open") {
                try {
                    val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                        .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.success(false)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    @Deprecated("Deprecated in Android 13, kept for legacy back handling")
    override fun onBackPressed() {
        if (mpBackGuard) {
            mpChannel?.invokeMethod("handleBack", null)
            return
        }
        super.onBackPressed()
    }
}