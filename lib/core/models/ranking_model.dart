// 排行榜数据模型
//
// 对应 /auth/postRanking 与 /auth/userRanking 返回的 data.ranking 条目。
// 字段解析保留多 key fallback（后端存在大小写差异，如 postID/PostID）。

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

double _readDouble(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final v = map[key];
    if (v is num) return v.toDouble();
    if (v is String) {
      final parsed = double.tryParse(v);
      if (parsed != null) return parsed;
    }
  }
  return 0;
}

/// 优质榜条目（帖子得票排名）
class PostRankingEntry {
  final int postId;
  final String title;
  final String partition;
  final int voteCount;
  final String postTime;

  const PostRankingEntry({
    required this.postId,
    required this.title,
    required this.partition,
    required this.voteCount,
    required this.postTime,
  });

  factory PostRankingEntry.fromDynamic(dynamic raw) {
    if (raw is! Map) {
      return const PostRankingEntry(
        postId: 0,
        title: '',
        partition: '',
        voteCount: 0,
        postTime: '',
      );
    }
    final map = raw.cast<String, dynamic>();
    return PostRankingEntry(
      postId: _readInt(map, ['postID', 'PostID']),
      title: _readString(map, ['title', 'Title']),
      partition: _readString(map, ['partition', 'Partition']),
      voteCount: _readInt(map, ['voteCount', 'VoteCount']),
      postTime: _readString(map, ['postTime', 'PostTime']),
    );
  }
}

/// 用户榜条目（获赞与获票合计排名）
class UserRankingEntry {
  final int userId;
  final String userName;
  final String avatarUrl;
  final int receivedLikeNum;
  final int receivedVoteNum;

  /// 官网 rankScore 计算公式未确认，App 端只接收不显示
  final double rankScore;

  const UserRankingEntry({
    required this.userId,
    required this.userName,
    required this.avatarUrl,
    required this.receivedLikeNum,
    required this.receivedVoteNum,
    required this.rankScore,
  });

  /// 合计按获赞 + 获票计算（不使用 rankScore）
  int get totalScore => receivedLikeNum + receivedVoteNum;

  factory UserRankingEntry.fromDynamic(dynamic raw) {
    if (raw is! Map) {
      return const UserRankingEntry(
        userId: 0,
        userName: '',
        avatarUrl: '',
        receivedLikeNum: 0,
        receivedVoteNum: 0,
        rankScore: 0,
      );
    }
    final map = raw.cast<String, dynamic>();
    return UserRankingEntry(
      userId: _readInt(map, ['userID', 'UserID', 'id']),
      userName: _readString(map, ['userName', 'UserName', 'name']),
      avatarUrl: _readString(map, ['avatarURL', 'AvatarURL', 'avatar']),
      receivedLikeNum: _readInt(map, ['receivedLikeNum', 'ReceivedLikeNum']),
      receivedVoteNum: _readInt(map, ['receivedVoteNum', 'ReceivedVoteNum']),
      rankScore: _readDouble(map, ['rankScore', 'RankScore']),
    );
  }
}
