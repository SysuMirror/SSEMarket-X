import 'package:flutter/material.dart';

import 'package:sse_market_x/core/api/post_service.dart';
import 'package:sse_market_x/core/api/user_service.dart';
import 'package:sse_market_x/core/models/ranking_model.dart';
import 'package:sse_market_x/shared/components/loading/skeleton_loader.dart';
import 'package:sse_market_x/shared/components/media/cached_image.dart';
import 'package:sse_market_x/shared/theme/app_colors.dart';
import 'package:sse_market_x/views/post/post_detail_page.dart';
import 'package:sse_market_x/views/profile/user_profile_page.dart';

// 前三名配色为排行榜页私有常量，不加入 AppColors
const Color _kGoldColor = Color(0xFFF5A623);
const Color _kSilverColor = Color(0xFF8E9AAC);
const Color _kBronzeColor = Color(0xFFCD7F32);

/// 数字格式化：≥10000 显示为 x.xw，≥1000 显示为 x.xk，否则原值
String _formatCount(int value) {
  if (value >= 10000) {
    return '${(value / 10000).toStringAsFixed(1)}w';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}k';
  }
  return value.toString();
}

/// 排行榜页（对应官网 /ranking）
///
/// 双 Tab：「优质榜」帖子得票前 100、「用户榜」获赞与获票合计前 100。
/// 两个 Tab 各自独立加载并缓存结果（AutomaticKeepAliveClientMixin），
/// 切回不重复请求；顺序按服务器返回渲染，无分页。
class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('排行榜'),
        backgroundColor: context.surfaceColor,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: context.textSecondaryColor,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: '优质榜'),
            Tab(text: '用户榜'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _PostRankingTab(),
          _UserRankingTab(),
        ],
      ),
    );
  }
}

