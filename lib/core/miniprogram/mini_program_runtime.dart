import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:sse_market_x/core/miniprogram/mp_platform_api.dart';
import 'package:sse_market_x/core/services/storage_service.dart';

class _CachedTicket {
  _CachedTicket(this.ticket, this.fetchedAt);

  final MPLaunchTicket ticket;
  final DateTime fetchedAt;

  bool get fresh => DateTime.now().difference(fetchedAt) <
      const Duration(seconds: 45);
}

/// 内置/兜底小程序定义。
///
/// 平台目录正常时以 `/v1/apps` 为准；这里只在目录为空或网络失败时兜底展示，
/// 真正的打开仍然走 launch ticket，不会绕过平台鉴权。
class MPFallbackApps {
  static const List<MPApp> apps = <MPApp>[
    MPApp(
      appKey: 'novel',
      name: '小说',
      icon: 'tabler:book-2',
      category: 'content',
      allowedOrigins: <String>['https://applet.ssemarket.cn'],
    ),
    MPApp(
      appKey: 'ranking',
      name: '排行榜',
      icon: 'tabler:trophy',
      category: 'content',
      allowedOrigins: <String>['https://applet.ssemarket.cn'],
    ),
    MPApp(
      appKey: 'resume',
      name: '简历',
      icon: 'tabler:file-cv',
      category: 'tool',
      allowedOrigins: <String>['https://applet.ssemarket.cn'],
    ),
    MPApp(
      appKey: 'media',
      name: '音乐视频',
      icon: 'tabler:disc',
      category: 'content',
      allowedOrigins: <String>['https://applet.ssemarket.cn'],
    ),
    MPApp(
      appKey: 'shop',
      name: '商城',
      icon: 'tabler:shopping-bag',
      category: 'shopping',
      allowedOrigins: <String>['https://applet.ssemarket.cn'],
    ),
    MPApp(
      appKey: 'course',
      name: '课程专区',
      icon: 'tabler:book',
      category: 'content',
      allowedOrigins: <String>['https://applet.ssemarket.cn'],
    ),
  ];

  static MPApp? byKey(String key) {
    for (final app in apps) {
      if (app.appKey == key) return app;
    }
    return null;
  }
}

/// 小程序运行时（全局单例）。
///
/// - WebView 只加载平台返回的 launchURL；官方内部小程序页（`applet.ssemarket.cn/mp/`）
///   会注入主站 access token 以复用 App 登录态（不注入 refresh token，不写 localStorage）；
/// - `hide()` 只隐藏容器，WebView 与音频继续运行；
/// - `destroy()` 才是真正关闭（暂停媒体、停止保活服务、释放 WebView）；
/// - Android 侧通过 `ssemarket/mp_lifecycle` 启动前台保活服务。
class MiniProgramRuntime extends ChangeNotifier {
  static final MiniProgramRuntime _instance = MiniProgramRuntime._internal();
  factory MiniProgramRuntime() => _instance;
  MiniProgramRuntime._internal() {
    // 原生返回键/侧滑返回：小程序打开时先交给 WebView 历史，再收起面板，
    // 而不是直接退出 App。
    _lifecycle.setMethodCallHandler((call) async {
      if (call.method == 'handleBack') {
        await handleBack();
        return true;
      }
      return null;
    });
  }

  static const MethodChannel _lifecycle =
      MethodChannel('ssemarket/mp_lifecycle');

  final MPPlatformApi api = MPPlatformApi();

  WebViewController? _controller;
  MPApp? _app;
  bool _open = false;
  bool _loading = false;
  bool _mediaPlaying = false;
  String? _error;
  bool _keepAliveStarted = false;

