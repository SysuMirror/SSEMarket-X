import 'package:flutter/material.dart';

import 'package:sse_market_x/core/miniprogram/mini_program_runtime.dart';
import 'package:sse_market_x/core/miniprogram/mp_platform_api.dart';
import 'package:sse_market_x/core/services/mini_program_catalog.dart';
import 'package:sse_market_x/core/services/mini_program_history_service.dart';
import 'package:sse_market_x/shared/components/icons/mini_program_icon.dart';
import 'package:sse_market_x/shared/theme/app_colors.dart';

/// 微信式小程序面板：最近使用 / 我的小程序 / 全部小程序 / 搜索。
///
/// 目录与偏好以小程序开放平台为准；平台不可用时展示兜底目录并给出错误提示。
Future<void> showMiniProgramDrawer(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '小程序',
    barrierColor: Colors.black.withOpacity(0.45),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (dialogContext, _, __) => Align(
      alignment: Alignment.topCenter,
      child: Container(
        height: MediaQuery.sizeOf(dialogContext).height * 0.72,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(dialogContext).colorScheme.surface,
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(22)),
        ),
        clipBehavior: Clip.antiAlias,
        child: const MiniProgramPanel(),
      ),
    ),
    transitionBuilder: (dialogContext, animation, _, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}

class MiniProgramPanel extends StatefulWidget {
  /// 下拉面板模式下由宿主折叠；为空时退回 Navigator.pop。
  final VoidCallback? onClose;

  const MiniProgramPanel({super.key, this.onClose});

  @override
  State<MiniProgramPanel> createState() => _MiniProgramPanelState();
}

class _MiniProgramPanelState extends State<MiniProgramPanel> {
  final MPPlatformApi _api = MPPlatformApi();

  List<MPApp> _apps = const <MPApp>[];
  List<String> _recentKeys = const <String>[];
  List<String> _favoriteKeys = const <String>[];
  bool _loading = true;
  String? _platformError;

  @override
  void initState() {
    super.initState();
    // 不等目录接口：先用已知的六个官方 appKey 预热票据，
    // 这样面板刚出现、目录还在加载时点击也不会卡在申请票据上。
    MiniProgramRuntime().prefetchTickets(MPFallbackApps.apps);
    _load();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _platformError = null;
    });

    // 本地缓存先上屏。
    final localHistory = MiniProgramHistoryService();
    _recentKeys = localHistory.recentKeys;
    _favoriteKeys = localHistory.favoriteKeys;

    try {
      final results = await Future.wait([
        _api.catalog(),
        _api.prefs(),
      ]);
      if (!mounted) return;
      final apps = results[0] as List<MPApp>;
      final prefs = results[1] as MPPrefs;
      setState(() {
        _apps = apps.isEmpty ? MPFallbackApps.apps : apps;
        _recentKeys = prefs.recent.isEmpty ? _recentKeys : prefs.recent;
        _favoriteKeys =
            prefs.favorites.isEmpty ? _favoriteKeys : prefs.favorites;
        _loading = false;
      });
      // 面板一出现就预热六个小程序的启动票据，点击时直接开窗口。
      MiniProgramRuntime().prefetchTickets(_apps);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _apps = MPFallbackApps.apps;
        _loading = false;
        _platformError =
            e is MPException ? '${e.message}（${e.code}）' : '小程序平台连接失败';
      });
    }
  }

  MPApp? _find(String key) {
    for (final app in _apps) {
      if (app.appKey == key) return app;
    }
    return MPFallbackApps.byKey(key);
  }

  List<MPApp> get _recentApps =>
      _recentKeys.map(_find).whereType<MPApp>().take(8).toList(growable: false);

  List<MPApp> get _favoriteApps =>
      _favoriteKeys.map(_find).whereType<MPApp>().toList(growable: false);

  void _close() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _open(MPApp app) async {
    _close();
    await MiniProgramRuntime().open(app);
  }

  Future<void> _toggleFavorite(MPApp app) async {
    final next = <String>[..._favoriteKeys];
    if (next.contains(app.appKey)) {
      next.remove(app.appKey);
    } else {
      next.insert(0, app.appKey);
    }
    setState(() => _favoriteKeys = next);
    try {
      await _api.updatePrefs(favorites: next);
    } catch (_) {
      // 平台不可用时至少保留本地状态。
      final local = MiniProgramHistoryService();
      await local.toggleFavorite(app.appKey);
    }
  }

  Future<void> _showEntryMenu(MPApp app) async {
    final isFavorite = _favoriteKeys.contains(app.appKey);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              title: Text(
                app.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimaryColor,
                ),
              ),
              subtitle: Text(
                app.description.isEmpty ? app.appKey : app.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: context.textTertiaryColor,
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                isFavorite
                    ? Icons.remove_circle_outline
                    : Icons.add_circle_outline,
                color: context.textPrimaryColor,
              ),
              title: Text(
                isFavorite ? '从我的小程序移除' : '添加到我的小程序',
                style: TextStyle(color: context.textPrimaryColor),
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _toggleFavorite(app);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.surfaceColor,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildSearchBar(),
            if (_platformError != null) _buildPlatformBanner(),
            Expanded(child: _buildShell()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: context.surfaceColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _openSearchPage,
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded,
                          size: 18, color: context.textTertiaryColor),
                      const SizedBox(width: 6),
                      Text(
                        '搜索小程序',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.textTertiaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: _close,
            child: Text(
              '取消',
              style: TextStyle(fontSize: 14, color: context.textSecondaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSearchPage() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MiniProgramSearchPage(
          apps: _apps.isEmpty ? MPFallbackApps.apps : _apps,
          onOpen: (app) async {
            _close();
            await MiniProgramRuntime().open(app);
          },
        ),
      ),
    );
  }

  Widget _buildPlatformBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4D6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 16, color: Color(0xFFB7791F)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '平台目录暂时不可用：$_platformError',
              style: const TextStyle(fontSize: 11, color: Color(0xFF92400E)),
            ),
          ),
          TextButton(
            onPressed: _load,
            child: const Text('重试', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildShell() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _buildSection(
          title: '最近使用',
          trailing: _loading
              ? const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                )
              : null,
          child: _recentApps.isEmpty
              ? _buildEmptyHint('打开过的小程序会出现在这里')
              : _buildGrid(_recentApps),
        ),
        _buildSection(
          title: '我的小程序',
          child: _favoriteApps.isEmpty
              ? _buildEmptyHint('长按小程序图标可添加到我的小程序')
              : _buildGrid(_favoriteApps),
        ),
        _buildSection(
          title: '全部小程序',
          child: _buildGrid(_apps),
        ),
        _buildSection(
          title: '主站功能',
          child: _buildMainSiteHint(),
        ),
        // 微信式：滑到面板底部后继续上滑，直接回到主页，不必找“取消”。
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragEnd: (details) {
            if ((details.primaryVelocity ?? 0) < -260) _close();
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 18, 0, 30),
            child: Column(
              children: [
                Icon(Icons.keyboard_arrow_up_rounded,
                    size: 18, color: context.textTertiaryColor),
                Text(
                  '上滑返回主页',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: context.textTertiaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainSiteHint() {
    return Text(
      '小秋、发帖、消息、币中心等仍在主站 App 内，不占用小程序进程。',
      style: TextStyle(fontSize: 11.5, color: context.textTertiaryColor),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
      decoration: BoxDecoration(
        color: context.surfaceColor.withOpacity(0.62),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: context.textTertiaryColor,
                ),
              ),
              const SizedBox(width: 8),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyHint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: context.textTertiaryColor),
      ),
    );
  }

  Widget _buildGrid(List<MPApp> apps) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 14,
        crossAxisSpacing: 6,
        childAspectRatio: 0.8,
      ),
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final app = apps[index];
        final palette = MiniProgramCatalog.paletteFor(
          app.appKey,
          dark: context.isDark,
        );
        return _MPCell(
          app: app,
          background: palette.bg,
          foreground: palette.fg,
          onTap: () => _open(app),
          onLongPress: () => _showEntryMenu(app),
        );
      },
    );
  }
}

