import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:sse_market_x/core/api/api_client.dart';
import 'package:sse_market_x/core/models/chat_message_model.dart';

/// 聊天 API 服务
class ChatService {
  final ApiClient _client;

  ChatService({ApiClient client = const ApiClient()}) : _client = client;

  String get token => _client.token;

  /// 获取聊天记录
  Future<List<ChatMessageModel>> getChatHistory(int senderUserId, int targetUserId) async {
    if (token.isEmpty) return [];

    final uri = Uri.parse('${_client.baseUrl}/auth/getChatHistory');
    final uriWithQuery = uri.replace(queryParameters: {
      'senderUserID': senderUserId.toString(),
      'targetUserID': targetUserId.toString(),
    });

    try {
      final response = await http.get(
        uriWithQuery,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['code'] == 200 && json['data'] != null) {
          final data = json['data'];
          if (data['chatHistoryList'] is List) {
             return (data['chatHistoryList'] as List)
                .map((e) => ChatMessageModel.fromJson(e))
                .toList();
          }
        }
      }
      return [];
    } catch (e) {
      print('获取聊天记录失败: $e');
      return [];
    }
  }
}