  /// 启动票据缓存。打开小程序的点击延迟主要来自申请票据的网络往返；
  /// 面板打开时就把可见小程序的票据取好，点击时直接开窗口/Activity。
  /// 票据 60 秒一次性有效，这里只缓存 45 秒，且取出后立即失效。
  final Map<String, _CachedTicket> _ticketCache = <String, _CachedTicket>{};
  final Map<String, Future<MPLaunchTicket>> _ticketRequests =
      <String, Future<MPLaunchTicket>>{};

  MPApp? get app => _app;
  WebViewController? get controller => _controller;
  bool get isOpen => _open;
  bool get isLoading => _loading;
  bool get mediaPlaying => _mediaPlaying;
  String? get error => _error;
  bool get hasController => _controller != null;

  bool get supported {
    if (kIsWeb) return false;
    return Platform.isAndroid ||
        Platform.isIOS ||
        Platform.operatingSystem == 'ohos';
  }

  Future<MPApp> resolveApp(String appKey) async {
    try {
      final apps = await api.catalog();
      for (final app in apps) {
        if (app.appKey == appKey) return app;
      }
    } catch (_) {}
    return MPFallbackApps.byKey(appKey) ??
        MPApp(
          appKey: appKey,
          name: appKey,
          allowedOrigins: const <String>['https://applet.ssemarket.cn'],
        );
  }

  Future<void> openByKey(String appKey, {String? name}) async {
    final app = await resolveApp(appKey);
    await open(app);
  }

  /// 票据同时绑定 appKey 与 origin，缓存键必须把两者都带上，
  /// 否则外部托管小程序的票据会被错误复用。
  String _ticketKey(MPApp app) => '${app.appKey}|${app.origin}';

  /// 面板/首页出现时预热票据。失败静默，真正打开时还会再请求一次。
  void prefetchTickets(Iterable<MPApp> apps) {
    if (StorageService().token.isEmpty) return;
    for (final app in apps) {
      if (app.appKey.isEmpty) continue;
      final key = _ticketKey(app);
      final cached = _ticketCache[key];
      if (cached != null && cached.fresh) continue;
      unawaited(_fetchTicket(app).then<void>(
        (_) {},
        onError: (Object _) => _ticketCache.remove(key),
      ));
    }
  }

  Future<MPLaunchTicket> _fetchTicket(MPApp app) {
    final key = _ticketKey(app);
    final existing = _ticketRequests[key];
    if (existing != null) return existing;
    final future = api
        .launchTicket(
          appKey: app.appKey,
          origin: app.origin.isNotEmpty ? app.origin : null,
        )
        .then((ticket) {
      _ticketCache[key] = _CachedTicket(ticket, DateTime.now());
      return ticket;
    }).whenComplete(() => _ticketRequests.remove(key));
    _ticketRequests[key] = future;
    return future;
  }

  Future<MPLaunchTicket> _takeTicket(MPApp app) async {
    final cached = _ticketCache.remove(_ticketKey(app));
    if (cached != null && cached.fresh) {
      return cached.ticket;
    }
    return _fetchTicket(app);
  }