/// 小程序搜索页（微信式：点面板里的搜索框进入新页面）。
class MiniProgramSearchPage extends StatefulWidget {
  final List<MPApp> apps;
  final Future<void> Function(MPApp app) onOpen;

  const MiniProgramSearchPage({
    super.key,
    required this.apps,
    required this.onOpen,
  });

  @override
  State<MiniProgramSearchPage> createState() => _MiniProgramSearchPageState();
}

class _MiniProgramSearchPageState extends State<MiniProgramSearchPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final text = _controller.text.trim();
      if (text != _query) setState(() => _query = text);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<MPApp> get _results {
    if (_query.isEmpty) return widget.apps;
    final q = _query.toLowerCase();
    return widget.apps
        .where((a) =>
            a.name.toLowerCase().contains(q) ||
            a.appKey.toLowerCase().contains(q) ||
            a.description.toLowerCase().contains(q))
        .toList(growable: false);
  }

  void _open(MPApp app) {
    // 先返回面板，再由面板收起并打开小程序，避免路由栈里残留搜索页。
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onOpen(app));
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, 10, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: context.textPrimaryColor),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded,
                              size: 18, color: context.textTertiaryColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focus,
                              textInputAction: TextInputAction.search,
                              style: TextStyle(
                                fontSize: 14,
                                color: context.textPrimaryColor,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: '搜索小程序',
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  color: context.textTertiaryColor,
                                ),
                              ),
                            ),
                          ),
                          if (_query.isNotEmpty)
                            GestureDetector(
                              onTap: _controller.clear,
                              child: Icon(Icons.cancel_rounded,
                                  size: 16, color: context.textTertiaryColor),
                            ),
                        ],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(
                      '取消',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Text(
                        '没有找到「$_query」相关的小程序',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textTertiaryColor,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                      itemCount: results.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
                            child: Text(
                              _query.isEmpty ? '全部小程序' : '搜索结果',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: context.textTertiaryColor,
                              ),
                            ),
                          );
                        }
                        final app = results[index - 1];
                        final palette = MiniProgramCatalog.paletteFor(
                          app.appKey,
                          dark: context.isDark,
                        );
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: context.surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _open(app),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: palette.bg,
                                        borderRadius: BorderRadius.circular(11),
                                      ),
                                      child: MiniProgramIcon(
                                        name: app.icon,
                                        size: 24,
                                        color: palette.fg,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            app.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: context.textPrimaryColor,
                                            ),
                                          ),
                                          if (app.description.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              app.description,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color:
                                                    context.textTertiaryColor,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded,
                                        size: 18,
                                        color: context.textTertiaryColor),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MPCell extends StatefulWidget {
  final MPApp app;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _MPCell({
    required this.app,
    required this.background,
    required this.foreground,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_MPCell> createState() => _MPCellState();
}

class _MPCellState extends State<_MPCell> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 100),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: widget.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: MiniProgramIcon(
                name: widget.app.icon,
                size: 26,
                color: widget.foreground,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.app.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.2,
                color: context.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
