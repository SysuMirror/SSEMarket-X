import 'package:sse_market_x/core/models/post_model.dart';

/// 响应结构不符合预期（服务端接口可能已变更/升级）
/// 由页面捕获后向用户显示「内容升级中」
class ApiResponseFormatError implements Exception {
  final String message;
  const ApiResponseFormatError([this.message = '响应结构不符合预期']);

  @override
  String toString() => message;
}

/// /auth/browse 响应结果：置顶帖与一般帖分页分离
///
/// 分页计数（offset 推进、hasMore 判断）只应使用 [posts]（不含 pinned）；
/// [pinned] 由页面在首页（offset==0）自行插入列表顶部，不得混入计数。
class GetPostsResult {
  /// 一般帖（本页 posts 箱）
  final List<PostModel> posts;

  /// 置顶帖（与 posts 已按 PostID 去重，可能为空）
  final List<PostModel> pinned;

  const GetPostsResult({required this.posts, this.pinned = const []});
}

/// 帖子列表请求参数
class GetPostsParams {
  final int limit;
  final int offset;
  final String partition;
  final String searchsort;
  final String searchinfo;
  final String userTelephone;
  final String tag;

  const GetPostsParams({
    required this.limit,
    required this.offset,
    required this.partition,
    required this.searchsort,
    required this.searchinfo,
    required this.userTelephone,
    required this.tag,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'limit': limit,
        'offset': offset,
        'partition': partition,
        'searchsort': searchsort,
        'searchinfo': searchinfo,
        'userTelephone': userTelephone,
        'tag': tag,
      };
}

/// 打分帖评分数据（对应 /auth/rating/post/detail 返回）
class RatingDetail {
  final double averageRating;
  final List<int> stars; // 长度 5，依次为 1~5 星数量
  final int userStar; // 当前用户评分，0 表示未评分
  final int raterCount;

  const RatingDetail({
    required this.averageRating,
    required this.stars,
    required this.userStar,
    required this.raterCount,
  });
}