/// 载入中骨架屏（副标题 + 颁奖台三卡 + 清单行）
class _RankingSkeleton extends StatelessWidget {
  const _RankingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        SkeletonLoader(
          width: 180,
          height: 13,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: SkeletonLoader(
                width: double.infinity,
                height: 140,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SkeletonLoader(
                width: double.infinity,
                height: 156,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SkeletonLoader(
                width: double.infinity,
                height: 140,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(6, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const SkeletonLoader(width: 24, height: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLoader(
                        width: double.infinity,
                        height: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      SkeletonLoader(
                        width: 160,
                        height: 12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

/// 空状态
class _RankingEmptyView extends StatelessWidget {
  const _RankingEmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 48,
            color: context.textTertiaryColor,
          ),
          const SizedBox(height: 12),
          Text(
            '暂无数据',
            style: TextStyle(
              fontSize: 15,
              color: context.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '投票或互动后，榜单会在这里更新',
            style: TextStyle(
              fontSize: 13,
              color: context.textTertiaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// 错误状态（可重试）
class _RankingErrorView extends StatelessWidget {
  const _RankingErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: context.textTertiaryColor,
          ),
          const SizedBox(height: 12),
          Text(
            '获取排行榜失败',
            style: TextStyle(
              fontSize: 15,
              color: context.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

/// 榜单 Tab 共用骨架：加载状态机（isLoading/hasError/entries + KeepAlive）、
/// 骨架屏/错误/空三态、副标题、颁奖台（2-1-3）与第 4 名起清单列外壳。
/// 子类注入：取数方法、副标文案、冠军卡垂直内边距、颁奖台卡内容、
/// 清单列内容、点击导航。
abstract class _RankingTabState<W extends StatefulWidget, E>
    extends State<W> with AutomaticKeepAliveClientMixin {
  List<E> _entries = const [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    final result = await fetchEntries();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _hasError = result == null;
      _entries = result ?? const [];
    });
  }

  // ---- 子类注入点 ----

  Future<List<E>?> fetchEntries();

  String get subtitle;

  /// 冠军卡垂直内边距（优质榜 22、用户榜 20，其余卡均为 12）
  double get championCardVerticalPadding;

  /// 颁奖台卡 Column 的内容（图标/文字行）
  List<Widget> podiumCardChildren(
    BuildContext context,
    E entry, {
    required Color color,
    required IconData icon,
    required bool isChampion,
  });

  /// 清单列中名次数字之后的内容
  List<Widget> listRowTrailing(BuildContext context, E entry);

  void onEntryTap(BuildContext context, E entry);

  // ---- 共用渲染 ----

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) return const _RankingSkeleton();
    if (_hasError) return _RankingErrorView(onRetry: _load);
    if (_entries.isEmpty) return const _RankingEmptyView();

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      children: [
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: context.textTertiaryColor,
          ),
        ),
        const SizedBox(height: 12),
        _buildPodium(context),
        const SizedBox(height: 16),
        ..._buildListRows(context),
      ],
    );
  }

  /// 前三名颁奖台：第 2 名左、第 1 名置中、第 3 名右
  Widget _buildPodium(BuildContext context) {
    final first = _entries.isNotEmpty ? _entries[0] : null;
    final second = _entries.length > 1 ? _entries[1] : null;
    final third = _entries.length > 2 ? _entries[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (second != null) ...[
          Expanded(
            child: _buildPodiumCard(
              context,
              entry: second,
              color: _kSilverColor,
              icon: Icons.workspace_premium,
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (first != null)
          Expanded(
            child: _buildPodiumCard(
              context,
              entry: first,
              color: _kGoldColor,
              icon: Icons.emoji_events,
              isChampion: true,
            ),
          ),
        if (third != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _buildPodiumCard(
              context,
              entry: third,
              color: _kBronzeColor,
              icon: Icons.military_tech,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPodiumCard(
    BuildContext context, {
    required E entry,
    required Color color,
    required IconData icon,
    bool isChampion = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: isChampion ? championCardVerticalPadding : 12,
      ),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onEntryTap(context, entry),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: podiumCardChildren(
              context,
              entry,
              color: color,
              icon: icon,
              isChampion: isChampion,
            ),
          ),
        ),
      ),
    );
  }

  /// 第 4 名起的一般清单
  List<Widget> _buildListRows(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 3; i < _entries.length; i++) {
      final entry = _entries[i];
      rows.add(
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onEntryTap(context, entry),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: context.textTertiaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ...listRowTrailing(context, entry),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return rows;
  }
}

/// 分区标签（primary 淡色底）
Widget _buildPartitionTag(BuildContext context, String partition) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      partition,
      style: const TextStyle(fontSize: 11, color: AppColors.primary),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  );
}

/// 用户头像：空或加载失败时回退为名字首字 /「用」
Widget _buildUserAvatar(
  BuildContext context,
  UserRankingEntry entry,
  double size,
) {
  final fallbackChar = entry.userName.isNotEmpty
      ? entry.userName.substring(0, 1)
      : '用';

  Widget fallback = Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.primary.withOpacity(0.12),
      shape: BoxShape.circle,
    ),
    child: Text(
      fallbackChar,
      style: TextStyle(
        fontSize: size * 0.42,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      ),
    ),
  );

  if (entry.avatarUrl.isEmpty) return fallback;

  return CachedImage(
    imageUrl: entry.avatarUrl,
    width: size,
    height: size,
    fit: BoxFit.cover,
    borderRadius: BorderRadius.circular(size / 2),
    errorWidget: fallback,
  );
}

/// 优质榜 Tab
class _PostRankingTab extends StatefulWidget {
  const _PostRankingTab();

  @override
  State<_PostRankingTab> createState() => _PostRankingTabState();
}

class _PostRankingTabState
    extends _RankingTabState<_PostRankingTab, PostRankingEntry> {
  final PostService _postService = PostService();

  @override
  Future<List<PostRankingEntry>?> fetchEntries() =>
      _postService.getPostRanking();

  @override
  String get subtitle => '按得票数排序 · 前 100 名';

  @override
  double get championCardVerticalPadding => 22;

  @override
  List<Widget> podiumCardChildren(
    BuildContext context,
    PostRankingEntry entry, {
    required Color color,
    required IconData icon,
    required bool isChampion,
  }) {
    return [
      Icon(icon, size: isChampion ? 34 : 26, color: color),
      const SizedBox(height: 6),
      Text(
        '${_formatCount(entry.voteCount)} 票',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: color,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 6),
      Text(
        entry.title.isEmpty ? '无标题' : entry.title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: context.textPrimaryColor,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      if (entry.partition.isNotEmpty)
        _buildPartitionTag(context, entry.partition),
    ];
  }

  @override
  List<Widget> listRowTrailing(BuildContext context, PostRankingEntry entry) {
    return [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.title.isEmpty ? '无标题' : entry.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (entry.partition.isNotEmpty) ...[
                  Flexible(
                    child: _buildPartitionTag(context, entry.partition),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  '${_formatCount(entry.voteCount)} 票',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  @override
  void onEntryTap(BuildContext context, PostRankingEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PostDetailPage(postId: entry.postId)),
    );
  }
}

/// 用户榜 Tab
class _UserRankingTab extends StatefulWidget {
  const _UserRankingTab();

  @override
  State<_UserRankingTab> createState() => _UserRankingTabState();
}

class _UserRankingTabState
    extends _RankingTabState<_UserRankingTab, UserRankingEntry> {
  final UserService _userService = UserService();

  @override
  Future<List<UserRankingEntry>?> fetchEntries() =>
      _userService.getUserRanking();

  @override
  String get subtitle => '获赞与获票合计 · 前 100 名';

  @override
  double get championCardVerticalPadding => 20;

  @override
  List<Widget> podiumCardChildren(
    BuildContext context,
    UserRankingEntry entry, {
    required Color color,
    required IconData icon,
    required bool isChampion,
  }) {
    final avatarSize = isChampion ? 64.0 : 52.0;

    return [
      SizedBox(
        width: avatarSize + 8,
        height: avatarSize + 8,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: _buildUserAvatar(context, entry, avatarSize),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.surfaceColor,
                    width: 1.5,
                  ),
                ),
                child: Icon(icon, size: 12, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Text(
        entry.userName.isNotEmpty ? entry.userName : '匿名用户',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: context.textPrimaryColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 4),
      Text(
        '合计 ${_formatCount(entry.totalScore)}',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: color,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 2),
      Text(
        '赞 ${_formatCount(entry.receivedLikeNum)} · 票 ${_formatCount(entry.receivedVoteNum)}',
        style: TextStyle(
          fontSize: 11,
          color: context.textTertiaryColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ];
  }

  @override
  List<Widget> listRowTrailing(BuildContext context, UserRankingEntry entry) {
    return [
      _buildUserAvatar(context, entry, 40),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.userName.isNotEmpty ? entry.userName : '匿名用户',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '赞 ${_formatCount(entry.receivedLikeNum)}'
              ' · 票 ${_formatCount(entry.receivedVoteNum)}'
              ' · 合计 ${_formatCount(entry.totalScore)}',
              style: TextStyle(
                fontSize: 13,
                color: context.textSecondaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ];
  }

  @override
  void onEntryTap(BuildContext context, UserRankingEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserProfilePage(userId: entry.userId),
      ),
    );
  }
}
