import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sse_market_x/core/api/post_service.dart';
import 'package:sse_market_x/core/models/rating_model.dart';
import 'package:sse_market_x/core/services/browse_history_service.dart';
import 'package:sse_market_x/core/services/blur_effect_service.dart';
import 'package:sse_market_x/shared/components/cards/rating_card.dart';
import 'package:sse_market_x/shared/components/layout/layout_config.dart';
import 'package:sse_market_x/shared/components/loading/skeleton_loader.dart';
import 'package:sse_market_x/shared/components/utils/snackbar_helper.dart';
import 'package:sse_market_x/shared/theme/app_colors.dart';
import 'package:sse_market_x/views/post/create_post_page.dart';
import 'package:sse_market_x/views/post/score_post_detail_page.dart';

/// 打分专区页（对齐官网 /rating：分类 pill + 搜寻 + 评分帖卡列表）
class ScorePage extends StatefulWidget {
  const ScorePage({
    super.key,
    this.onPostTap,
  });

  final Function(int postId)? onPostTap;

  @override
  State<ScorePage> createState() => _ScorePageState();
}

class _ScorePageState extends State<ScorePage> {
  final PostService _postService = PostService();
  final TextEditingController _searchController = TextEditingController();

  /// 「全部」哨兵值：接口 categoryID < 0 表示全部
  static const int _allCategoryId = -1;
  static const int _pageSize = 20;

