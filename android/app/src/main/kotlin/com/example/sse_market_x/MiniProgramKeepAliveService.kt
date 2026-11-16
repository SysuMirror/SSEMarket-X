package com.susse.market

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

/**
 * 小程序保活服务。
 *
 * 小程序 WebView 在 Flutter 主进程里；用户收起小程序/切到帖子时，这个前台服务
 * 让进程保持存活，音乐/视频可以继续播放。只有用户在小程序菜单里「关闭小程序」
 * 或主站音频条点「关闭音乐」时才停止。
 */
class MiniProgramKeepAliveService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val openApp = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("小程序音频播放中")
            .setContentText("点按返回 App，可暂停或关闭小程序")
            .setSmallIcon(R.drawable.ic_stat_notify)
            .setContentIntent(openApp)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
        startForeground(NOTIFICATION_ID, notification)
        return START_NOT_STICKY
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            if (manager.getNotificationChannel(CHANNEL_ID) == null) {
                manager.createNotificationChannel(
                    NotificationChannel(
                        CHANNEL_ID,
                        "小程序音频播放",
                        NotificationManager.IMPORTANCE_LOW
                    ).apply {
                        description = "仅在小程序播放音频/视频时显示"
                        setShowBadge(false)
                    }
                )
            }
        }
    }

    companion object {
        private const val CHANNEL_ID = "mp_keep_alive_v2"
        private const val NOTIFICATION_ID = 42001
    }
}