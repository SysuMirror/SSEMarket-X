import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sse_market_x/core/services/storage_service.dart';

/// 集市小程序开放平台客户端（对齐 `mp-app-integration` Skill）。
///
/// 安全约束：
/// - 只向平台发主站 **access token**，refreshToken 永远不出 App；
/// - 平台返回的 launchURL 交给小程序容器，不向 WebView 注入任何主站 token。
class MPException implements Exception {
  MPException(this.status, this.code, this.message, this.requestId);

  final int status;
  final String code;
  final String message;
  final String? requestId;

  @override
  String toString() => 'MPException($status $code): $message'
      '${requestId == null ? '' : ' [requestId=$requestId]'}';
}

class MPApp {
  final String appKey;
  final String name;
  final String description;
  final String icon;
  final String category;
  final String entryURL;
  final List<String> allowedOrigins;
  final List<String> scopes;
  final String visibility;
  final String version;
  final int sort;
  final String? badge;

  const MPApp({
    required this.appKey,
    required this.name,
    this.description = '',
    this.icon = '',
    this.category = '',
    this.entryURL = '',
    this.allowedOrigins = const <String>[],
    this.scopes = const <String>[],
    this.visibility = '',
    this.version = '',
    this.sort = 0,
    this.badge,
  });

  factory MPApp.fromDynamic(dynamic raw) {
    if (raw is! Map) return const MPApp(appKey: '', name: '');
    List<String> strings(String key) =>
        ((raw[key] as List?) ?? const []).map((e) => e.toString()).toList();
    return MPApp(
      appKey: raw['appKey']?.toString() ?? '',
      name: raw['name']?.toString() ?? '',
      description: raw['description']?.toString() ?? '',
      icon: raw['icon']?.toString() ?? '',
      category: raw['category']?.toString() ?? '',
      entryURL: raw['entryURL']?.toString() ?? '',
      allowedOrigins: strings('allowedOrigins'),
      scopes: strings('scopes'),
      visibility: raw['visibility']?.toString() ?? '',
      version: raw['version']?.toString() ?? '',
      sort: (raw['sort'] as num?)?.toInt() ?? 0,
      badge: raw['badge']?.toString(),
    );
  }

  String get origin {
    if (allowedOrigins.isNotEmpty) return allowedOrigins.first;
    final uri = Uri.tryParse(entryURL);
    if (uri == null) return '';
    return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
  }
}

class MPLaunchTicket {
  final String ticket;
  final String launchUrl;
  final int expiresIn;
  final MPApp? app;

  const MPLaunchTicket({
    required this.ticket,
    required this.launchUrl,
    required this.expiresIn,
    this.app,
  });
}

class MPPrefs {
  final List<String> recent;
  final List<String> favorites;

  const MPPrefs({this.recent = const [], this.favorites = const []});

  factory MPPrefs.fromDynamic(dynamic raw) {
    if (raw is! Map) return const MPPrefs();
    List<String> keys(dynamic value) {
      if (value is! List) return const <String>[];
      return value
          .map((e) {
            if (e is String) return e;
            if (e is Map) return e['appKey']?.toString() ?? '';
            return '';
          })
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    }

    return MPPrefs(
      recent: keys(raw['recent']),
      favorites: keys(raw['favorites']),
    );
  }
}

