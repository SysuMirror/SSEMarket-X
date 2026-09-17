import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:sse_market_x/core/api/api_client.dart';
import 'package:sse_market_x/core/api/api_types.dart';
import 'package:sse_market_x/core/models/post_model.dart';
import 'package:sse_market_x/core/models/ranking_model.dart';
import 'package:sse_market_x/core/models/rating_model.dart';

/// 帖子 API 服务
class PostService {
  final ApiClient _client;

  PostService({ApiClient client = const ApiClient()}) : _client = client;

  String get token => _client.token;

  /// 获取帖子列表（对应 /auth/browse）
  ///
  /// 返回 pinned 与 posts 分离的结果；分页计数（offset 推进、hasMore 判断）
  /// 只应使用一般帖（result.posts），pinned 由页面在首页自行插入列表顶部。
  Future<GetPostsResult> getPosts(GetPostsParams params) async {
    if (token.isEmpty) {
      return const GetPostsResult(posts: []);
    }

    final uri = Uri.parse('${_client.baseUrl}/auth/browse');
    final body = jsonEncode(params.toJson());

    final response = await http.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      return const GetPostsResult(posts: []);
    }

    // 后端返回 { pinned: [...], posts: [...], total: 0 }
    // 结构不符（如服务端接口变更/升级）时抛出，由页面显示「内容升级中」
    dynamic json;
    try {
      json = jsonDecode(response.body);
    } catch (_) {
      throw const ApiResponseFormatError('browse 响应不是有效 JSON');
    }
    if (json is! Map<String, dynamic> || json['posts'] is! List) {
      throw const ApiResponseFormatError('browse 响应缺少 posts 字段');
    }

    final posts = (json['posts'] as List<dynamic>)
        .map<PostModel>((e) => PostModel.fromDynamic(e))
        .toList();

