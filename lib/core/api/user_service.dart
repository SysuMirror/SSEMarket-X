import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:sse_market_x/core/api/api_client.dart';
import 'package:sse_market_x/core/models/ranking_model.dart';
import 'package:sse_market_x/core/models/user_model.dart';

/// 用户 API 服务
class UserService {
  final ApiClient _client;

  UserService({ApiClient client = const ApiClient()}) : _client = client;

  String get token => _client.token;

  Future<UserModel> getUserInfo() async {
    if (token.isEmpty) return UserModel.empty();

    final uri = Uri.parse('${_client.baseUrl}/auth/info');
    final response = await http.get(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      return UserModel.empty();
    }

    final dynamic json = jsonDecode(response.body);

    dynamic userRaw;
    if (json is Map<String, dynamic>) {
      final data = json['data'];
      if (data is Map<String, dynamic>) {
        if (data['user'] != null) {
          userRaw = data['user'];
        } else {
          userRaw = data;
        }
      } else {
        userRaw = json;
      }
    } else {
      userRaw = json;
    }

    return UserModel.fromDynamic(userRaw);
  }

  Future<UserModel> getDetailedUserInfo(String phone) async {
    if (token.isEmpty || phone.isEmpty) return UserModel.empty();

    final uri = Uri.parse('${_client.baseUrl}/auth/getInfo');
    final body = jsonEncode(<String, dynamic>{
      'phone': phone,
    });

    final response = await http.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      return UserModel.empty();
    }

    final dynamic json = jsonDecode(response.body);
    return UserModel.fromDynamic(json);
  }

  Future<UserModel> getInfoById(int userId) async {
    if (token.isEmpty || userId == 0) return UserModel.empty();

    final uri = Uri.parse('${_client.baseUrl}/auth/getInfo');
    final body = jsonEncode(<String, dynamic>{
      'userID': userId,
    });

    final response = await http.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      return UserModel.empty();
    }

    final dynamic json = jsonDecode(response.body);
    return UserModel.fromDynamic(json);
  }

  /// 上传图片
  /// 返回图片 URL，失败返回 null
  Future<String?> uploadPhoto(Uint8List imageBytes, String fileName) async {
    if (token.isEmpty) return null;

    // Use new API URL from newSSE
    final uri = Uri.parse('https://ssemarket.cn/api/auth/uploadPhotos');

    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      MediaType? mediaType;
      final lowerName = fileName.toLowerCase();
      if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')) {
        mediaType = MediaType('image', 'jpeg');
      } else if (lowerName.endsWith('.png')) {
        mediaType = MediaType('image', 'png');
      } else if (lowerName.endsWith('.gif')) {
        mediaType = MediaType('image', 'gif');
      } else if (lowerName.endsWith('.webp')) {
        mediaType = MediaType('image', 'webp');
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: fileName,
          contentType: mediaType,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['fileURL'] as String?;
      } else {
        print('上传图片失败: ${response.statusCode} ${response.body}');
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('上传图片失败: $e');
      return null;
    }
  }

  /// 更新用户信息（头像、简介、昵称）
  Future<bool> updateUserInfo({
    required String avatarUrl,
    required String intro,
    required String name,
    required int userId,
  }) async {
    if (token.isEmpty || userId == 0) return false;

    final uri = Uri.parse('${_client.baseUrl}/auth/updateUserInfo');
    final body = jsonEncode(<String, dynamic>{
      'avatarURL': avatarUrl,
      'intro': intro,
      'name': name,
      'userID': userId,
    });

    try {
      final response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['code'] == 200;
      }
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('更新用户信息失败: $e');
      return false;
    }
  }

  /// 更新邮箱推送设置（切换开关）
  /// 注意：此 API 返回空响应体，状态码 200 表示成功
  Future<bool> updateEmailPush(int userId) async {
    if (token.isEmpty || userId == 0) return false;

    final uri = Uri.parse('${_client.baseUrl}/auth/changeEmailPush');
    final body = jsonEncode(<String, dynamic>{
      'user_id': userId,
    });

    try {
      final response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      // 此 API 返回空响应体，状态码 200 即表示成功
      return response.statusCode == 200;
    } catch (e) {
      // ignore: avoid_print
      print('更新邮箱推送设置失败: $e');
      return false;
    }
  }

  /// 提交反馈
  Future<bool> submitFeedback(String content) async {
    if (token.isEmpty) return false;

    final uri = Uri.parse('${_client.baseUrl}/auth/submitFeedback');
    final body = jsonEncode(<String, dynamic>{
      'ftext': content,
      'attachment': '',
    });

    try {
      final response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['msg'] == 'success' || data['code'] == 200;
      }
      return false;
    } catch (e) {
      print('提交反馈失败: $e');
      return false;
    }
  }

  /// 获取用户排行榜（对应 /auth/userRanking，服务器固定返回前 100 名，无分页）
  /// 失败（网络错误/状态码非 200/结构不符）返回 null，页面显示错误态可重试；
  /// 成功但无数据返回空列表
  Future<List<UserRankingEntry>?> getUserRanking() async {
    if (token.isEmpty) return null;

    final uri = Uri.parse('${_client.baseUrl}/auth/userRanking');

    try {
      final response = await http.get(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) return null;

      final dynamic json = jsonDecode(response.body);
      if (json is! Map) return null;
      final ranking = json['data'] is Map ? json['data']['ranking'] : null;
      if (ranking is! List) return null;

      return ranking
          .map((e) => UserRankingEntry.fromDynamic(e))
          .toList();
    } catch (e) {
      // ignore: avoid_print
      print('获取用户排行榜失败: $e');
      return null;
    }
  }
}
