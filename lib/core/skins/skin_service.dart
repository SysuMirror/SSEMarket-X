import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sse_market_x/core/skins/skin_models.dart';
import 'package:sse_market_x/core/services/storage_service.dart';

/// 全站皮肤状态（对齐 web `useSkin.ts`）。
///
/// 判定顺序：
/// 1. `/auth/theme/state` 给出活动时间窗；
/// 2. 用户设置 themeMode：auto 跟随活动 / default 默认 / <skinID> 强制；
/// 3. 本地注册表 [skinList] 把 skinID 映射到资源。
class SkinService extends ChangeNotifier {
  static final SkinService _instance = SkinService._internal();
  factory SkinService() => _instance;
  SkinService._internal();

  static const String _baseUrl = 'https://ssemarket.cn/api';
  static const String _prefsKey = 'sse_theme_prefs_v1';

  ThemeEvent? _event;
  ThemeSettings _prefs = const ThemeSettings();
  bool _ready = false;
  bool _loading = false;
  bool _saving = false;
  int _serverOffsetMs = 0;
  Timer? _ticker;
  bool _splashOpen = false;
  bool _splashSeen = false;

  ThemeEvent? get event => _event;
  ThemeSettings get prefs => _prefs;
  bool get ready => _ready;
  bool get loading => _loading;
  bool get saving => _saving;
  bool get splashOpen => _splashOpen;
  String get serverTimeIso => DateTime.now()
      .add(Duration(milliseconds: _serverOffsetMs))
      .toUtc()
      .toIso8601String();

  bool get eventActive {
    final e = _event;
    if (e == null) return false;
    final now = DateTime.now().millisecondsSinceEpoch + _serverOffsetMs;
    final start = DateTime.tryParse(e.startsAt)?.millisecondsSinceEpoch;
    final end = DateTime.tryParse(e.endsAt)?.millisecondsSinceEpoch;
    if (start != null && end != null) {
      return now >= start && now <= end;
    }
    return e.active;
  }

  String get effectiveThemeId {
    final mode = _prefs.themeMode;
    if (mode == 'default') return '';
    if (mode == 'auto') {
      return eventActive ? (_event?.themeId ?? '') : '';
    }
    return isSkinId(mode) ? mode : '';
  }

  SkinDefinition? get activeSkin => getSkin(effectiveThemeId);

  bool get skinActive => activeSkin != null;

  /// 是否有可见背景（皮肤内置或合法自定义 URL），用于页面透明化。
  bool get hasBackgroundEnabled {
    if (!_prefs.backgroundEnabled) return false;
    if (_prefs.backgroundSource == 'custom') {
      final url = _prefs.customBackgroundUrl.trim();
      return url.startsWith('https://') || url.startsWith('http://');
    }
    return activeSkin != null;
  }

  /// 背景来源：皮肤内置或用户自定义；关闭背景时为 null。
  String? backgroundAsset({required bool wide}) {
    if (!_prefs.backgroundEnabled) return null;
    if (_prefs.backgroundSource == 'custom') return null; // 自定义走 URL
    final skin = activeSkin;
    if (skin == null) return null;
    return wide ? skin.backgroundDesktop : skin.backgroundMobile;
  }

  String? get customBackgroundUrl {
    if (!_prefs.backgroundEnabled || _prefs.backgroundSource != 'custom') {
      return null;
    }
    final url = _prefs.customBackgroundUrl.trim();
    if (!url.startsWith('https://') && !url.startsWith('http://')) return null;
    return url;
  }

  String? splashAsset({required bool wide}) {
    final skin = activeSkin;
    if (skin == null) return null;
    return wide ? skin.splashDesktop : skin.splashMobile;
  }

  Future<void> init() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        _prefs = ThemeSettings.fromDynamic(jsonDecode(raw));
      } catch (_) {}
    }
    _ticker ??= Timer.periodic(const Duration(seconds: 30), (_) {
      // 跨零点自动结束活动
      if (_event != null) notifyListeners();
    });
    try {
      // 外观是弱功能，网络慢时不阻塞 App 启动。
      await refresh().timeout(const Duration(seconds: 4));
    } catch (_) {
      _ready = true;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();
    try {
      final token = StorageService().token;
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/theme/state'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final dynamic json = jsonDecode(response.body);
        final data = json is Map ? json['data'] : null;
        if (data is Map) {
          final rawEvent = data['event'];
          _event = rawEvent == null ? null : ThemeEvent.fromDynamic(rawEvent);
          final serverTime =
              DateTime.tryParse(data['serverTime']?.toString() ?? '');
          if (serverTime != null) {
            _serverOffsetMs = serverTime.millisecondsSinceEpoch -
                DateTime.now().millisecondsSinceEpoch;
          }
          final rawSettings = data['settings'];
          if (rawSettings != null) {
            _prefs = ThemeSettings.fromDynamic(rawSettings);
            await _persistPrefs();
          }
        }
      }
    } catch (e) {
      debugPrint('加载皮肤设置失败: $e');
    } finally {
      _loading = false;
      _ready = true;
      _tryOpenSplash();
      notifyListeners();
    }
  }

  Future<void> _persistPrefs() async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_prefsKey, jsonEncode(_prefs.toJson()));
    } catch (_) {}
  }

  void _tryOpenSplash() {
    final skin = activeSkin;
    if (skin == null || !_prefs.splashEnabled || _splashSeen) return;
    _splashSeen = true;
    _splashOpen = true;
  }

  void closeSplash() {
    if (!_splashOpen) return;
    _splashOpen = false;
    notifyListeners();
  }

  /// 设置页「预览开场画面」。
  void previewSplash() {
    if (activeSkin == null) return;
    _splashOpen = true;
    notifyListeners();
  }

  /// 更新外观设置：先乐观更新 UI，再写服务端；失败回滚。
  Future<({bool ok, String msg})> updatePrefs(ThemeSettings next) async {
    if (_saving) return (ok: false, msg: '正在保存，请稍候');
    final previous = _prefs;
    _prefs = next;
    await _persistPrefs();
    notifyListeners();

    if (!StorageService().isLoggedIn) return (ok: true, msg: '');

    _saving = true;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/theme/settings'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${StorageService().token}',
        },
        body: jsonEncode(next.toJson()),
      );
      final dynamic json = jsonDecode(response.body);
      if (response.statusCode != 200 || (json is Map && json['code'] != 200)) {
        _prefs = previous;
        await _persistPrefs();
        notifyListeners();
        return (
          ok: false,
          msg: json is Map ? (json['msg']?.toString() ?? '保存失败') : '保存失败'
        );
      }
      final data = json is Map ? json['data'] : null;
      final settings = data is Map ? data['settings'] : null;
      if (settings != null) {
        _prefs = ThemeSettings.fromDynamic(settings);
        await _persistPrefs();
      }
      notifyListeners();
      return (ok: true, msg: '已保存');
    } catch (e) {
      _prefs = previous;
      await _persistPrefs();
      notifyListeners();
      return (ok: false, msg: '网络异常，请稍后重试');
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
