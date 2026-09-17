import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:sse_market_x/core/api/workbench_service.dart';
import 'package:sse_market_x/shared/components/feedback/content_upgrading_placeholder.dart';
import 'package:sse_market_x/shared/components/utils/snackbar_helper.dart';
import 'package:sse_market_x/shared/theme/app_colors.dart';
import 'package:sse_market_x/views/home/partition_page.dart';
import 'package:sse_market_x/views/ranking/ranking_page.dart';
import 'package:sse_market_x/views/resume/resume_list_page.dart';
import 'package:sse_market_x/views/shop/shop_page.dart';
import 'package:sse_market_x/views/todo/score_page.dart';

/// 入口动作类型
enum _EntryKind {
  ranking,
  score,
  resume,
  shop,
  externalLink,
  partition,
  placeholder,
}

/// 工作台入口项
class _WorkbenchEntry {
  const _WorkbenchEntry(this.name, this.icon, this.kind, [this.target = '']);

  final String name;
  final IconData icon;
  final _EntryKind kind;

  /// externalLink 的目标 URL
  final String target;
}

/// 工作台页（移动端底栏 tab 5）
///
/// 官网对齐：常用区 8 个内建项 + 后端动态下发的 apps（匿名接口，加载失败
/// 静默跳过）追加在常用区之后；「全部分区」10 项进入对应分区的帖子列表。
/// 小秋/课程专区为占位页，分别待 B6/B4 接入（简历已接入 Batch 6 (A)）。
class WorkbenchPage extends StatefulWidget {
  const WorkbenchPage({super.key});

  @override
  State<WorkbenchPage> createState() => _WorkbenchPageState();
}

class _WorkbenchPageState extends State<WorkbenchPage> {
  final WorkbenchService _workbenchService = WorkbenchService();

  /// 常用区 8 个内建项（顺序对齐官网 /workbench）
  static const List<_WorkbenchEntry> _frequentEntries = [
    _WorkbenchEntry('排行榜', Icons.leaderboard, _EntryKind.ranking),
    _WorkbenchEntry('小秋', Icons.smart_toy, _EntryKind.placeholder),
    _WorkbenchEntry('打分', Icons.grade, _EntryKind.score),
    _WorkbenchEntry('简历', Icons.description, _EntryKind.resume),
    _WorkbenchEntry('商城', Icons.storefront, _EntryKind.shop),
    _WorkbenchEntry(
      'iWiki',
      Icons.auto_stories,
      _EntryKind.externalLink,
      'https://ssemarket.cn/iwiki/',
    ),
    _WorkbenchEntry('课程专区', Icons.menu_book, _EntryKind.placeholder),
    _WorkbenchEntry(
      '学人汇',
      Icons.hub,
      _EntryKind.externalLink,
      'https://scholarhub.top/',
    ),
  ];

  /// 全部分区入口（分区名即 API partition 精确字符串）
  static const List<_WorkbenchEntry> _partitionEntries = [
    _WorkbenchEntry('学习交流', Icons.school, _EntryKind.partition),
    _WorkbenchEntry('生活日常', Icons.wb_sunny, _EntryKind.partition),
    _WorkbenchEntry('社团活动', Icons.groups, _EntryKind.partition),
    _WorkbenchEntry('实习就业', Icons.work_outline, _EntryKind.partition),
    _WorkbenchEntry('期末资料', Icons.library_books, _EntryKind.partition),
    _WorkbenchEntry('宿舍生活', Icons.apartment, _EntryKind.partition),
    _WorkbenchEntry('技术分享', Icons.code, _EntryKind.partition),
    _WorkbenchEntry('课程专区', Icons.menu_book, _EntryKind.partition),
    _WorkbenchEntry('组团捞人', Icons.group_add, _EntryKind.partition),
    _WorkbenchEntry('其他', Icons.apps, _EntryKind.partition),
  ];

  /// 动态 apps 转换后的入口（加载失败保持空，内建清单照常可用）
  List<_WorkbenchEntry> _dynamicEntries = const [];

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    final apps = await _workbenchService.getWorkbenchApps();
    if (!mounted) return;

