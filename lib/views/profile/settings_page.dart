import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sse_market_x/core/api/api_service.dart';
import 'package:sse_market_x/core/services/media_cache_service.dart';
import 'package:sse_market_x/core/services/storage_service.dart';
import 'package:sse_market_x/core/services/watch_later_service.dart';
import 'package:sse_market_x/core/services/blur_effect_service.dart';
import 'package:sse_market_x/core/services/desktop_layout_preference_service.dart';
import 'package:sse_market_x/core/services/new_posts_service.dart';
import 'package:sse_market_x/core/services/notification_service.dart';
import 'package:sse_market_x/core/skins/skin_models.dart';
import 'package:sse_market_x/core/skins/skin_service.dart';
import 'package:sse_market_x/shared/components/lists/settings_list_item.dart';
import 'package:sse_market_x/shared/components/overlays/custom_dialog.dart';
import 'package:sse_market_x/shared/components/utils/snackbar_helper.dart';
import 'package:sse_market_x/shared/theme/app_colors.dart';
import 'package:sse_market_x/views/auth/login_page.dart';
import 'package:sse_market_x/views/auth/reset_password_page.dart';
import 'package:sse_market_x/views/profile/about_page.dart';
import 'package:sse_market_x/views/profile/cache_management_page.dart';
import 'package:sse_market_x/shared/components/layout/layout_config.dart';

class SettingsPage extends StatefulWidget {
  final ApiService apiService;
  final String? userEmail;