class MPPlatformApi {
  MPPlatformApi({
    this.baseUrl = const String.fromEnvironment(
      'MP_BASE',
      defaultValue: 'https://applet.ssemarket.cn',
    ),
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  String? _deviceId;
  Future<String>? _deviceIdFuture;

  Future<String> get deviceId => _deviceIdFuture ??= _loadDeviceId();

  Future<String> _loadDeviceId() async {
    if (_deviceId != null) return _deviceId!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('mp_device_id') ?? '';
    if (id.isEmpty) {
      id = 'dev_${DateTime.now().millisecondsSinceEpoch}_${_rand()}';
      await prefs.setString('mp_device_id', id);
    }
    _deviceId = id;
    return id;
  }

  String _rand() {
    final now = DateTime.now().microsecondsSinceEpoch;
    return (now % 100000000).toRadixString(36);
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalized = baseUrl.replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$normalized$path').replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (auth) {
      final token = StorageService().token;
      if (token.isEmpty) {
        throw MPException(401, 'UNAUTHORIZED', '请先登录主站', null);
      }
      headers['Authorization'] = 'Bearer $token';
    }
    if (body != null) headers['Content-Type'] = 'application/json';

    final request = http.Request(method, _uri(path, query))
      ..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);

    final streamed = await _client
        .send(request)
        .timeout(const Duration(seconds: 15));
    final response = await http.Response.fromStream(streamed)
        .timeout(const Duration(seconds: 15));
    final dynamic decoded =
        response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode >= 400) {
      final map =
          decoded is Map<String, dynamic> ? decoded : const <String, dynamic>{};
      throw MPException(
        response.statusCode,
        (map['code'] as String?) ?? 'HTTP_ERROR',
        (map['message'] as String?) ?? '请求失败',
        map['requestId'] as String?,
      );
    }
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  Future<List<MPApp>> catalog({
    String? category,
    String? cursor,
    int limit = 50,
  }) async {
    final data = await _request('GET', '/v1/apps', query: {
      if (category != null && category.isNotEmpty) 'category': category,
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      'limit': '$limit',
    });
    return ((data['items'] as List?) ?? const [])
        .map(MPApp.fromDynamic)
        .where((a) => a.appKey.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<MPApp>> search(String query, {int limit = 20}) async {
    final data = await _request('GET', '/v1/search', query: {
      'q': query,
      'limit': '$limit',
    });
    return ((data['items'] as List?) ?? const [])
        .map(MPApp.fromDynamic)
        .where((a) => a.appKey.isNotEmpty)
        .toList(growable: false);
  }

  Future<MPLaunchTicket> launchTicket({
    required String appKey,
    String? origin,
  }) async {
    final data = await _request('POST', '/v1/launch-tickets', body: {
      'appKey': appKey,
      'deviceID': await deviceId,
      if (origin != null && origin.isNotEmpty) 'origin': origin,
    });
    return MPLaunchTicket(
      ticket: data['ticket']?.toString() ?? '',
      launchUrl: data['launchURL']?.toString() ?? '',
      expiresIn: (data['expiresIn'] as num?)?.toInt() ?? 60,
      app: data['app'] == null ? null : MPApp.fromDynamic(data['app']),
    );
  }

  Future<MPPrefs> prefs() async {
    final data = await _request('GET', '/v1/me/prefs');
    return MPPrefs.fromDynamic(data);
  }

  Future<MPPrefs> updatePrefs({
    List<String>? recent,
    List<String>? favorites,
  }) async {
    final data = await _request('PUT', '/v1/me/prefs', body: {
      if (recent != null) 'recent': recent,
      if (favorites != null) 'favorites': favorites,
    });
    return MPPrefs.fromDynamic(data);
  }

  Future<void> registerDevice({
    required String platform,
    required String pushProvider,
    String pushToken = '',
    String appVersion = '',
    bool notificationEnabled = true,
    String locale = 'zh-CN',
  }) async {
    await _request('POST', '/v1/devices', body: {
      'deviceID': await deviceId,
      'platform': platform,
      'pushProvider': pushProvider,
      'pushToken': pushToken,
      'appVersion': appVersion,
      'notificationEnabled': notificationEnabled,
      'locale': locale,
    });
  }

  Future<void> updateSubscriptions({
    bool enabled = true,
    String? quietFrom,
    String? quietTo,
  }) async {
    await _request('PUT', '/v1/me/subscriptions', body: {
      'topics': [
        {
          'topic': 'new_posts',
          'enabled': enabled,
          'quietHours': quietFrom != null && quietTo != null
              ? {'from': quietFrom, 'to': quietTo}
              : null,
        }
      ]
    });
  }

  Future<Map<String, dynamic>> pollNewPosts({
    DateTime? since,
    int limit = 30,
  }) {
    return _request('GET', '/v1/events/new-posts', query: {
      if (since != null) 'since': since.toUtc().toIso8601String(),
      'limit': '$limit',
    });
  }

  void dispose() => _client.close();
}