  Future<void> open(MPApp app) async {
    unawaited(_logDesktopOpen('runtime.open appKey=${app.appKey} name=${app.name}'));

    // 桌面端没有 Flutter 内嵌 WebView：在独立的浏览器窗口中打开小程序，
    // 与主 App 窗口互不干扰；Android 则使用独立 Activity/任务卡片。
    final desktopExternal = kIsWeb ||
        Platform.isWindows ||
        Platform.isLinux ||
        Platform.isMacOS;

    _app = app;
    // 桌面端永远不在主窗口上叠加载入遮罩：开窗是外部进程完成的，
    // 主窗口保持原样，避免出现“点了小程序后主窗口一直转圈”。
    _open = !desktopExternal;
    _error = null;
    _loading = true;
    notifyListeners();
    if (_open) _setBackGuard(true);

    if (!supported && !desktopExternal) {
      _error = '当前平台暂不支持内嵌小程序';
      _loading = false;
      notifyListeners();
      return;
    }

    try {
      unawaited(_logDesktopOpen('request launchTicket appKey=${app.appKey}'));
      final ticket = await _takeTicket(app);
      unawaited(_logDesktopOpen('launchTicket ok appKey=${app.appKey} url=${ticket.launchUrl}'));
      final effectiveApp = ticket.app ?? app;
      _app = effectiveApp;
      final uri = Uri.parse(ticket.launchUrl);
      if (!_isAllowed(effectiveApp, uri)) {
        throw MPException(
            400, 'ORIGIN_MISMATCH', 'launchURL 不在允许的 origin 内', null);
      }

      if (desktopExternal) {
        await _openDesktopWindow(uri);
        _open = false;
        _loading = false;
        notifyListeners();
        return;
      }

      // Android：用独立 Activity + 独立最近任务卡片打开（类似微信小程序），
      // 不再把 WebView 叠在主 App 的 Activity 上。
      if (Platform.isAndroid) {
        final launched = await _lifecycle.invokeMethod<bool>(
          'openActivity',
          <String, dynamic>{
            'url': uri.toString(),
            'name': effectiveApp.name,
            'appKey': effectiveApp.appKey,
            'token': StorageService().token,
          },
        );
        if (launched == true) {
          _open = false;
          _loading = false;
          notifyListeners();
          await _setBackGuard(false);
          return;
        }
      }

      _controller ??= _createController();
      await _controller!.loadRequest(uri);
      // 保活只在真正有音频/视频播放时启动（见 media-state），
      // 避免一打开小程序就常驻一条前台服务通知。
    } catch (e) {
      unawaited(_logDesktopOpen('open failed appKey=${app.appKey} error=$e'));
      _error = e is MPException ? '${e.message}（${e.code}）' : '打开小程序失败：$e';
      _loading = false;
      notifyListeners();
    }
  }