  const SettingsPage({
    super.key,
    required this.apiService,
    this.userEmail,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isNotificationEnabled = true;
  bool _systemNotificationsEnabled = false;
  bool _isEmailNotificationEnabled = false;
  // bool _isAutoPlay = true; // TODO: 自动播放功能待实现
  bool _isWatchLaterEnabled = false;
  bool _isBlurEffectEnabled = true;

  final MediaCacheService _cacheService = MediaCacheService();
  final WatchLaterService _watchLaterService = WatchLaterService();
  final BlurEffectService _blurEffectService = BlurEffectService();
  String _cacheSize = '计算中...';
  bool _isLoadingCacheInfo = true;

  @override
  void initState() {
    super.initState();
    // Web 端不需要加载缓存信息
    if (!kIsWeb) {
      _loadCacheInfo();
    }
    _loadEmailPushStatus();
    _loadWatchLaterStatus();
    _loadBlurEffectStatus();
    _loadNotificationStatus();
    _loadNotificationPermission();
  }

  void _loadNotificationStatus() {
    setState(() {
      _isNotificationEnabled = NewPostsService().isEnabled;
    });
  }

  Future<void> _loadNotificationPermission() async {
    final enabled = await NotificationService().areNotificationsEnabled();
    if (mounted) {
      setState(() => _systemNotificationsEnabled = enabled);
    }
  }

  Future<void> _sendTestNotification() async {
    final service = NotificationService();
    var enabled = await service.areNotificationsEnabled();
    if (!enabled) {
      enabled = await service.requestPermission();
    }
    if (!enabled) {
      if (mounted) {
        SnackBarHelper.show(context, '系统通知权限未开启，请到系统设置中允许通知');
        await service.openSystemSettings();
      }
      return;
    }
    final ok = await service.showTestNotification();
    if (!mounted) return;
    await _loadNotificationPermission();
    SnackBarHelper.show(
      context,
      ok ? '已发送测试通知，请查看通知栏' : '发送失败，请检查系统通知权限',
    );
  }

  Future<void> _toggleNotification(bool value) async {
    final service = NewPostsService();
    final ok = await service.setEnabled(value);
    if (!mounted) return;
    setState(() {
      _isNotificationEnabled = service.isEnabled;
    });
    await _loadNotificationPermission();
    if (!mounted) return;
    if (value && !ok) {
      SnackBarHelper.show(context, '未获得通知权限，请在系统设置中允许通知');
    } else {
      SnackBarHelper.show(
        context,
        value ? '已开启新帖通知' : '已关闭新帖通知',
      );
    }
  }

  Future<void> _loadWatchLaterStatus() async {
    final enabled = await _watchLaterService.isEnabled();
    if (mounted) {
      setState(() {
        _isWatchLaterEnabled = enabled;
      });
    }
  }

  void _loadBlurEffectStatus() {
    setState(() {
      _isBlurEffectEnabled = _blurEffectService.isEnabled;
    });
  }

  Future<void> _loadCacheInfo() async {
    setState(() {
      _isLoadingCacheInfo = true;
    });

    try {
      final size = await _cacheService.getCacheSize();

      if (mounted) {
        setState(() {
          _cacheSize = _cacheService.formatCacheSize(size);
          _isLoadingCacheInfo = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cacheSize = '获取失败';
          _isLoadingCacheInfo = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final layoutConfig = LayoutConfig.of(context);
    final isThreeColumn = layoutConfig?.isThreeColumn ?? false;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '设置',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.textPrimaryColor,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('通知设置'),
            SettingsListGroup(
              children: [
                SettingsListItem(
                  title: '新帖通知',
                  subtitle: '有新帖子时发送系统通知，App 内也会显示横幅',
                  leadingIcon: 'assets/icons/ic_notifications.svg',
                  type: SettingsListItemType.toggle,
                  switchValue: _isNotificationEnabled,
                  onSwitchChanged: _toggleNotification,
                  isFirst: true,
                ),
                SettingsListItem(
                  title: '发送测试通知',
                  subtitle: _systemNotificationsEnabled
                      ? '系统通知已开启，点此发送一条测试通知'
                      : '系统通知未开启，点此申请权限或去系统设置',
                  leadingIcon: 'assets/icons/ic_notifications.svg',
                  type: SettingsListItemType.navigation,
                  onTap: _sendTestNotification,
                ),
                SettingsListItem(
                  title: '邮箱通知',
                  subtitle: '接收回复、私信等的邮箱通知',
                  leadingIcon: 'assets/icons/ic_email.svg',
                  type: SettingsListItemType.toggle,
                  switchValue: _isEmailNotificationEnabled,
                  onSwitchChanged: (val) {
                    _toggleEmailNotification(val);
                  },
                  isLast: true,
                ),
              ],
            ),
            _buildSectionTitle('外观与皮肤'),
            _buildSkinSection(),
            // TODO: 自动播放功能待实现
            // _buildSectionTitle('媒体设置'),
            // SettingsListGroup(
            //   children: [
            //     SettingsListItem(
            //       title: '自动播放',
            //       subtitle: '自动播放视频和音频',
            //       leadingIcon: 'assets/icons/ic_play.svg',
            //       type: SettingsListItemType.toggle,
            //       switchValue: _isAutoPlay,
            //       onSwitchChanged: (val) {
            //         setState(() {
            //           _isAutoPlay = val;
            //         });
            //       },
            //       isFirst: true,
            //       isLast: true,
            //     ),
            //   ],
            // ),
            // Web 端不显示存储设置
            if (!kIsWeb) ...[
              _buildSectionTitle('存储设置'),
              SettingsListGroup(
                children: [
                  SettingsListItem(
                    title: '缓存管理',
                    subtitle: '查看和清理图片、视频等媒体缓存',
                    leadingIcon: 'assets/icons/ic_storage.svg',
                    type: SettingsListItemType.custom,
                    onTap: _openCacheManagement,
                    trailing: _buildCacheTrailing(),
                    isFirst: true,
                    isLast: true,
                  ),
                ],
              ),
            ],
            _buildSectionTitle('账户设置'),
            SettingsListGroup(
              children: [
                SettingsListItem(
                  title: '重置密码',
                  subtitle: '修改登录密码',
                  leadingIcon: 'assets/icons/ic_lock.svg',
                  type: SettingsListItemType.navigation,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ResetPasswordPage(
                          apiService: widget.apiService,
                          initialEmail: widget.userEmail,
                        ),
                      ),
                    );
                  },
                  isFirst: true,
                  isLast: true,
                ),
              ],
            ),
            _buildSectionTitle('实验性功能'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.surfaceColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: context.dividerColor,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.science_outlined,
                    size: 16,
                    color: context.textTertiaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '这些功能仍在测试中，可能不稳定',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textTertiaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SettingsListGroup(
              children: [
                SettingsListItem(
                  title: '背景模糊',
                  subtitle: '导航栏和顶部栏的毛玻璃效果',
                  leadingIcon: 'assets/icons/ic_blur.svg',
                  type: SettingsListItemType.toggle,
                  switchValue: _isBlurEffectEnabled,
                  onSwitchChanged: (value) async {
                    await _blurEffectService.setEnabled(value);
                    setState(() {
                      _isBlurEffectEnabled = value;
                    });
                    if (mounted) {
                      SnackBarHelper.show(
                        context,
                        value ? '已启用模糊效果' : '已关闭模糊效果',
                      );
                    }
                  },
                  isFirst: true,
                ),
                SettingsListItem(
                  title: '稍后再看',
                  subtitle: '在帖子详情页标记稍后查看的内容',
                  leadingIcon: 'assets/icons/ic_watch_later.svg',
                  type: SettingsListItemType.toggle,
                  switchValue: _isWatchLaterEnabled,
                  onSwitchChanged: (value) async {
                    await _watchLaterService.setEnabled(value);
                    setState(() {
                      _isWatchLaterEnabled = value;
                    });
                    if (mounted) {
                      SnackBarHelper.show(
                        context,
                        value ? '已启用稍后再看功能' : '已关闭稍后再看功能',
                      );
                    }
                  },
                  isLast: true,
                ),
              ],
            ),
            _buildSectionTitle('其他'),
            SettingsListGroup(
              children: [
                SettingsListItem(
                  title: '关于本应用',
                  leadingIcon: 'assets/icons/ic_info.svg',
                  type: SettingsListItemType.navigation,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AboutPage(),
                      ),
                    );
                  },
                  isFirst: true,
                ),
                if (isThreeColumn)
                  SettingsListItem(
                    title: '重置多栏布局宽度',
                    subtitle: '恢复侧栏和中间栏的默认宽度',
                    leadingIcon: 'assets/icons/ic_layout_reset.svg',
                    type: SettingsListItemType.navigation,
                    onTap: _resetDesktopLayoutWidths,
                  ),
                SettingsListItem(
                  title: '退出登录',
                  leadingIcon: 'assets/icons/ic_logout.svg',
                  leadingIconColor: AppColors.error,
                  titleColor: AppColors.error,
                  type: SettingsListItemType.navigation,
                  onTap: _handleLogout,
                  isLast: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetDesktopLayoutWidths() async {
    await DesktopLayoutPreferenceService().reset();
    if (mounted) {
      SnackBarHelper.show(context, '已恢复默认多栏宽度');
    }
  }

  Widget _buildSkinSection() {
    final skin = SkinService();
    return AnimatedBuilder(
      animation: skin,
      builder: (context, _) {
        final prefs = skin.prefs;
        final active = skin.activeSkin;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '当前皮肤：${active?.name ?? '默认'}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryColor,
                      ),
                    ),
                  ),
                  if (skin.loading)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    ),
                ],
              ),
              if (active != null) ...[
                const SizedBox(height: 2),
                Text(
                  active.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textTertiaryColor,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _skinModeChip(
                    label: '自动（跟随活动）',
                    mode: 'auto',
                    selected: prefs.themeMode == 'auto',
                    onSelected: () => _updateSkinPrefs(
                      prefs.copyWith(themeMode: 'auto'),
                    ),
                  ),
                  _skinModeChip(
                    label: '默认',
                    mode: 'default',
                    selected: prefs.themeMode == 'default',
                    onSelected: () => _updateSkinPrefs(
                      prefs.copyWith(themeMode: 'default'),
                    ),
                  ),
                  for (final s in skinList)
                    _skinModeChip(
                      label: s.name,
                      mode: s.id,
                      selected: prefs.themeMode == s.id,
                      onSelected: () => _updateSkinPrefs(
                        prefs.copyWith(themeMode: s.id),
                      ),
                    ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  '开场画面',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textPrimaryColor,
                  ),
                ),
                subtitle: Text(
                  '进入 App 时展示一次当前皮肤的开场图',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textTertiaryColor,
                  ),
                ),
                value: prefs.splashEnabled,
                onChanged: (v) => _updateSkinPrefs(
                  prefs.copyWith(splashEnabled: v),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  '皮肤背景',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textPrimaryColor,
                  ),
                ),
                subtitle: Text(
                  '关闭后页面使用默认纯色背景',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textTertiaryColor,
                  ),
                ),
                value: prefs.backgroundEnabled,
                onChanged: (v) => _updateSkinPrefs(
                  prefs.copyWith(backgroundEnabled: v),
                ),
              ),
              if (prefs.backgroundEnabled) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '背景来源',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('皮肤内置', style: TextStyle(fontSize: 11)),
                      selected: prefs.backgroundSource == 'default',
                      onSelected: (_) => _updateSkinPrefs(
                        prefs.copyWith(backgroundSource: 'default'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label:
                          const Text('自定义图片', style: TextStyle(fontSize: 11)),
                      selected: prefs.backgroundSource == 'custom',
                      onSelected: (_) async {
                        if (prefs.backgroundSource != 'custom') {
                          await _updateSkinPrefs(
                            prefs.copyWith(backgroundSource: 'custom'),
                          );
                        }
                        if (!mounted) return;
                        await _editCustomBackground();
                      },
                    ),
                  ],
                ),
                if (prefs.backgroundSource == 'custom')
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      prefs.customBackgroundUrl.isEmpty
                          ? '尚未设置图片地址'
                          : prefs.customBackgroundUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: context.textTertiaryColor,
                      ),
                    ),
                  ),
              ],
              if (active != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: skin.previewSplash,
                    child: const Text('预览开场画面'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _skinModeChip({
    required String label,
    required String mode,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }

  Future<void> _updateSkinPrefs(ThemeSettings next) async {
    final result = await SkinService().updatePrefs(next);
    if (!result.ok && mounted) {
      SnackBarHelper.show(context, result.msg);
    }
  }

  Future<void> _editCustomBackground() async {
    final controller = TextEditingController(
      text: SkinService().prefs.customBackgroundUrl,
    );
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('自定义背景图片'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            hintText: 'https://example.com/background.jpg',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    if (result.isNotEmpty &&
        !result.startsWith('https://') &&
        !result.startsWith('http://')) {
      SnackBarHelper.show(context, '背景图片必须是 http(s) 地址');
      return;
    }
    await _updateSkinPrefs(
      SkinService().prefs.copyWith(customBackgroundUrl: result),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          color: context.textSecondaryColor,
        ),
      ),
    );
  }

  /// 构建缓存尾部组件
  Widget _buildCacheTrailing() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isLoadingCacheInfo)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.textSecondaryColor,
            ),
          )
        else
          Text(
            _cacheSize,
            style: TextStyle(
              fontSize: 14,
              color: context.textSecondaryColor,
            ),
          ),
      ],
    );
  }

  /// 打开缓存管理页面
  Future<void> _openCacheManagement() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CacheManagementPage(),
      ),
    );
    // 返回后刷新缓存信息
    _loadCacheInfo();
  }

  /// 加载邮箱推送状态
  Future<void> _loadEmailPushStatus() async {
    try {
      final userInfo = await widget.apiService.getUserInfo();
      final detailedInfo =
          await widget.apiService.getDetailedUserInfo(userInfo.phone);

      if (mounted) {
        setState(() {
          _isEmailNotificationEnabled = detailedInfo.emailPush;
        });
      }
    } catch (e) {
      // 加载失败，保持默认值
    }
  }

  /// 切换邮箱通知
  Future<void> _toggleEmailNotification(bool value) async {
    try {
      final userInfo = await widget.apiService.getUserInfo();

      if (userInfo.userId == 0) {
        if (mounted) {
          SnackBarHelper.show(context, '用户信息获取失败');
        }
        return;
      }

      final success = await widget.apiService.updateEmailPush(userInfo.userId);

      if (mounted) {
        if (success) {
          setState(() {
            _isEmailNotificationEnabled = value;
          });

          SnackBarHelper.show(
            context,
            value ? '邮箱通知已开启' : '邮箱通知已关闭',
          );
        } else {
          SnackBarHelper.show(
            context,
            '操作失败，请稍后重试',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.show(
          context,
          '操作失败，请稍后重试',
        );
      }
    }
  }

  /// 处理退出登录
  Future<void> _handleLogout() async {
    final confirm = await showCustomDialog(
      context: context,
      title: '退出登录',
      content: '确定要退出登录吗？',
      cancelText: '取消',
      confirmText: '确定',
      confirmColor: AppColors.error,
    );

    if (confirm == true) {
      // 清除持久化登录数据
      await StorageService().logout();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }
}
