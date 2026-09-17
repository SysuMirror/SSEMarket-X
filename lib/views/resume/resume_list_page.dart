import 'package:flutter/material.dart';

import 'package:sse_market_x/core/api/resume_service.dart';
import 'package:sse_market_x/core/models/resume_model.dart';
import 'package:sse_market_x/shared/components/loading/skeleton_loader.dart';
import 'package:sse_market_x/shared/theme/app_colors.dart';
import 'package:sse_market_x/views/resume/resume_detail_page.dart';
import 'package:sse_market_x/views/resume/resume_upload_page.dart';

/// 简历专区列表页（对应官网 /resume）
///
/// 双 Tab「全部简历」(home)/「我的简历」(my)，切换即重查；
/// AutomaticKeepAlive 快取各自结果，重查期间已有数据保持展示。
/// 搜索框位于 TabBar 下方，搜索作用于当前 Tab；一次取回 200 笔，无分页。
class ResumeListPage extends StatefulWidget {
  const ResumeListPage({super.key});

  @override
  State<ResumeListPage> createState() => _ResumeListPageState();
}

class _ResumeListPageState extends State<ResumeListPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<_ResumeListTabState> _homeTabKey =
      GlobalKey<_ResumeListTabState>();
  final GlobalKey<_ResumeListTabState> _myTabKey =
      GlobalKey<_ResumeListTabState>();

  /// 当前生效的搜索词（点搜索才生效，输入中不触发）
  String _searchInfo = '';

  /// 上次已加载的 Tab 下标，用于去重：同一下标不重复发起
  int _loadedIndex = 0;

  GlobalKey<_ResumeListTabState> get _currentTabKey =>
      _tabController.index == 1 ? _myTabKey : _homeTabKey;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reloadCurrentTab();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// 切换 Tab = 重查新 Tab（动画完成时触发；下标未变不重复查）
  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == _loadedIndex) return;
    _reloadCurrentTab();
  }

  void _reloadCurrentTab() {
    _loadedIndex = _tabController.index;
    _currentTabKey.currentState?.reload(searchinfo: _searchInfo);
  }

  void _onSearch() {
    _searchInfo = _searchController.text.trim();
    FocusScope.of(context).unfocus();
    _reloadCurrentTab();
  }

  Future<void> _onUpload() async {
    final uploaded = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ResumeUploadPage()),
    );
    if (mounted && uploaded == true) _reloadCurrentTab();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('简历专区'),
        backgroundColor: context.surfaceColor,
        actions: [
          TextButton.icon(
            onPressed: _onUpload,
            icon: const Icon(Icons.upload_file, size: 18),
            label: const Text('上传简历'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: context.textSecondaryColor,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: '全部简历'),
            Tab(text: '我的简历'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(context),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ResumeListTab(key: _homeTabKey, searchsort: 'home'),
                _ResumeListTab(key: _myTabKey, searchsort: 'my'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _onSearch(),
              style: TextStyle(
                fontSize: 14,
                color: context.textPrimaryColor,
              ),
              decoration: InputDecoration(
                hintText: '搜索标题、简介或文件名',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: context.textTertiaryColor,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 20,
                  color: context.textTertiaryColor,
                ),
                isDense: true,
                filled: true,
                fillColor: context.surfaceColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
                border: border,
                enabledBorder: border,
                focusedBorder: border,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _onSearch,
            child: const Text('搜索'),
          ),
        ],
      ),
    );
  }
}

/// 单个 Tab 的简历清单（三态 + KeepAlive）
class _ResumeListTab extends StatefulWidget {
  const _ResumeListTab({super.key, required this.searchsort});

  /// "home"=全部简历 / "my"=我的简历
  final String searchsort;

  @override
  State<_ResumeListTab> createState() => _ResumeListTabState();
}

