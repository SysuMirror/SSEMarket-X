import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:sse_market_x/core/api/api_service.dart';
import 'package:sse_market_x/core/models/presence_model.dart';
import 'package:sse_market_x/core/services/storage_service.dart';

/// 全站在线心跳（模块级单例，对齐 web `usePresence.ts`）。
///
/// - 登录后每 60 秒上报一次；页面通过 [setTarget] 切换「我在看什么」；
/// - 服务端在线判定窗口约 150 秒，漏一两次心跳不会误判离线；
/// - App 切后台时暂停，回前台立即补一次。
class PresenceService {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  static const Duration _defaultInterval = Duration(seconds: 60);

  final ValueNotifier<PresenceSnapshot?> snapshot =
      ValueNotifier<PresenceSnapshot?>(null);

  ApiService? _api;
  Timer? _timer;
  String _scene = 'home';
  int _targetID = 0;
  bool _inFlight = false;
  bool _active = false;

  String get scene => _scene;
  int get targetID => _targetID;

  void start(ApiService api) {
    _api = api;
    if (!StorageService().isLoggedIn) return;
    if (_timer != null) return;
    _active = true;
    unawaited(beat());
    _timer = Timer.periodic(_defaultInterval, (_) => unawaited(beat()));
  }

  void stop() {
    _active = false;
    _timer?.cancel();
    _timer = null;
  }

  /// 切换当前场景；内容变化后立即补一次心跳。
  void setTarget(String scene, {int targetID = 0}) {
    _scene = scene;
    _targetID = scene == 'home' ? 0 : targetID;
    if (_active) unawaited(beat());
  }

  Future<void> beat() async {
    if (_inFlight || !_active) return;
    final api = _api;
    if (api == null || !StorageService().isLoggedIn) return;

    _inFlight = true;
    try {
      final result = await api.sendPresenceHeartbeat(
        scene: _scene,
        targetID: _targetID,
      );
      if (result != null) snapshot.value = result;
    } finally {
      _inFlight = false;
    }
  }

  /// 只在页面首次渲染前拉一次只读数字，不产生心跳。
  Future<void> refreshStats({String? scene, int targetID = 0}) async {
    final api = _api;
    if (api == null || !StorageService().isLoggedIn) return;
    final result = await api.fetchPresenceStats(
      scene: scene ?? _scene,
      targetID: targetID,
    );
    if (result != null) snapshot.value = result;
  }
}