    // 置顶帖单独返回（按 PostID 与 posts 去重），不再合并进 posts
    if (json['pinned'] is List) {
      final existingIds = posts.map((p) => p.id).toSet();
      final pinned = (json['pinned'] as List<dynamic>)
          .map<PostModel>((e) => PostModel.fromDynamic(e))
          .where((p) => p.id != 0 && !existingIds.contains(p.id))
          .toList();
      return GetPostsResult(posts: posts, pinned: pinned);
    }
    return GetPostsResult(posts: posts);
  }

  /// 点赞帖子
  Future<bool> likePost(int postId, String userPhone) async {
    if (token.isEmpty || userPhone.isEmpty) return false;

    final uri = Uri.parse('${_client.baseUrl}/auth/updateLike');
    final body = jsonEncode(<String, dynamic>{
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
      print('点赞失败: $e');
      return false;
    }
  }

  /// 获取帖子详情
  Future<PostModel> getPostDetail(int postId, String userPhone) async {
    if (token.isEmpty) return PostModel.empty();

    final uri = Uri.parse('${_client.baseUrl}/auth/showDetails');
    final body = jsonEncode(<String, dynamic>{
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

      if (response.statusCode != 200) {
        return PostModel.empty();
      }

      final dynamic json = jsonDecode(response.body);
      if (json is Map<String, dynamic> && json['data'] != null) {
        return PostModel.fromDynamic(json['data']);
      }
      return PostModel.fromDynamic(json);
    } catch (e) {
      // ignore: avoid_print
      print('获取帖子详情失败: $e');
      return PostModel.empty();
    }
  }

  /// 发布帖子
  Future<bool> createPost(
    String title,
    String content,
    String partition,
    String userTelephone, {
    String photos = '',
    String tagList = '',
  }) async {
    if (token.isEmpty || userTelephone.isEmpty) return false;

    final uri = Uri.parse('${_client.baseUrl}/auth/post');
    final body = jsonEncode(<String, dynamic>{
      'title': title,
      'content': content,
      'partition': partition,
      'photos': photos,
      'tagList': tagList,
      'userTelephone': userTelephone,
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
      print('发布帖子失败: $e');
      return false;
    }
  }

  /// 收藏/取消收藏帖子
  Future<bool> savePost(int postId, String userTelephone) async {
    if (token.isEmpty || userTelephone.isEmpty) return false;

    final uri = Uri.parse('${_client.baseUrl}/auth/updateSave');
    final body = jsonEncode(<String, dynamic>{
      'postID': postId,
      'userTelephone': userTelephone,
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
      print('收藏帖子失败: $e');
      return false;
    }
  }

  /// 删除帖子
  Future<bool> deletePost(int postId) async {
    if (token.isEmpty) return false;

    final uri = Uri.parse('${_client.baseUrl}/auth/deletePost');
    final body = jsonEncode(<String, dynamic>{
      'postID': postId,
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
      print('删除帖子失败: $e');
      return false;
    }
  }

  /// 提交评分（对应 /auth/rating/star/submit，用户身份由 Bearer token 标识）
  Future<bool> submitRating(int postId, int starNum) async {
    if (token.isEmpty) return false;

    final uri = Uri.parse('${_client.baseUrl}/auth/rating/star/submit');
    final body = jsonEncode(<String, dynamic>{
      'ratingPostID': postId,
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
      print('提交评分失败: $e');
      return false;
    }
  }

  /// 获取打分帖评分详情（对应 /auth/rating/post/detail）
  /// 一次返回平均分、星级分布与当前用户评分
  Future<RatingDetail?> getRatingPostDetail(int ratingPostId) async {
    if (token.isEmpty) return null;

    final uri = Uri.parse('${_client.baseUrl}/auth/rating/post/detail');
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

      if (response.statusCode != 200) return null;

      final dynamic json = jsonDecode(response.body);
      if (json is! Map) return null;
      final data = json['data'] is Map ? json['data'] as Map : json;

      final starsRaw = data['stars'];
      final stars = List<int>.generate(5, (i) {
        if (starsRaw is List && i < starsRaw.length) {
          final v = starsRaw[i];
          if (v is num) return v.toInt();
          if (v is String) return int.tryParse(v) ?? 0;
        }
        return 0;
      });

      return RatingDetail(
        averageRating: data['averageRating'] is num
            ? (data['averageRating'] as num).toDouble()
            : 0.0,
        stars: stars,
        userStar: data['userStar'] is num ? (data['userStar'] as num).toInt() : 0,
        raterCount: data['raterCount'] is num ? (data['raterCount'] as num).toInt() : 0,
      );
    } catch (e) {
      // ignore: avoid_print
      print('获取评分详情失败: $e');
      return null;
    }
  }

  /// 获取热榜帖子
  Future<List<PostModel>> getHeatPosts() async {
    if (token.isEmpty) return [];

    final uri = Uri.parse('${_client.baseUrl}/auth/calculateHeat');

    try {
      final response = await http.get(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((e) => PostModel.fromDynamic(e)).toList();
        }
        if (data is Map && data['data'] is List) {
          return (data['data'] as List)
              .map((e) => PostModel.fromDynamic(e))
              .toList();
        }
      }
      return [];
    } catch (e) {
      // ignore: avoid_print
      print('获取热榜帖子失败: $e');
      return [];
    }
  }

  /// 获取帖子排行榜（对应 /auth/postRanking，服务器固定返回前 100 名，无分页）
  /// 失败（网络错误/状态码非 200/结构不符）返回 null，页面显示错误态可重试；
  /// 成功但无数据返回空列表
  Future<List<PostRankingEntry>?> getPostRanking() async {
    if (token.isEmpty) return null;

    final uri = Uri.parse('${_client.baseUrl}/auth/postRanking');

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
          .map((e) => PostRankingEntry.fromDynamic(e))
          .toList();
    } catch (e) {
      // ignore: avoid_print
      print('获取帖子排行榜失败: $e');
      return null;
    }
  }

  /// 获取评分分类（对应 /auth/rating/category/list，回裸陣列）
  /// 客户端过滤 name 为 "test"（trim + 小写）的脏数据，按 categoryID 降冪（官网行为）
  Future<List<RatingCategory>?> getRatingCategories() async {
    if (token.isEmpty) return null;

    final uri = Uri.parse('${_client.baseUrl}/auth/rating/category/list');

    try {
      final response = await http
          .post(
            uri,
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(<String, dynamic>{}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return null;

      final dynamic json = jsonDecode(response.body);
      if (json is! List) return null;

      final categories = json
          .map((e) => RatingCategory.fromDynamic(e))
          .where((c) => c.name.trim().toLowerCase() != 'test')
          .toList()
        ..sort((a, b) => b.categoryId.compareTo(a.categoryId));
      return categories;
    } catch (e) {
      // ignore: avoid_print
      print('获取评分分类失败: $e');
      return null;
    }
  }

  /// 获取评分帖列表（对应 /auth/rating/post/list，回裸陣列）
  /// [categoryId] < 0 表示全部；[searchinfo] 传 trim 后的关键字
  Future<List<RatingPost>?> getRatingPosts({
    required int categoryId,
    String searchinfo = '',
    int limit = 20,
    int offset = 0,
  }) async {
    if (token.isEmpty) return null;

    final uri = Uri.parse('${_client.baseUrl}/auth/rating/post/list');

    try {
      final response = await http
          .post(
            uri,
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(<String, dynamic>{
              'categoryID': categoryId,
              'searchinfo': searchinfo.trim(),
              'limit': limit,
              'offset': offset,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return null;

      final dynamic json = jsonDecode(response.body);
      if (json is! List) return null;

      return json.map((e) => RatingPost.fromDynamic(e)).toList();
    } catch (e) {
      // ignore: avoid_print
      print('获取评分帖列表失败: $e');
      return null;
    }
  }

  /// 点赞评分帖（对应 /auth/rating/post/like，成功语义为回應 code == 200）
  Future<bool> likeRatingPost(int ratingPostId) async {
    if (token.isEmpty) return false;

    final uri = Uri.parse('${_client.baseUrl}/auth/rating/post/like');

    try {
      final response = await http
          .post(
            uri,
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(<String, dynamic>{
              'ratingPostID': ratingPostId,
            }),
          )
          .timeout(const Duration(seconds: 15));

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
      print('点赞评分帖失败: $e');
      return false;
    }
  }
}
