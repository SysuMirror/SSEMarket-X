import 'package:flutter/material.dart';

import 'package:sse_market_x/core/api/api_types.dart';
import 'package:sse_market_x/core/api/post_service.dart';
import 'package:sse_market_x/core/models/post_model.dart';
import 'package:sse_market_x/core/models/user_model.dart';
import 'package:sse_market_x/core/services/storage_service.dart';
import 'package:sse_market_x/shared/components/cards/post_card.dart';
import 'package:sse_market_x/shared/components/feedback/content_upgrading_placeholder.dart';
import 'package:sse_market_x/shared/components/loading/loading_indicator.dart';
import 'package:sse_market_x/shared/components/loading/skeleton_loader.dart';
import 'package:sse_market_x/shared/theme/app_colors.dart';
import 'package:sse_market_x/views/post/post_detail_page.dart';

/// 分区浏览页：以卡片展示各分区，点击进入对应分区的帖子列表
class PartitionPage extends StatelessWidget {
  const PartitionPage({
    super.key,
    this.contentPadding = EdgeInsets.zero,
  });

  final EdgeInsetsGeometry contentPadding;

  /// 显示名称 -> API 分区名称
  static const Map<String, String> _partitions = <String, String>{
    '院务': '院务',
    '课程': '课程交流',
    '学习解惑': '学习交流',
    '打听求助': '打听求助',
    '随想随记': '日常吐槽',
    '求职招募': '求职招募',
    '课程专区': '课程专区',
    '其他': '其他',
  };

  @override
  Widget build(BuildContext context) {
    final topPadding =
        contentPadding.resolve(Directionality.of(context)).top;
    final bottomPadding =
        MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight;

    return Padding(
      padding: EdgeInsets.only(top: topPadding + 8, bottom: bottomPadding),
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.4,
        ),
        itemCount: _partitions.length,
        itemBuilder: (context, index) {
          final entry = _partitions.entries.elementAt(index);
          return _buildPartitionCard(context, entry.key, entry.value);
        },
      ),
    );
  }

  Widget _buildPartitionCard(
      BuildContext context, String displayName, String apiName) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PartitionPostsPage(
                  title: displayName,
                  partition: apiName,
                ),
              ),
            );
          },
          child: Center(
            child: Text(
              displayName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 指定分区的帖子列表页
class PartitionPostsPage extends StatefulWidget {
  const PartitionPostsPage({
    super.key,
    required this.title,
    required this.partition,
  });

  final String title;
  final String partition;

  @override
  State<PartitionPostsPage> createState() => _PartitionPostsPageState();
}

class _PartitionPostsPageState extends State<PartitionPostsPage> {
  final PostService _postService = PostService();
  static const int _pageSize = 15;

  List<PostModel> _posts = [];
  bool _isLoading = false;
  bool _isInitialLoading = true;
  bool _hasMore = true;
  bool _hasFormatError = false; // 响应结构不兼容，显示「内容升级中」
  int _offset = 0;
  UserModel _user = UserModel.empty();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadUser();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadPosts(refresh: false);
      }
    }
  }

  Future<void> _loadUser() async {
    final user = StorageService().user ?? UserModel.empty();
    if (!mounted) return;
    setState(() {
      _user = user;
    });
    _loadPosts(refresh: true);
  }

  Future<void> _loadPosts({required bool refresh}) async {
    if (_isLoading) return;
    if (_user.phone.isEmpty) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _offset = 0;
        _posts = [];
      }
    });

    try {
      final result = await _postService.getPosts(
        GetPostsParams(
          limit: _pageSize,
          offset: _offset,
          partition: widget.partition,
          searchsort: 'home',
          searchinfo: '',
          userTelephone: _user.phone,
          tag: '',
        ),
      );

      if (!mounted) return;

      setState(() {
        if (refresh) {
          // 首页/刷新：置顶帖插顶部；续载只追加一般帖，不重复插入置顶
          _posts = [...result.pinned, ...result.posts];
        } else {
          _posts.addAll(result.posts);
        }
        // offset 只按一般帖推进，不被置顶帖污染
        _offset += result.posts.length;
        _hasMore = result.posts.length >= _pageSize;
        _isLoading = false;
        _isInitialLoading = false;
        _hasFormatError = false;
      });
    } on ApiResponseFormatError {
      // 响应结构不兼容：显示「内容升级中」
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialLoading = false;
          _hasFormatError = true;
        });
      }
    } catch (e) {
      debugPrint('加载分区帖子失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: context.surfaceColor,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // 初始加载或正在加载且列表为空时显示骨架屏
    if (_isInitialLoading || (_isLoading && _posts.isEmpty)) {
      return const PostListSkeleton(itemCount: 5, isDense: false);
    }

    if (_posts.isEmpty && !_isLoading) {
      // 响应结构不兼容时显示「内容升级中」
      if (_hasFormatError) {
        return const ContentUpgradingPlaceholder();
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: context.textTertiaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              '该分区暂无帖子',
              style: TextStyle(
                fontSize: 14,
                color: context.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadPosts(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 8),
        itemCount: _posts.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _posts.length) {
            return const LoadingRow();
          }
          final post = _posts[index];
          return PostCard(
            post: post,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PostDetailPage(
                    postId: post.id,
                    initialPost: post, // 传递初始数据
                  ),
                ),
              );
              _loadPosts(refresh: true);
            },
            onLikeTap: () async {
              return _postService.likePost(post.id, _user.phone);
            },
          );
        },
      ),
    );
  }
}