    final builtInNames = _frequentEntries.map((e) => e.name).toSet();
    final entries = <_WorkbenchEntry>[];
    for (final app in apps) {
      if (!app.isVisible || app.name.isEmpty) continue;
      if (builtInNames.contains(app.name)) continue;
      if (app.colorBg.isNotEmpty || app.colorFg.isNotEmpty) {
        debugPrint(
          'workbench app 自定义色: ${app.name} '
          'colorBg=${app.colorBg} colorFg=${app.colorFg}',
        );
      }
      switch (app.targetType) {
        case 'link':
          if (app.target.isEmpty) continue;
          entries.add(
            _WorkbenchEntry(
              app.name,
              Icons.apps,
              _EntryKind.externalLink,
              app.target,
            ),
          );
        case 'route':
          // 官网内部路由，App 端暂以占位页承接（route 值见 debugPrint）
          debugPrint('workbench route 型 app: ${app.name} -> ${app.target}');
          entries.add(
            _WorkbenchEntry(app.name, Icons.apps, _EntryKind.placeholder),
          );
        default:
          debugPrint(
            'workbench 未知 targetType: ${app.name} ${app.targetType}',
          );
      }
    }

    setState(() {
      _dynamicEntries = entries;
    });
  }

  void _onEntryTap(BuildContext context, _WorkbenchEntry entry) {
    switch (entry.kind) {
      case _EntryKind.ranking:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RankingPage()),
        );
      case _EntryKind.score:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ScorePage()),
        );
      case _EntryKind.resume:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ResumeListPage()),
        );
      case _EntryKind.shop:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ShopPage(standalone: true)),
        );
      case _EntryKind.partition:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PartitionPostsPage(
              title: entry.name,
              partition: entry.name,
            ),
          ),
        );
      case _EntryKind.placeholder:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _WorkbenchPlaceholderPage(title: entry.name),
          ),
        );
      case _EntryKind.externalLink:
        _launchExternal(entry.target);
    }
  }

  Future<void> _launchExternal(String url) async {
    final uri = Uri.parse(url);
    // 不以 canLaunchUrl 预检作唯一闸门(部分定制 ROM 会误报),
    // 直接尝试外部浏览器,失败再退回平台默认,仍失败才提示
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(uri);
      } catch (_) {
        if (mounted) {
          SnackBarHelper.show(context, '无法打开链接');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding =
        MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight;
    final frequent = [..._frequentEntries, ..._dynamicEntries];

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding:
              EdgeInsets.fromLTRB(16, 12, 16, bottomPadding + kFloatingActionButtonMargin + 24),
          children: [
            Text(
              '工作台',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionLabel(context, '常用'),
            const SizedBox(height: 12),
            _buildEntryGrid(context, frequent),
            const SizedBox(height: 24),
            _buildSectionLabel(context, '全部分区'),
            const SizedBox(height: 12),
            _buildEntryGrid(context, _partitionEntries),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: context.textPrimaryColor,
      ),
    );
  }

  /// 入口卡片格（视觉参考 PartitionPage：surfaceColor 卡片 + 12 圆角）
  Widget _buildEntryGrid(BuildContext context, List<_WorkbenchEntry> entries) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 12,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        return _buildEntryCard(context, entries[index]);
      },
    );
  }

  Widget _buildEntryCard(BuildContext context, _WorkbenchEntry entry) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _onEntryTap(context, entry),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(entry.icon, size: 28, color: AppColors.primary),
                const SizedBox(height: 8),
                Text(
                  entry.name,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textPrimaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 工作台占位页：复用 ContentUpgradingPlaceholder，显示入口名称 + 即将上线语义
class _WorkbenchPlaceholderPage extends StatelessWidget {
  const _WorkbenchPlaceholderPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: context.surfaceColor,
      ),
      body: const ContentUpgradingPlaceholder(),
    );
  }
}
