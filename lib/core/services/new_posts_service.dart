import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sse_market_x/core/api/api_service.dart';
import 'package:sse_market_x/core/models/post_model.dart';
import 'package:sse_market_x/core/services/notification_service.dart';
import 'package:sse_market_x/core/services/storage_service.dart';

/// 新帖提醒状态（供 App 内横幅 / 首页小红点使用）。
@immutable
class NewPostsState {
  final List<int> newPostIds;
  final String? firstTitle;
  final bool isVisible;
  final int updatedAt;

  const NewPostsState({
    this.newPostIds = const <int>[],
    this.firstTitle,
    this.isVisible = false,
    this.updatedAt = 0,
  });

  int get count => newPostIds.length;

  bool get hasUnread => newPostIds.isNotEmpty;

  NewPostsState copyWith({
    List<int>? newPostIds,
    String? firstTitle,
    bool? isVisible,
    int? updatedAt,
  }) {
    return NewPostsState(
      newPostIds: newPostIds ?? this.newPostIds,
      firstTitle: firstTitle ?? this.firstTitle,
      isVisible: isVisible ?? this.isVisible,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 新帖轮询服务：与 web `store/newPostsStore.ts` 同口径。
///
/// 每 60 秒拉一次「主页」最新 20 条，对比 ID 找新增；
/// 首次拉取只建立基线，不弹通知。轮询只在 App 前台运行时进行。
class NewPostsService {
  static final NewPostsService _instance = NewPostsService._internal();
  factory NewPostsService() => _instance;
  NewPostsService._internal();

  static const Duration pollInterval = Duration(seconds: 60);
  static const String _enabledKey = 'new_posts_notification_enabled';
  static const String _askedKey = 'new_posts_permission_asked';

  final ValueNotifier<NewPostsState> state =
      ValueNotifier<NewPostsState>(const NewPostsState());
  final ValueNotifier<bool> enabledNotifier = ValueNotifier<bool>(true);

  Timer? _timer;
  ApiService? _api;
  List<int> _cachedIds = <int>[];
  bool _checking = false;
  bool _initialized = false;

  bool get isEnabled => enabledNotifier.value;

  /// 纯函数：返回 current 中不在 previous 里的 ID（保持原顺序）。
  /// 单独抽出来便于单测。
  static List<int> diffNewPostIds(
    List<int> previous,
    List<int> current,
  ) {
    if (previous.isEmpty) return const <int>[];
    final previousSet = previous.toSet();
    final seen = <int>{};
    return current
        .where((id) => !previousSet.contains(id) && seen.add(id))
        .toList();
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await NotificationService().init();
    final prefs = await SharedPreferences.getInstance();
    enabledNotifier.value = prefs.getBool(_enabledKey) ?? true;
  }

  /// 首次进入时请求一次通知权限；之后交给设置页开关控制。
  Future<bool> ensurePermissionAsked() async {
    if (!isEnabled) return false;
    final notification = NotificationService();
    // 已经授权就不重复弹窗。
    if (await notification.areNotificationsEnabled()) return true;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_askedKey) == true) {
      // 之前问过但没授权：不再自动弹，交给设置页/系统设置处理。
      return false;
    }
    await prefs.setBool(_askedKey, true);
    // 等首帧稳定后再弹系统权限框，避免 Activity 尚未 resumed 导致请求被丢弃。
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final requested = await notification.requestPermission();
    final granted = requested || await notification.areNotificationsEnabled();
    if (!granted) {
      // 用户拒绝时不关闭功能，App 内横幅仍可提醒；设置页可再次开启。
      await prefs.setBool(_enabledKey, true);
    }
    return granted;
  }

  /// 设置页开关。打开时会重新申请权限。
  Future<bool> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      final notification = NotificationService();
      final granted = await notification.requestPermission() ||
          await notification.areNotificationsEnabled();
      if (!granted) {
        enabledNotifier.value = false;
        await prefs.setBool(_enabledKey, false);
        return false;
      }
    }
    enabledNotifier.value = value;
    await prefs.setBool(_enabledKey, value);
    if (!value) {
      stop();
    } else if (_api != null) {
      start(_api!);
    }
    return true;
  }

  /// 启动轮询。重复调用安全。
  void start(ApiService api) {
    _api = api;
    if (!isEnabled) return;
    if (_timer != null) return;
    // 立刻检查一次，之后按固定间隔轮询。
    unawaited(checkNow());
    _timer = Timer.periodic(pollInterval, (_) => unawaited(checkNow()));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// 手动检查一次（供页面下拉刷新或通知点击后调用）。
  Future<void> checkNow() async {
    if (_checking || !isEnabled) return;
    final api = _api;
    final user = StorageService().user;
    if (api == null || user == null || user.phone.isEmpty) return;

    _checking = true;
    try {
      final posts = await api.getPosts(
        GetPostsParams(
          limit: 20,
          offset: 0,
          partition: '主页',
          searchsort: 'home',
          searchinfo: '',
          userTelephone: user.phone,
          tag: '',
        ),
      );
      final currentIds = posts.map((PostModel p) => p.id).toList();
      if (_cachedIds.isEmpty) {
        // 首次加载只建立基线。
        _cachedIds = currentIds;
        return;
      }

      final newIds = diffNewPostIds(_cachedIds, currentIds);
      if (newIds.isEmpty) return;

      final newIdSet = newIds.toSet();
      final newPosts = posts.where((p) => newIdSet.contains(p.id)).toList();
      _cachedIds = currentIds;

      state.value = NewPostsState(
        newPostIds: <int>[...newIds, ...state.value.newPostIds]
            .toSet()
            .toList(growable: false),
        firstTitle: newPosts.isNotEmpty ? newPosts.first.title : null,
        isVisible: true,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      await NotificationService().showNewPosts(
        count: state.value.count,
        firstPostTitle: state.value.firstTitle,
        firstPostId: newPosts.isNotEmpty ? newPosts.first.id : null,
      );
    } catch (e) {
      debugPrint('检查新帖失败: $e');
    } finally {
      _checking = false;
    }
  }

  /// 用户看过首页后清掉小红点（保留已缓存 ID，避免重复提醒）。
  void markSeen() {
    if (!state.value.isVisible && !state.value.hasUnread) return;
    state.value = state.value.copyWith(
      newPostIds: const <int>[],
      isVisible: false,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
