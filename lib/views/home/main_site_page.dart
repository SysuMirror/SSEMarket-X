import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:sse_market_x/core/services/storage_service.dart';
import 'package:sse_market_x/shared/theme/app_colors.dart';

/// 主站 H5 功能页（小秋等）。
///
/// 小秋明确是主站功能，不走小程序生命周期；这里加载主站页面，并只在
/// `ssemarket.cn` 同源下注入主站 refreshToken 完成免登录。
class MainSitePage extends StatefulWidget {
  final String title;
  final String path;

  const MainSitePage({
    super.key,
    required this.title,
    required this.path,
  });

  @override
  State<MainSitePage> createState() => _MainSitePageState();
}

class _MainSitePageState extends State<MainSitePage> {
  WebViewController? _controller;
  bool _supported = false;
  bool _loading = true;
  bool _reloadedForAuth = false;
  String? _error;

  String get _url => 'https://ssemarket.cn${widget.path}';

  @override
  void initState() {
    super.initState();
    _supported = !kIsWeb &&
        (Platform.isAndroid ||
            Platform.isIOS ||
            Platform.operatingSystem == 'ohos');
    if (_supported) _init();
  }

  Future<void> _init() async {
    final controller = WebViewController();
    setState(() => _controller = controller);
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (_) => _injectAuth(controller),
        onPageFinished: (url) async {
          await _injectAuth(controller);
          if (!mounted) return;
          setState(() => _loading = false);
          if (!_reloadedForAuth &&
              url.contains('/auth/login') &&
              StorageService().isLoggedIn) {
            _reloadedForAuth = true;
            await _injectAuth(controller);
            await controller.reload();
          }
        },
        onWebResourceError: (error) {
          if (!mounted) return;
          if (!(error.isForMainFrame ?? true)) return;
          setState(() {
            _loading = false;
            _error = error.description;
          });
        },
      ),
    );
    await controller.loadRequest(Uri.parse(_url));
  }

  Future<void> _injectAuth(WebViewController controller) async {
    final storage = StorageService();
    if (!storage.isLoggedIn || storage.refreshToken.isEmpty) return;
    final token = jsonEncode(storage.refreshToken);
    final expiry = storage.refreshTokenExpiry;
    final script = '''
      try {
        localStorage.setItem('rememberMe', 'true');
        localStorage.setItem('refreshToken', $token);
        localStorage.setItem('refreshTokenExpiry', '$expiry');
      } catch (e) {}
    ''';
    try {
      await controller.runJavaScript(script);
    } catch (_) {}
  }

  Future<void> _openBrowser() async {
    await launchUrl(Uri.parse(_url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimaryColor),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: context.textPrimaryColor,
          ),
        ),
        actions: [
          IconButton(
            tooltip: '在浏览器打开',
            icon: Icon(Icons.open_in_browser_rounded,
                color: context.textPrimaryColor),
            onPressed: _openBrowser,
          ),
        ],
      ),
      body: !_supported
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.language_rounded,
                        size: 52, color: context.textTertiaryColor),
                    const SizedBox(height: 12),
                    Text(
                      '当前平台暂不支持内嵌主站页面',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _openBrowser,
                      icon: const Icon(Icons.open_in_browser_rounded, size: 18),
                      label: const Text('在浏览器打开'),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                if (_controller != null)
                  WebViewWidget(controller: _controller!),
                if (_loading) const Center(child: CircularProgressIndicator()),
                if (_error != null)
                  Positioned.fill(
                    child: ColoredBox(
                      color: context.surfaceColor,
                      child: Center(
                        child: Text(
                          '页面加载失败：$_error',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
