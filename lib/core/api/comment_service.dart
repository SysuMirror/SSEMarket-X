import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:sse_market_x/core/api/api_client.dart';
import 'package:sse_market_x/core/models/comment_model.dart';

/// 评论 API 服务
class CommentService {
  final ApiClient _client;

  CommentService({ApiClient client = const ApiClient()}) : _client = client;

  String get token => _client.token;

  /// 获取帖子评论列表
  Future<List<CommentModel>> getComments(int postId, String userPhone, {String postType = 'post'}) async {
    if (token.isEmpty) return [];

    final uri = Uri.parse('${_client.baseUrl}/auth/showPcomments');
    final body = jsonEncode(<String, dynamic>{
      'postID': postId,
      'userTelephone': userPhone,
      'postType': postType,
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

      if (response.statusCode != 200) {
        return [];
      }

      final dynamic json = jsonDecode(response.body);
      if (json is List) {
        return json.map<CommentModel>((e) => CommentModel.fromDynamic(e)).toList();
      }
      if (json is Map<String, dynamic> && json['data'] is List) {
        final list = json['data'] as List<dynamic>;
        return list.map<CommentModel>((e) => CommentModel.fromDynamic(e)).toList();
      }
      return [];
    } catch (e) {
      // ignore: avoid_print
      print('获取评论列表失败: $e');
      return [];
    }
  }

  /// 发送评论
  Future<bool> sendComment(String content, int postId, String userPhone) async {
    if (token.isEmpty || userPhone.isEmpty) return false;

    final uri = Uri.parse('${_client.baseUrl}/auth/postPcomment');
    final body = jsonEncode(<String, dynamic>{
      'content': content,
      'postID': postId,
      'userTelephone': userPhone,
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

      return response.statusCode == 200;
    } catch (e) {
      // ignore: avoid_print
      print('发送评论失败: $e');
      return false;
    }
  }

  /// 发送打分帖评论（对应 /auth/rating/comment/create，可附带星级）
  /// 用户身份由 Bearer token 标识
  Future<bool> sendRatingComment(String content, int postId, int starNum) async {
    if (token.isEmpty) return false;

    final uri = Uri.parse('${_client.baseUrl}/auth/rating/comment/create');
    final body = jsonEncode(<String, dynamic>{
      'ratingPostID': postId,
      'content': content,
      'starNum': starNum,
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
        if (data is Map && data['code'] != null) {
          return data['code'] == 200;
        }
        return true;
      }
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('发送打分帖评论失败: $e');
      return false;
    }
  }

  /// 获取打分帖评论列表（对应 /auth/rating/comment/list）
  Future<List<CommentModel>> getRatingComments(int ratingPostId) async {
    if (token.isEmpty) return [];

    final uri = Uri.parse('${_client.baseUrl}/auth/rating/comment/list');
    final body = jsonEncode(<String, dynamic>{
      'ratingPostID': ratingPostId,
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
        final dynamic json = jsonDecode(response.body);
        if (json is List) {
          return json.map<CommentModel>((e) => CommentModel.fromDynamic(e)).toList();
        }
        if (json is Map<String, dynamic> && json['data'] is List) {
          final list = json['data'] as List<dynamic>;
          return list.map<CommentModel>((e) => CommentModel.fromDynamic(e)).toList();
        }
      }
      return [];
    } catch (e) {
      // ignore: avoid_print
      print('获取打分帖评论失败: $e');
      return [];
    }
  }

  /// 发送子评论（回复评论）
  Future<bool> sendSubComment({
    required String content,
    required int postId,
    required int parentCommentId,
    int? targetCommentId,
    String? targetUserName,
  }) async {
    if (token.isEmpty) return false;

    final uri = Uri.parse('${_client.baseUrl}/auth/postCcomment');
    final body = <String, dynamic>{
      'content': content,
      'postID': postId,
      'pcommentID': parentCommentId,
      'userTelephone': await _client.getUserPhone(),
    };

    // 如果是回复子评论，添加额外参数
    if (targetCommentId != null) {
      body['ccommentID'] = targetCommentId;
    }
    if (targetUserName != null && targetUserName.isNotEmpty) {
      body['userTargetName'] = targetUserName;
    }

    try {
      final response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      // ignore: avoid_print
      print('发送子评论失败: $e');
      return false;
    }
  }

  /// 点赞评论
  Future<bool> likeComment(int commentId, String userPhone) async {
    if (token.isEmpty || userPhone.isEmpty) return false;

    final uri = Uri.parse('${_client.baseUrl}/auth/updatePcommentLike');
    final body = jsonEncode(<String, dynamic>{
      'pcommentID': commentId,
      'userTelephone': userPhone,
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

      return response.statusCode == 200;
    } catch (e) {
      // ignore: avoid_print
      print('点赞评论失败: $e');
      return false;
    }
  }

  /// 点赞子评论
  Future<bool> likeSubComment(int subCommentId, String userPhone) async {
    if (token.isEmpty || userPhone.isEmpty) return false;

    final uri = Uri.parse('${_client.baseUrl}/auth/updateCcommentLike');
    final body = jsonEncode(<String, dynamic>{
      'ccommentID': subCommentId,
      'userTelephone': userPhone,
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

      return response.statusCode == 200;
    } catch (e) {
      // ignore: avoid_print
      print('点赞子评论失败: $e');
      return false;
    }
  }

  /// 删除评论
  Future<bool> deleteComment(int commentId) async {
    if (token.isEmpty) return false;

    final uri = Uri.parse('${_client.baseUrl}/auth/deletePcomment');
    final body = jsonEncode(<String, dynamic>{
      'pcommentID': commentId,
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

      return response.statusCode == 200;
    } catch (e) {
      // ignore: avoid_print
      print('删除评论失败: $e');
      return false;
    }
  }

  /// 删除子评论
  Future<bool> deleteSubComment(int subCommentId) async {
    if (token.isEmpty) return false;

    final uri = Uri.parse('${_client.baseUrl}/auth/deleteCcomment');
    final body = jsonEncode(<String, dynamic>{
      'ccommentID': subCommentId,
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

      return response.statusCode == 200;
    } catch (e) {
      // ignore: avoid_print
      print('删除子评论失败: $e');
      return false;
    }
  }
}
