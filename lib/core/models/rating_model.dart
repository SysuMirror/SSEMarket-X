import 'package:sse_market_x/core/models/post_model.dart';

// 打分专区数据模型
//
// 对应 /auth/rating/category/list 与 /auth/rating/post/list 返回的裸陣列条目。
// 字段一律容错解析（参考 ranking_model.dart 写法）。
// 人评数固定用 stars 陣列總和（官网 Σstars 语义），raterCount 仅接收备用。

int _readInt(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final v = map[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      final parsed = int.tryParse(v);
      if (parsed != null) return parsed;
    }
  }
  return 0;
}

String _readString(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final v = map[key];
    if (v is String) return v;
  }
  return '';
}

bool _readBool(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final v = map[key];
    if (v is bool) return v;
    if (v is int) return v != 0;
    if (v is String) return v.toLowerCase() == 'true' || v == '1';
  }
  return false;
}

double _readDouble(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final v = map[key];
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) {
      final parsed = double.tryParse(v);
      if (parsed != null) return parsed;
    }
  }
  return 0.0;
}

List<int> _readListInt(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final v = map[key];
    if (v is List) {
      return v.map((e) {
        if (e is int) return e;
        if (e is num) return e.toInt();
        if (e is String) return int.tryParse(e) ?? 0;
        return 0;
      }).toList();
    }
  }
  return [];
}

/// 评分分类
class RatingCategory {
  final int categoryId;
  final String name;
  final String description;
  final int postCount;

  const RatingCategory({
    required this.categoryId,
    required this.name,
    required this.description,
    required this.postCount,
  });

  factory RatingCategory.fromDynamic(dynamic raw) {
    if (raw is! Map) {
      return const RatingCategory(
        categoryId: 0,
        name: '',
        description: '',
        postCount: 0,
      );
    }
    final map = raw.cast<String, dynamic>();
    return RatingCategory(
      categoryId: _readInt(map, ['categoryID', 'CategoryID', 'categoryID']),
      name: _readString(map, ['name', 'Name']),
      description: _readString(map, ['description', 'Description']),
      postCount: _readInt(map, ['postCount', 'PostCount']),
    );
  }
}

/// 评分帖
class RatingPost {
  final int ratingPostId;
  final int categoryId;
  final String categoryName;
  final int userId;
  final String userName;
  final int userScore;
  final String userTelephone;
  final String userAvatar;
  final String userIdentity;
  final String title;
  final String content;
  final int like;
  final int comment;
  final int browse;
  final String createdAt;
  final bool isLiked;
  final String photos;
  final double averageRating;

  /// 1~5 星人数（5 元素）
  final List<int> stars;

  /// 官网语义未确认，仅接收备用（人评数用 stars 总和）
  final int raterCount;

  const RatingPost({
    required this.ratingPostId,
    required this.categoryId,
    required this.categoryName,
    required this.userId,
    required this.userName,
    required this.userScore,
    required this.userTelephone,
    required this.userAvatar,
    required this.userIdentity,
    required this.title,
    required this.content,
    required this.like,
    required this.comment,
    required this.browse,
    required this.createdAt,
    required this.isLiked,
    required this.photos,
    required this.averageRating,
    required this.stars,
    required this.raterCount,
  });

  /// 人评数 = stars 陣列總和（官网 Σstars 语义）
  int get totalRatings => stars.fold(0, (sum, count) => sum + count);

  /// 转为 PostModel 供浏览历史等既有组件复用（partition 记「打分」）
  PostModel toPostModel() {
    return PostModel(
      id: ratingPostId,
      title: title,
      content: content,
      partition: '打分',
      authorName: userName,
      authorAvatar: userAvatar,
      authorPhone: userTelephone,
      createdAt: createdAt,
      likeCount: like,
      commentCount: comment,
      saveCount: 0,
      viewCount: browse,
      userScore: userScore,
      userIdentity: userIdentity,
      isLiked: isLiked,
      isSaved: false,
      rating: averageRating,
      stars: stars,
      userRating: 0,
      heat: 0,
    );
  }

  /// 由浏览历史等处的 PostModel 反向构造（仅映射显示所需字段）
  factory RatingPost.fromPostModel(PostModel post) {
    return RatingPost(
      ratingPostId: post.id,
      categoryId: 0,
      categoryName: post.partition,
      userId: 0,
      userName: post.authorName,
      userScore: post.userScore,
      userTelephone: post.authorPhone,
      userAvatar: post.authorAvatar,
      userIdentity: post.userIdentity,
      title: post.title,
      content: post.content,
      like: post.likeCount,
      comment: post.commentCount,
      browse: post.viewCount,
      createdAt: post.createdAt,
      isLiked: post.isLiked,
      photos: '',
      averageRating: post.rating,
      stars: post.stars,
      raterCount: 0,
    );
  }

  factory RatingPost.fromDynamic(dynamic raw) {
    if (raw is! Map) {
      return const RatingPost(
        ratingPostId: 0,
        categoryId: 0,
        categoryName: '',
        userId: 0,
        userName: '',
        userScore: 0,
        userTelephone: '',
        userAvatar: '',
        userIdentity: '',
        title: '',
        content: '',
        like: 0,
        comment: 0,
        browse: 0,
        createdAt: '',
        isLiked: false,
        photos: '',
        averageRating: 0.0,
        stars: [],
        raterCount: 0,
      );
    }
    final map = raw.cast<String, dynamic>();
    return RatingPost(
      ratingPostId: _readInt(
        map,
        ['ratingPostID', 'RatingPostID', 'ratingPostId', 'id'],
      ),
      categoryId: _readInt(map, ['categoryID', 'CategoryID']),
      categoryName: _readString(map, ['categoryName', 'CategoryName']),
      userId: _readInt(map, ['userID', 'UserID']),
      userName: _readString(map, ['userName', 'UserName']),
      userScore: _readInt(map, ['userScore', 'UserScore', 'Score']),
      userTelephone: _readString(map, ['userTelephone', 'UserTelephone']),
      userAvatar: _readString(
        map,
        ['userAvatar', 'UserAvatar', 'avatarURL', 'avatar'],
      ),
      userIdentity: _readString(map, ['userIdentity', 'UserIdentity']),
      title: _readString(map, ['title', 'Title']),
      content: _readString(map, ['content', 'Content']),
      like: _readInt(map, ['like', 'Like', 'likeNum', 'LikeNum']),
      comment: _readInt(map, ['comment', 'Comment', 'commentNum', 'CommentNum']),
      browse: _readInt(map, ['browse', 'Browse', 'viewNum', 'ViewNum']),
      createdAt: _readString(
        map,
        ['createdAt', 'CreatedAt', 'postTime', 'PostTime'],
      ),
      isLiked: _readBool(map, ['isLiked', 'IsLiked']),
      photos: _readString(map, ['photos', 'Photos']),
      averageRating: _readDouble(
        map,
        ['averageRating', 'AverageRating', 'rating', 'Rating'],
      ),
      stars: _readListInt(map, ['stars', 'Stars']),
      raterCount: _readInt(map, ['raterCount', 'RaterCount']),
    );
  }
}
