import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 本地通知服务。
///
/// - Android / iOS / macOS / Windows / Linux 走 `flutter_local_notifications`；
/// - HarmonyOS 走原生 MethodChannel（`ssemarket/notifications`），
///   在 `ohos/entry/src/main/ets/entryability/EntryAbility.ets` 中实现。
/// - Web 不支持，全部降级为空操作。
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const MethodChannel _ohosChannel =
      MethodChannel('ssemarket/notifications');
  static const MethodChannel _settingsChannel =
      MethodChannel('ssemarket/notifications_settings');

  static const String _channelId = 'new_posts';
  static const int _notificationId = 41001;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final StreamController<String> _tapController =
      StreamController<String>.broadcast();

  bool _initialized = false;
  String? _pendingPayload;

  /// 用户点击通知时发出 payload（这里固定为 `new_posts`）。
  Stream<String> get onNotificationTap => _tapController.stream;

  /// 冷启动时由通知拉起，初始化后可读取一次。
  String? takePendingPayload() {
    final payload = _pendingPayload;
    _pendingPayload = null;
    return payload;
  }

  bool get isSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid ||
        Platform.isIOS ||
        Platform.isMacOS ||
        Platform.isWindows ||
        Platform.operatingSystem == 'ohos';
  }

  Future<void> init() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    // Linux 桌面依赖 DBus；容器/无桌面会话下初始化会让 plugin 抛异步异常，直接跳过。
    if (Platform.isLinux) return;
    // HarmonyOS 的通知能力由 ArkTS 原生侧提供。
    if (Platform.operatingSystem == 'ohos') return;

    // 必须使用纯白剪影 drawable 作为 small icon；直接用 mipmap 启动图
    // 在 Android 8+ 会报 “Invalid notification (no valid small icon)”。
    const android = AndroidInitializationSettings('ic_stat_notify');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const linux = LinuxInitializationSettings(defaultActionName: '打开');
    const windows = WindowsInitializationSettings(
      appName: 'SSE Market',
      appUserModelId: 'com.susse.market',
      guid: 'b7b0f2b9-6f3e-4a3c-9d2e-2f6f1a5c8e10',
    );

    final settings = InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
      linux: linux,
      windows: windows,
    );

    try {
      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: _handleResponse,
      );
      if (Platform.isAndroid) {
        final androidImpl = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await androidImpl?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            '新帖通知',
            description: '集市有新帖时提醒',
            importance: Importance.high,
          ),
        );
      }
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true) {
        _pendingPayload = launchDetails?.notificationResponse?.payload;
      }
    } catch (e) {
      debugPrint('[notification] init failed: $e');
    }
  }

  void _handleResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      _tapController.add(payload);
    }
  }

  /// 申请系统通知权限；返回是否已授权。
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    if (Platform.operatingSystem == 'ohos') {
      try {
        final granted =
            await _ohosChannel.invokeMethod<bool>('requestPermission');
        return granted ?? false;
      } catch (_) {
        return false;
      }
    }

    if (!isSupported) return false;

    try {
      if (Platform.isAndroid) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return await android?.requestNotificationsPermission() ?? false;
      }
      if (Platform.isIOS || Platform.isMacOS) {
        final ios = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        return await ios?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
      // Windows / Linux 没有运行时通知权限弹窗。
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 当前系统是否允许通知（Android 13+ / iOS / OHOS）。
  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return false;
    if (Platform.operatingSystem == 'ohos') {
      try {
        return await _ohosChannel.invokeMethod<bool>('areEnabled') ?? false;
      } catch (_) {
        return false;
      }
    }
    if (!isSupported) return false;
    try {
      if (Platform.isAndroid) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return await android?.areNotificationsEnabled() ?? false;
      }
      if (Platform.isIOS || Platform.isMacOS) {
        // iOS 没有同步查询接口，权限申请结果以 requestPermission 为准。
        return true;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 跳转系统通知设置页（Android）；其他平台返回 false。
  Future<bool> openSystemSettings() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _settingsChannel.invokeMethod<bool>('open') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// 设置页「发送测试通知」：立即验证系统通道是否可用。
  Future<bool> showTestNotification() async {
    if (!isSupported) return false;
    if (Platform.operatingSystem == 'ohos') {
      try {
        await _ohosChannel.invokeMethod<bool>('show', <String, dynamic>{
          'id': 41002,
          'title': '通知测试',
          'text': '如果你看到这条通知，说明系统通知权限正常',
        });
        return true;
      } catch (_) {
        return false;
      }
    }
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          '新帖通知',
          channelDescription: '集市有新帖时提醒',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_stat_notify',
          category: AndroidNotificationCategory.social,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      );
      await _plugin.show(
        41002,
        '通知测试',
        '如果你看到这条通知，说明系统通知权限正常',
        details,
        payload: 'test',
      );
      return true;
    } catch (e) {
      debugPrint('[notification] show test failed: $e');
      return false;
    }
  }

  /// 新帖通知。
  Future<void> showNewPosts({
    required int count,
    String? firstPostTitle,
    int? firstPostId,
  }) async {
    if (!isSupported) return;

    final title = count > 1 ? '集市有 $count 条新帖' : '集市有新帖';
    final body = (firstPostTitle == null || firstPostTitle.trim().isEmpty)
        ? '点击回首页看看大家的新动态'
        : firstPostTitle.trim();

    if (Platform.operatingSystem == 'ohos') {
      try {
        await _ohosChannel.invokeMethod<bool>('show', <String, dynamic>{
          'id': _notificationId,
          'title': title,
          'text': body,
          'payload':
              firstPostId != null ? 'new_posts:$firstPostId' : 'new_posts',
        });
      } catch (_) {
        // 原生侧未实现时忽略。
      }
      return;
    }

    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          '新帖通知',
          channelDescription: '集市有新帖时提醒',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_stat_notify',
          category: AndroidNotificationCategory.social,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
        linux: LinuxNotificationDetails(),
      );
      await _plugin.show(
        _notificationId,
        title,
        body,
        details,
        // 带上首条新帖 ID，点通知直接打开该帖（dataid 深链）。
        payload: firstPostId != null ? 'new_posts:$firstPostId' : 'new_posts',
      );
    } catch (e) {
      // 权限未授予或平台不支持时降级，App 内仍有横幅提示。
      debugPrint('[notification] show new posts failed: $e');
    }
  }
}
