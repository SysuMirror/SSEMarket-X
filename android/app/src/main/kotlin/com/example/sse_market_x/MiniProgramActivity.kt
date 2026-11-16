package com.susse.market

import android.app.Activity
import android.app.ActivityManager
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.webkit.CookieManager
import android.webkit.JavascriptInterface
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.FrameLayout
import android.widget.ImageButton
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import org.json.JSONObject

/**
 * 小程序独立任务窗口。
 *
 * 小程序在最近任务里是独立的一张卡片（类似微信小程序），不再叠在主 App 的
 * Activity 上。页面仍使用系统 WebView；登录态由平台 SSO / App 注入的临时 token 提供。
 */
class MiniProgramActivity : Activity() {
    private lateinit var webView: WebView
    private var appName: String = "小程序"
    private var appKey: String = ""
    private var token: String = ""
    private var mediaPlaying = false

    companion object {
        const val EXTRA_URL = "mp_url"
        const val EXTRA_NAME = "mp_name"
        const val EXTRA_APP_KEY = "mp_app_key"
        const val EXTRA_TOKEN = "mp_token"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        appName = intent.getStringExtra(EXTRA_NAME) ?: "小程序"
        appKey = intent.getStringExtra(EXTRA_APP_KEY) ?: ""
        token = intent.getStringExtra(EXTRA_TOKEN).orEmpty()
        val url = intent.getStringExtra(EXTRA_URL).orEmpty()
        if (url.isEmpty()) {
            finish()
            return
        }

        // Android 15+ 强制 edge-to-edge：让白色背景铺到状态栏/刘海区域，
// 再用系统栏 insets 给工具栏留出安全区，避免水滴屏/挖孔屏出现黑条。
        WindowCompat.setDecorFitsSystemWindows(window, false)
        window.decorView.setBackgroundColor(Color.WHITE)
        WindowInsetsControllerCompat(window, window.decorView).apply {
            isAppearanceLightStatusBars = true
            isAppearanceLightNavigationBars = true
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            setTaskDescription(ActivityManager.TaskDescription(appName))
        }

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.WHITE)
        }
        ViewCompat.setOnApplyWindowInsetsListener(root) { view, insets ->
            val bars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            view.setPadding(0, bars.top, 0, bars.bottom)
            insets
        }
        root.addView(buildToolbar())
        webView = WebView(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                0,
                1f
            )
            settings.javaScriptEnabled = true
            settings.domStorageEnabled = true
            settings.databaseEnabled = true
            settings.mediaPlaybackRequiresUserGesture = false
            settings.loadsImagesAutomatically = true
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                settings.mixedContentMode = android.webkit.WebSettings.MIXED_CONTENT_NEVER_ALLOW
            }
            CookieManager.getInstance().setAcceptCookie(true)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                CookieManager.getInstance().setAcceptThirdPartyCookies(this, true)
            }
            addJavascriptInterface(Bridge(), "mpBridge")
            webViewClient = object : WebViewClient() {
                override fun shouldOverrideUrlLoading(
                    view: WebView?,
                    request: WebResourceRequest?
                ): Boolean {
                    val next = request?.url ?: return false
                    val host = next.host ?: return true
                    if (isAllowed(host)) return false
                    try {
                        startActivity(Intent(Intent.ACTION_VIEW, next))
                    } catch (_: Exception) {
                    }
                    return true
                }

                override fun onPageStarted(view: WebView?, url: String?, favicon: android.graphics.Bitmap?) {
                    super.onPageStarted(view, url, favicon)
                    if (url != null) injectToken(url)
                }

                override fun onPageFinished(view: WebView?, url: String?) {
                    super.onPageFinished(view, url)
                    injectMediaHook()
                }
            }
            loadUrl(url)
        }
        root.addView(webView)
        setContentView(root)
    }

    private fun buildToolbar(): View {
        val bar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setBackgroundColor(Color.WHITE)
            setPadding(dp(4), dp(4), dp(4), dp(4))
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                dp(52)
            )
        }
        val back = ImageButton(this).apply {
            setBackgroundColor(Color.TRANSPARENT)
            setImageResource(R.drawable.ic_mp_back)
            contentDescription = "返回"
            setOnClickListener { goBack() }
        }
        bar.addView(back, LinearLayout.LayoutParams(dp(44), dp(44)))
        val title = TextView(this).apply {
            text = appName
            textSize = 16f
            setTextColor(Color.rgb(17, 24, 39))
            gravity = Gravity.CENTER
            maxLines = 1
            ellipsize = android.text.TextUtils.TruncateAt.END
        }
        bar.addView(title, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, 1f))
        val more = TextView(this).apply {
            text = "···"
            textSize = 22f
            setTextColor(Color.rgb(55, 65, 81))
            gravity = Gravity.CENTER
            setOnClickListener { showCloseDialog() }
            contentDescription = "更多"
        }
        bar.addView(more, LinearLayout.LayoutParams(dp(44), dp(44)))
        return bar
    }

    private fun showCloseDialog() {
        android.app.AlertDialog.Builder(this)
            .setTitle(appName)
            .setMessage("关闭后会停止小程序内的播放和页面。")
            .setNegativeButton("继续使用", null)
            .setPositiveButton("关闭小程序") { _, _ -> finish() }
            .show()
    }

    private fun isAllowed(host: String): Boolean {
        return host == "applet.ssemarket.cn" ||
            host == "ssemarket.cn" ||
            host == "sso.ssemarket.cn" ||
            host.endsWith(".ssemarket.cn")
    }

    private fun injectToken(url: String) {
        if (!url.contains("applet.ssemarket.cn/mp/") || token.isEmpty()) return
        val encoded = JSONObject.quote(token)
        val js = """
            (function(){
              try {
                var t = $encoded;
                window.__SSE_MAIN_TOKEN__ = t;
                if (typeof window.__setSSEAppToken === 'function') window.__setSSEAppToken(t);
                window.dispatchEvent(new Event('sse-main-token'));
              } catch(e) {}
            })();
        """.trimIndent()
        webView.evaluateJavascript(js, null)
    }

    private fun injectMediaHook() {
        val js = """
            (function(){
              try {
                if (window.__mpMediaHooked) return;
                window.__mpMediaHooked = true;
                function report(){
                  try {
                    var ms = Array.prototype.slice.call(document.querySelectorAll('audio,video'));
                    var playing = ms.some(function(m){ return !m.paused && !m.ended && m.readyState >= 2; });
                    if (window.mpBridge && window.mpBridge.postMessage) {
                      window.mpBridge.postMessage(JSON.stringify({type:'mp.event',event:'media-state',payload:{playing:playing,count:ms.length}}));
                    }
                  } catch(e) {}
                }
                ['play','pause','ended','volumechange'].forEach(function(ev){
                  document.addEventListener(ev, report, true);
                });
                setInterval(report, 2000);
                report();
              } catch(e) {}
            })();
        """.trimIndent()
        webView.evaluateJavascript(js, null)
    }

    inner class Bridge {
        @JavascriptInterface
        fun postMessage(message: String) {
            try {
                val start = message.indexOf('{')
                val end = message.lastIndexOf('}')
                if (start < 0 || end <= start) return
                val obj = JSONObject(message.substring(start, end + 1))
                if (obj.optString("type") != "mp.event") return
                when (obj.optString("event")) {
                    "close" -> runOnUiThread { finish() }
                    "media-state" -> {
                        val playing = obj.optJSONObject("payload")?.optBoolean("playing") == true
                        if (playing != mediaPlaying) {
                            mediaPlaying = playing
                            runOnUiThread {
                                val intent = Intent(this@MiniProgramActivity, MiniProgramKeepAliveService::class.java)
                                if (playing) {
                                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                        startForegroundService(intent)
                                    } else {
                                        startService(intent)
                                    }
                                } else {
                                    stopService(intent)
                                }
                            }
                        }
                    }
                    "open-url" -> {
                        val url = obj.optJSONObject("payload")?.optString("url").orEmpty()
                        if (url.isNotEmpty()) {
                            runOnUiThread {
                                try { startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url))) } catch (_: Exception) {}
                            }
                        }
                    }
                }
            } catch (_: Exception) {
            }
        }
    }

    private fun goBack() {
        if (this::webView.isInitialized && webView.canGoBack()) {
            webView.goBack()
        } else {
            finish()
        }
    }

    @Deprecated("Deprecated in Android 13, kept for legacy back handling")
    override fun onBackPressed() {
        goBack()
    }

    override fun onDestroy() {
        if (mediaPlaying) {
            stopService(Intent(this, MiniProgramKeepAliveService::class.java))
        }
        if (this::webView.isInitialized) {
            webView.stopLoading()
            webView.loadUrl("about:blank")
            webView.destroy()
        }
        super.onDestroy()
    }

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()
}