class _ResumeListTabState extends State<_ResumeListTab>
    with AutomaticKeepAliveClientMixin {
  final ResumeService _resumeService = ResumeService();

  List<ResumeModel> _resumes = const [];
  bool _isLoading = false;
  bool _hasError = false;

  /// 最近一次使用的搜索词，供重试/详情返回/上传返回时复用
  String _lastSearchinfo = '';

  /// 请求序号：慢响应回来时若已有更新请求则丢弃
  int _requestSeq = 0;

  @override
  bool get wantKeepAlive => true;

  Future<void> reload({String searchinfo = ''}) async {
    _lastSearchinfo = searchinfo;
    final seq = ++_requestSeq;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    final result = await _resumeService.getResumeList(
      searchsort: widget.searchsort,
      searchinfo: searchinfo,
    );
    if (!mounted || seq != _requestSeq) return;
    setState(() {
      _isLoading = false;
      if (result != null) {
        _resumes = result;
      } else if (_resumes.isEmpty) {
        // 失败且无缓存 → 错误态；有缓存则保留旧数据
        _hasError = true;
      }
    });
  }

  Future<void> _openDetail(ResumeModel resume) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ResumeDetailPage(resumeId: resume.resumeId),
      ),
    );
    // 详情内浏览/下载/编辑/删除都会改变列表数据，返回即刷新
    if (mounted) reload(searchinfo: _lastSearchinfo);
  }

  Future<void> _goUpload() async {
    final uploaded = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ResumeUploadPage()),
    );
    if (mounted && uploaded == true) reload(searchinfo: _lastSearchinfo);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_resumes.isEmpty) {
      if (_isLoading) return const PostListSkeleton(itemCount: 4);
      if (_hasError) {
        return _ResumeListErrorView(
          onRetry: () => reload(searchinfo: _lastSearchinfo),
        );
      }
      return _ResumeListEmptyView(
        isMine: widget.searchsort == 'my',
        onUpload: _goUpload,
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      itemCount: _resumes.length,
      itemBuilder: (context, index) {
        final resume = _resumes[index];
        return _ResumeCard(
          resume: resume,
          onTap: () => _openDetail(resume),
        );
      },
    );
  }
}

/// 简历卡片：类型图标 + 标题/匿名标 + 简介 + 元信息 + 页脚
class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.resume, required this.onTap});

  final ResumeModel resume;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final extLabel = resume.normalizedFileExt.isNotEmpty
        ? resume.normalizedFileExt.toUpperCase()
        : '文件';
    final uploader = resume.uploader.isNotEmpty ? resume.uploader : '匿名用户';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildExtIcon(context),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              resume.title.isNotEmpty ? resume.title : '未命名简历',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: context.textPrimaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (resume.isAnonymous) ...[
                            const SizedBox(width: 8),
                            _buildAnonymousTag(context),
                          ],
                        ],
                      ),
                      if (resume.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          resume.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textSecondaryColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        '$uploader · ${resume.formattedFileSize}'
                        ' · ${resume.viewNum} 次浏览 · ${resume.downloadNum} 次下载',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textTertiaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Divider(height: 1, color: context.dividerColor),
                      const SizedBox(height: 8),
                      Text(
                        '$extLabel · ${resume.createdAt}',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textTertiaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 副檔名四类图标（pdf/word/图片/其他），底色为对应主色淡化
  Widget _buildExtIcon(BuildContext context) {
    final IconData icon;
    final Color color;
    switch (resume.category) {
      case ResumeFileCategory.pdf:
        icon = Icons.picture_as_pdf;
        color = AppColors.error;
      case ResumeFileCategory.word:
        icon = Icons.description;
        color = AppColors.primary;
      case ResumeFileCategory.image:
        icon = Icons.image;
        color = AppColors.secondary;
      case ResumeFileCategory.other:
        icon = Icons.insert_drive_file;
        color = context.textTertiaryColor;
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 22, color: color),
    );
  }

  Widget _buildAnonymousTag(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: context.textTertiaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '匿名',
        style: TextStyle(
          fontSize: 11,
          color: context.textSecondaryColor,
        ),
      ),
    );
  }
}

/// 空状态：我的/全部 文案不同，附上传入口
class _ResumeListEmptyView extends StatelessWidget {
  const _ResumeListEmptyView({required this.isMine, required this.onUpload});

  final bool isMine;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.description_outlined,
            size: 48,
            color: context.textTertiaryColor,
          ),
          const SizedBox(height: 12),
          Text(
            isMine ? '你还没有上传简历' : '暂无简历，快来上传第一份吧',
            style: TextStyle(
              fontSize: 15,
              color: context.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onUpload,
            icon: const Icon(Icons.upload_file, size: 18),
            label: const Text('上传简历'),
          ),
        ],
      ),
    );
  }
}

/// 错误状态（可重试）
class _ResumeListErrorView extends StatelessWidget {
  const _ResumeListErrorView({required this.onRetry});

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
            '获取简历列表失败',
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
