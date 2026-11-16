import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:sse_market_x/core/services/storage_service.dart';

/// 小秋（OpsAgent）原生对话服务。
///
/// 主站接口：
/// - GET  /api/v1/agent/conversation/bootstrap
/// - POST /api/v1/agent/conversation/bootstrap
/// - GET  /api/v1/agent/conversations
/// - GET  /api/v1/agent/conversations/{id}/messages
/// - POST /api/v1/agent/task/sse
/// - GET  /api/v1/agent/suggestions
/// - POST /api/v1/agent/feedback
class XiaoQiuService {
  static const String _base = 'https://ssemarket.cn';

  Map<String, String> get _headers => <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (StorageService().token.isNotEmpty)
          'Authorization': 'Bearer ${StorageService().token}',
      };

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final request = http.Request(method, Uri.parse('$_base$path'))
      ..headers.addAll(_headers);
    if (body != null) request.body = jsonEncode(body);
    final streamed = await request.send().timeout(const Duration(seconds: 20));
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('小秋服务请求失败（${response.statusCode}）');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is Map && decoded['data'] != null) return decoded['data'];
    return decoded;
  }

  Future<({String sessionId, List<({String role, String content})> messages})>
      bootstrap({String? sessionId}) async {
    final data = sessionId == null
        ? await _request('GET', '/api/v1/agent/conversation/bootstrap')
        : await _request(
            'POST',
            '/api/v1/agent/conversation/bootstrap',
            body: <String, dynamic>{'session_id': sessionId},
          );
    final messages = <({String role, String content})>[];
    if (data is Map && data['messages'] is List) {
      for (final raw in data['messages'] as List) {
        if (raw is Map) {
          messages.add((
            role: raw['role']?.toString() ?? '',
            content: raw['content']?.toString() ?? '',
          ));
        }
      }
    }
    return (
      sessionId: data is Map ? (data['session_id']?.toString() ?? '') : '',
      messages: messages,
    );
  }

  Future<List<({String id, String title, String updatedAt})>>
      conversations() async {
    final data = await _request('GET', '/api/v1/agent/conversations?limit=50');
    final list = data is Map && data['conversations'] is List
        ? data['conversations'] as List
        : const [];
    return list
        .whereType<Map>()
        .map((raw) {
          return (
            id: raw['session_id']?.toString() ?? '',
            title: raw['title']?.toString() ?? '未命名对话',
            updatedAt: raw['updated_at']?.toString() ?? '',
          );
        })
        .where((c) => c.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<({String role, String content})>> messages(
      String sessionId) async {
    final data = await _request(
      'GET',
      '/api/v1/agent/conversations/${Uri.encodeComponent(sessionId)}/messages',
    );
    final list = data is Map && data['messages'] is List
        ? data['messages'] as List
        : const [];
    return list.whereType<Map>().map((raw) {
      return (
        role: raw['role']?.toString() ?? '',
        content: raw['content']?.toString() ?? '',
      );
    }).toList(growable: false);
  }

  Future<List<String>> suggestions() async {
    try {
      final data = await _request('GET', '/api/v1/agent/suggestions');
      final list = data is Map && data['suggestions'] is List
          ? data['suggestions'] as List
          : const [];
      return list
          .whereType<Map>()
          .map((e) => e['text']?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .take(4)
          .toList(growable: false);
    } catch (_) {
      return const <String>[];
    }
  }

  Future<void> feedback(String runId, String sessionId, int rating) async {
    await _request('POST', '/api/v1/agent/feedback', body: <String, dynamic>{
      'run_id': runId,
      'thread_id': sessionId,
      'rating': rating,
      'comment': '',
    });
  }

  Future<void> deleteConversation(String sessionId) async {
    await _request(
      'DELETE',
      '/api/v1/agent/conversations/${Uri.encodeComponent(sessionId)}',
    );
  }

  Future<void> closeConversation(String sessionId) async {
    await _request(
      'POST',
      '/api/v1/agent/conversation/close',
      body: <String, dynamic>{'session_id': sessionId},
    );
  }

  /// SSE 流：每条事件返回 `{event, data}`。
  Stream<({String event, Map<String, dynamic> data})> streamTask({
    required String sessionId,
    required String task,
  }) async* {
    final request = http.Request(
      'POST',
      Uri.parse('$_base/api/v1/agent/task/sse'),
    )
      ..headers.addAll(<String, String>{
        ..._headers,
        'Accept': 'text/event-stream',
      })
      ..body = jsonEncode(<String, dynamic>{
        'session_id': sessionId,
        'task': task,
      });

    final response = await request.send();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final text = await response.stream.bytesToString();
      throw Exception(text.isEmpty ? '小秋服务异常' : text);
    }

    var buffer = '';
    await for (final chunk in response.stream.transform(utf8.decoder)) {
      buffer += chunk;
      while (true) {
        final index = buffer.indexOf('\n\n');
        if (index < 0) break;
        final frame = buffer.substring(0, index);
        buffer = buffer.substring(index + 2);
        final parsed = _parseFrame(frame);
        if (parsed != null) yield parsed;
      }
    }
    if (buffer.trim().isNotEmpty) {
      final parsed = _parseFrame(buffer);
      if (parsed != null) yield parsed;
    }
  }

  ({String event, Map<String, dynamic> data})? _parseFrame(String frame) {
    var event = 'message';
    final dataLines = <String>[];
    for (final line in frame.replaceAll('\r\n', '\n').split('\n')) {
      if (line.startsWith('event:')) {
        event = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        dataLines.add(line.substring(5).trim());
      }
    }
    if (dataLines.isEmpty) return null;
    final raw = dataLines.join('\n');
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return (event: event, data: Map<String, dynamic>.from(decoded));
      }
      return (
        event: event,
        data: <String, dynamic>{'text': raw},
      );
    } catch (_) {
      return (
        event: event,
        data: <String, dynamic>{'text': raw},
      );
    }
  }
}