  List<RatingCategory> _categories = [];
  List<RatingPost> _posts = [];
  int _selectedCategoryId = _allCategoryId;
  String _appliedSearch = '';
  int _offset = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadPosts(refresh: true);
    _clearLegacyCache();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 旧版打分本地缓存（score_posts_cache）已随 browse 旧数据路径弃用，清除残留
  Future<void> _clearLegacyCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('score_posts_cache');
    } catch (e) {
      debugPrint('清除旧打分缓存失败: $e');
    }
  }

  Future<void> _loadCategories() async {
    final categories = await _postService.getRatingCategories();
    if (!mounted) return;
    if (categories == null) {
      // 分类加载失败不阻塞列表，仅保留「全部」pill
      debugPrint('评分分类加载失败，仅保留「全部」');
      return;
    }
    setState(() {
      _categories = categories;
    });
  }

  Future<void> _loadPosts({required bool refresh}) async {
    if (_isLoading || _isLoadingMore) return;

    setState(() {
      if (refresh) {
        _isLoading = true;
        _offset = 0;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      final list = await _postService.getRatingPosts(
        categoryId: _selectedCategoryId,
        searchinfo: _appliedSearch,
        limit: _pageSize,
        offset: refresh ? 0 : _offset,
      );

      if (!mounted) return;

      if (list == null) {
        setState(() {
          if (refresh) {
            _posts = [];
            _hasMore = false;
          }
        });
        SnackBarHelper.show(context, '加载失败，请重试');
        return;
      }

      setState(() {
        _posts = refresh ? list : [..._posts, ...list];
        _offset += list.length;
        _hasMore = list.length == _pageSize;
      });
    } finally {
      // 任何路径（含异常）都保证复位加载标志，防止永久 Skeleton
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onSearchSubmitted() {
    _appliedSearch = _searchController.text.trim();
    _loadPosts(refresh: true);
  }

  void _onCategoryPillTap(int categoryId) {
    if (categoryId == _selectedCategoryId) return;
    setState(() {
      _selectedCategoryId = categoryId;
    });
    _loadPosts(refresh: true);
  }

  /// 卡片分类链接 → 切换到对应分类 pill
  void _switchToCategoryByName(String name) {
    for (final category in _categories) {
      if (category.name == name) {
        _onCategoryPillTap(category.categoryId);
        return;
      }
    }
  }

  void _onCardTap(RatingPost post) {
    // 浏览历史记录（partition 记「打分」）
    BrowseHistoryService().addPostHistory(post.toPostModel());

    final onPostTap = LayoutConfig.of(context)?.onPostTap;
    if (onPostTap != null) {
      // 多栏模式，回调给宿主打开详情面板
      onPostTap(post.ratingPostId, isScorePost: true);
      return;
    }

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => ScorePostDetailPage(
              postId: post.ratingPostId,
              initialPost: post.toPostModel(),
            ),
          ),
        )
        .then((_) => _loadPosts(refresh: true));
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;
    final bottomPadding = kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: ValueListenableBuilder<bool>(
          valueListenable: BlurEffectService().enabledNotifier,
          builder: (context, isBlurEnabled, _) {
            Widget content = Container(
              decoration: BoxDecoration(
                color: isBlurEnabled
                    ? context.blurBackgroundColor.withOpacity(0.82)
                    : context.surfaceColor,
                border: Border(
                  bottom: BorderSide(
                    color: context.dividerColor.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
              ),
            );

            if (isBlurEnabled) {
              return ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: content,
                ),
              );
            } else {
              return content;
            }
          },
        ),
        title: Text(
          '打分专区',
          style: TextStyle(
            color: context.textPrimaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.create_new_folder_outlined,
              color: context.textSecondaryColor,
              size: 22,
            ),
            tooltip: '创建分区',
            onPressed: () {
              SnackBarHelper.show(context, '即将上线');
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: IconButton(
              icon: const Icon(Icons.add, color: AppColors.primary),
              tooltip: '发布打分帖子',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreatePostPage(
                      fromRatingPage: true,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: context.backgroundColor,
      body: _buildBody(context, topPadding, bottomPadding),
    );
  }

  Widget _buildBody(
    BuildContext context,
    double topPadding,
    double bottomPadding,
  ) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Column(
        children: [
          _buildSearchRow(context),
          const SizedBox(height: 8),
          _buildCategoryPills(context),
          const SizedBox(height: 4),
          Expanded(child: _buildList(context, bottomPadding)),
        ],
      ),
    );
  }

  Widget _buildSearchRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _onSearchSubmitted(),
              style: TextStyle(
                fontSize: 14,
                color: context.textPrimaryColor,
              ),
              decoration: InputDecoration(
                hintText: '搜索主题或分区名（如「其他」）',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: context.textTertiaryColor,
                ),
                filled: true,
                fillColor: context.surfaceColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _onSearchSubmitted,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('搜'),
          ),
        ],
      ),
    );
  }

  /// 分类 pill 横向列表：「全部」+ 各分类「{name} {postCount}」
  Widget _buildCategoryPills(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _buildPill(
            context,
            '全部',
            _selectedCategoryId == _allCategoryId,
            () => _onCategoryPillTap(_allCategoryId),
          ),
          for (final category in _categories)
            _buildPill(
              context,
              '${category.name} ${category.postCount}',
              _selectedCategoryId == category.categoryId,
              () => _onCategoryPillTap(category.categoryId),
            ),
        ],
      ),
    );
  }

  Widget _buildPill(
    BuildContext context,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : context.surfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primary : context.dividerColor,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? Colors.white : context.textSecondaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, double bottomPadding) {
    if (_isLoading) {
      return const PostListSkeleton(itemCount: 5, isDense: true);
    }

    if (_posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadPosts(refresh: true),
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 120),
          children: [
            Center(
              child: Text(
                '暂无内容',
                style: TextStyle(
                  fontSize: 15,
                  color: context.textSecondaryColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadPosts(refresh: true),
      color: AppColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: bottomPadding + 16),
        itemCount: _posts.length + 1,
        itemBuilder: (context, index) {
          if (index == _posts.length) {
            if (!_hasMore) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: _isLoadingMore
                    ? const Text(
                        '…',
                        style: TextStyle(fontSize: 14),
                      )
                    : TextButton(
                        onPressed: () => _loadPosts(refresh: false),
                        child: const Text('加载更多'),
                      ),
              ),
            );
          }

          final post = _posts[index];
          return RatingCard(
            ratingPost: post,
            onTap: () => _onCardTap(post),
            onCategoryTap: _switchToCategoryByName,
            onLikeTap: () => _postService.likeRatingPost(post.ratingPostId),
          );
        },
      ),
    );
  }
}
