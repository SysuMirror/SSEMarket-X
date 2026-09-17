import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:sse_market_x/core/api/api_client.dart';
import 'package:sse_market_x/core/models/notice_model.dart';

/// 通知 API 服务
class NoticeService {
  final ApiClient _client;

  NoticeService({ApiClient client = const ApiClient()}) : _client = client;

  String get token => _client.token;

  /// 获取通知数量
  Future<NoticeNum> getNoticeNum() async {
    if (token.isEmpty) {
      return NoticeNum(totalNum: 0, unreadTotalNum: 0, readTotalNum: 0);
    }

    try {
      final response = await http.get(
        Uri.parse('${_client.baseUrl}/auth/getNoticeNum'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return NoticeNum.fromJson(json);
      }
    } catch (e) {
      print('获取通知数量失败: $e');
    }
    return NoticeNum(totalNum: 0, unreadTotalNum: 0, readTotalNum: 0);
  }

  /// 获取通知列表
  Future<List<Notice>> getNotices({
    int requireId = 0,
    int pageSize = 20,
    required int read, // 0:未读, 1:已读
  }) async {
    if (token.isEmpty) return [];

    try {
      final uri = Uri.parse('${_client.baseUrl}/auth/getNotice').replace(queryParameters: {
        'requireID': requireId.toString(),
        'pageSize': pageSize.toString(),
        'read': read.toString(),
      });

      final response = await http.get(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['noticeList'] is List) {
          return (json['noticeList'] as List)
              .map((e) => Notice.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      print('获取通知列表失败: $e');
    }
    return [];
  }

  /// 标记通知已读
  Future<bool> readNotice(int noticeId) async {
    if (token.isEmpty) return false;

    try {
      final response = await http.patch(
        Uri.parse('${_client.baseUrl}/auth/readNotice/$noticeId'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['status'] == 'success';
      }
    } catch (e) {
      print('标记通知已读失败: $e');
    }
    return false;
  }
}