  WebViewController _createController() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFFFFFF))
      ..addJavaScriptChannel('mpBridge', onMessageReceived: _onBridgeMessage)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;
            if (uri.scheme == 'about') return NavigationDecision.navigate;
            final app = _app;
            if (app != null && _isAllowed(app, uri)) {
              return NavigationDecision.navigate;
            }
            launchUrl(uri, mode: LaunchMode.externalApplication);
            return NavigationDecision.prevent;
          },
          onPageStarted: (url) {
            _loading = true;
            notifyListeners();
            // 尽早注入，页面 bootstrap 会等这个 token。
            _injectMainToken(url);
          },
          onPageFinished: (url) async {
            _loading = false;
            notifyListeners();
            await _injectMainToken(url);
            await _injectMediaHook();
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) {
              _error = '页面加载失败：${error.description}';
              _loading = false;
              notifyListeners();
            }
          },
        ),
      );
    return controller;
  }

  bool _isAllowed(MPApp app, Uri uri) {
    if (uri.scheme != 'https' &&
        uri.host != 'localhost' &&
        uri.host != '127.0.0.1') {
      return false;
    }
    // 官方内置小程序的统一身份登录会在 WebView 内跳到 SSO 域名；
    // 仅对官方 `/mp/` 小程序放行，第三方小程序仍严格走 allowedOrigins。
    if (uri.scheme == 'https' && _isInternalApp(app)) {
      if (uri.host == 'sso.ssemarket.cn' || uri.host == 'ssemarket.cn') {
        return true;
      }
    }
    final allowed = app.allowedOrigins
        .map(Uri.tryParse)
        .whereType<Uri>()
        .map(_originOf)
        .toSet();
    final origin = _originOf(uri);
    if (allowed.isNotEmpty) return allowed.contains(origin);
    final entry = Uri.tryParse(app.entryURL);
    return entry != null && entry.host == uri.host;
  }

  bool _isInternalApp(MPApp app) {
    return app.appKey == 'novel' ||
        app.appKey == 'ranking' ||
        app.appKey == 'resume' ||
        app.appKey == 'media' ||
        app.appKey == 'shop' ||
        app.appKey == 'course' ||
        app.entryURL.contains('applet.ssemarket.cn/mp/');
  }

  String _originOf(Uri uri) =>
      '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';

  /// 官方内部托管的小程序才注入主站 access token。
  ///
  /// 平台规则不允许把 token 交给第三方 WebView；这里限定死官方 origin + `/mp/` 路径，
  /// 且只注入短时效 access token，不注入 refresh token、不落 localStorage。
  bool _isInternalMpUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return uri.scheme == 'https' &&
        uri.host == 'applet.ssemarket.cn' &&
        uri.path.startsWith('/mp/');
  }

  Future<void> _injectMainToken(String url) async {
    if (!_isInternalMpUrl(url)) return;
    final controller = _controller;
    if (controller == null) return;
    final token = StorageService().token;
    if (token.isEmpty) return;
    final encoded = jsonEncode(token);
    final script = '''
(function(){
  try {
    var t = $encoded;
    window.__SSE_MAIN_TOKEN__ = t;
    if (typeof window.__setSSEAppToken === 'function') window.__setSSEAppToken(t);
    window.dispatchEvent(new Event('sse-main-token'));
  } catch(e) {}
})();
''';
    try {
      await controller.runJavaScript(script);
    } catch (_) {}
  }

  Future<void> _injectMediaHook() async {
    final controller = _controller;
    if (controller == null) return;
    const script = r'''
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
''';
    try {
      await controller.runJavaScript(script);
    } catch (_) {}
  }

  void _onBridgeMessage(JavaScriptMessage message) {
    try {
      final start = message.message.indexOf('{');
      final end = message.message.lastIndexOf('}');
      if (start < 0 || end <= start) return;
      final decoded = jsonDecode(message.message.substring(start, end + 1));
      if (decoded is! Map) return;
      if (decoded['type'] != 'mp.event') return;
      final event = decoded['event']?.toString() ?? '';
      final payload = decoded['payload'];
      switch (event) {
        case 'close':
          hide();
          break;
        case 'media-state':
          if (payload is Map) {
            final playing = payload['playing'] == true;
            if (playing != _mediaPlaying) {
              _mediaPlaying = playing;
              notifyListeners();
              // 只有确实在播放媒体时才保留前台服务；没有音频就不显示通知。
              unawaited(_setKeepAlive(playing));
            }
          }
          break;
        case 'open-url':
          final url = payload is Map ? payload['url']?.toString() : null;
          final uri = url == null ? null : Uri.tryParse(url);
          if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
          break;
        default:
          break;
      }
    } catch (_) {}
  }

  void show() {
    if (_controller == null) return;
    _open = true;
    _setBackGuard(true);
    notifyListeners();
  }

  /// 隐藏容器但保持 WebView/音频运行（微信「关闭」语义）。
  void hide() {
    _open = false;
    _setBackGuard(false);
    notifyListeners();
  }

  /// 系统返回键/侧滑返回。返回 true 表示已被小程序消费。
  Future<bool> handleBack() async {
    if (!_open) return false;
    final controller = _controller;
    if (controller != null) {
      try {
        if (await controller.canGoBack()) {
          await controller.goBack();
          return true;
        }
      } catch (_) {}
    }
    hide();
    return true;
  }

  /// 桌面端用 Chromium 的 --app 模式打开独立窗口（没有地址栏/标签栏），
/// 与主 App 窗口互不影响；找不到 Edge/Chrome 时回退默认浏览器。
  Future<void> _openDesktopWindow(Uri uri) async {
    if (kIsWeb) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    final url = uri.toString();
    if (Platform.isWindows) {
      unawaited(_logDesktopOpen('open url=$url'));
      final pf = Platform.environment['ProgramFiles'] ?? r'C:\Program Files';
      final pf86 = Platform.environment['ProgramFiles(x86)'] ?? r'C:\Program Files (x86)';
      final local = Platform.environment['LOCALAPPDATA'] ?? '';
      final candidates = <String>[
        '$pf86\\Microsoft\\Edge\\Application\\msedge.exe',
        '$pf\\Microsoft\\Edge\\Application\\msedge.exe',
        if (local.isNotEmpty) '$local\\Microsoft\\Edge\\Application\\msedge.exe',
        '$pf\\Google\\Chrome\\Application\\chrome.exe',
        '$pf86\\Google\\Chrome\\Application\\chrome.exe',
        if (local.isNotEmpty) '$local\\Google\\Chrome\\Application\\chrome.exe',
        '$pf\\BraveSoftware\\Brave-Browser\\Application\\brave.exe',
      ];
      for (final path in candidates) {
        try {
          if (File(path).existsSync()) {
            await Process.start(path, <String>['--new-window', '--app=$url'],
                mode: ProcessStartMode.detached);
            unawaited(_logDesktopOpen('started $path'));
            return;
          }
        } catch (_) {}
      }
      // PATH 里可能能找到 msedge/chrome
      for (final exe in const <String>['msedge', 'chrome', 'brave']) {
        try {
          await Process.start(exe, <String>['--new-window', '--app=$url'],
              mode: ProcessStartMode.detached);
          unawaited(_logDesktopOpen('started PATH $exe'));
          return;
        } catch (_) {}
      }
      // 最后用 cmd start，确保至少新开一个浏览器窗口
      try {
        await Process.start('cmd', <String>['/c', 'start', '', 'msedge', '--new-window', url],
            mode: ProcessStartMode.detached);
        unawaited(_logDesktopOpen('started cmd msedge'));
        return;
      } catch (_) {}
    } else if (Platform.isLinux) {
      for (final bin in const <String>[
        'google-chrome',
        'chromium',
        'chromium-browser',
        'microsoft-edge',
      ]) {
        try {
          await Process.start(bin, <String>['--app=$url', '--new-window'],
              mode: ProcessStartMode.detached);
          return;
        } catch (_) {}
      }
    }
    unawaited(_logDesktopOpen('fallback launchUrl'));
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _logDesktopOpen(String message) async {
    if (!Platform.isWindows) return;
    try {
      final base = Platform.environment['LOCALAPPDATA'];
      if (base == null || base.isEmpty) return;
      final dir = Directory('$base\\SSEMarket');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final file = File('${dir.path}\\mp-open.log');
      file.writeAsStringSync('${DateTime.now().toIso8601String()} $message\n',
          mode: FileMode.append, flush: true);
    } catch (_) {}
  }

  Future<void> _setBackGuard(bool on) async {
    try {
      await _lifecycle.invokeMethod<bool>(
        'setBackGuard',
        <String, dynamic>{'enabled': on},
      );
    } catch (_) {}
  }

  Future<void> refresh() async {
    try {
      await _controller?.reload();
    } catch (_) {}
  }

  Future<void> pauseMedia() async {
    try {
      await _controller?.runJavaScript(
        "document.querySelectorAll('audio,video').forEach(function(m){try{m.pause()}catch(e){}});",
      );
    } catch (_) {}
    _mediaPlaying = false;
    await _setKeepAlive(false);
    notifyListeners();
  }

  /// 真正关闭：暂停媒体、停止保活、释放 WebView。
  Future<void> destroy() async {
    await pauseMedia();
    _open = false;
    _app = null;
    _error = null;
    _controller = null;
    await _setKeepAlive(false);
    await _setBackGuard(false);
    notifyListeners();
  }

  Future<void> _setKeepAlive(bool on) async {
    if (on == _keepAliveStarted) return;
    _keepAliveStarted = on;
    if (!Platform.isAndroid) return;
    try {
      await _lifecycle.invokeMethod<bool>(on ? 'start' : 'stop');
    } catch (_) {}
  }
}
