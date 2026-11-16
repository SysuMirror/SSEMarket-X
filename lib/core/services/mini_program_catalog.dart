import 'package:flutter/material.dart';

import 'package:sse_market_x/core/models/mini_program_app_model.dart';

/// 小程序打开方式。
enum MiniProgramAction {
  /// 在 App 内置的小程序容器里打开 web 站内页面。
  miniProgram,

  /// 外链（仍然用小程序容器打开，菜单里提供“在浏览器打开”）。
  externalLink,
}

/// 小程序目录里的一项。
class MiniProgramEntry {
  final String key;
  final String label;
  final String iconName;
  final MiniProgramAction action;
  final String url;

  /// 是否属于内容分区（分区在抽屉里单独一组）。
  final bool isPartition;

  /// 接口返回的自定义配色。
  final String? colorBg;
  final String? colorFg;

  /// 是否来自接口动态应用。
  final bool isDynamic;

  const MiniProgramEntry({
    required this.key,
    required this.label,
    required this.iconName,
    required this.action,
    required this.url,
    this.isPartition = false,
    this.colorBg,
    this.colorFg,
    this.isDynamic = false,
  });
}

/// 内容分区（与 web `src/constants/partitions.ts` 保持一致）。
class MiniProgramPartition {
  final String name;
  final String iconName;
  final String key;

  const MiniProgramPartition({
    required this.name,
    required this.iconName,
    required this.key,
  });
}

/// 小程序目录。
///
/// 微信小程序的入口是「下拉 -> 最近使用 / 我的小程序 / 搜索」，
/// 这里把 web 现有板块与全部分区都注册成小程序，供下拉抽屉使用。
class MiniProgramCatalog {
  static const String webBaseUrl = 'https://ssemarket.cn';

  /// 站内路径转完整 web 地址。
  static String webUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '$webBaseUrl${path.startsWith('/') ? '' : '/'}$path';
  }

  static const List<MiniProgramPartition> partitions = <MiniProgramPartition>[
    MiniProgramPartition(name: '学习交流', iconName: 'tabler:school', key: 'study'),
    MiniProgramPartition(
        name: '生活日常', iconName: 'tabler:coffee', key: 'daily-life'),
    MiniProgramPartition(name: '社团活动', iconName: 'tabler:users', key: 'club'),
    MiniProgramPartition(
        name: '实习就业', iconName: 'tabler:briefcase', key: 'internship'),
    MiniProgramPartition(
        name: '期末资料', iconName: 'tabler:file-text', key: 'materials'),
    MiniProgramPartition(
        name: '宿舍生活', iconName: 'tabler:home', key: 'dormitory'),
    MiniProgramPartition(name: '技术分享', iconName: 'tabler:code', key: 'tech'),
    MiniProgramPartition(
        name: '课程专区', iconName: 'tabler:book', key: 'course-partition'),
    MiniProgramPartition(
        name: '组团捞人', iconName: 'tabler:user-plus', key: 'team-up'),
    MiniProgramPartition(name: '其他', iconName: 'tabler:dots', key: 'misc'),
  ];

  /// 全部内置小程序（对齐 web 路由 + 工作台入口）。
  static const List<MiniProgramEntry> builtinEntries = <MiniProgramEntry>[
    MiniProgramEntry(
      key: 'ranking',
      label: '排行榜',
      iconName: 'tabler:trophy',
      action: MiniProgramAction.miniProgram,
      url: '$webBaseUrl/ranking',
    ),
    MiniProgramEntry(
      key: 'xiaoqiu',
      label: '小秋',
      iconName: 'tabler:sparkles',
      action: MiniProgramAction.miniProgram,
      url: '$webBaseUrl/smart-xiaoqiu',
    ),
    MiniProgramEntry(
      key: 'rating',
      label: '打分',
      iconName: 'tabler:star',
      action: MiniProgramAction.miniProgram,
      url: '$webBaseUrl/rating',
    ),
    MiniProgramEntry(
      key: 'novel',
      label: '小说',
      iconName: 'tabler:book-2',
      action: MiniProgramAction.miniProgram,
      url: '$webBaseUrl/novel',
    ),
    MiniProgramEntry(
      key: 'resume',
      label: '简历',
      iconName: 'tabler:file-cv',
      action: MiniProgramAction.miniProgram,
      url: '$webBaseUrl/resume',
    ),
    MiniProgramEntry(
      key: 'shop',
      label: '商城',
      iconName: 'tabler:shopping-bag',
      action: MiniProgramAction.miniProgram,
      url: '$webBaseUrl/shop',
    ),
    MiniProgramEntry(
      key: 'iwiki',
      label: 'iWiki',
      iconName: 'tabler:book-2',
      action: MiniProgramAction.miniProgram,
      url: '$webBaseUrl/iwiki/',
    ),
    MiniProgramEntry(
      key: 'course',
      label: '课程专区',
      iconName: 'tabler:book',
      action: MiniProgramAction.miniProgram,
      url: '$webBaseUrl/course',
    ),
    MiniProgramEntry(
      key: 'xuerenhui',
      label: '学人汇',
      iconName: 'tabler:external-link',
      action: MiniProgramAction.externalLink,
      url: 'https://scholarhub.top/',
    ),
    MiniProgramEntry(
      key: 'coin',
      label: '币中心',
      iconName: 'tabler:coin',
      action: MiniProgramAction.miniProgram,
      url: '$webBaseUrl/coin',
    ),
    MiniProgramEntry(
      key: 'video',
      label: '视频',
      iconName: 'tabler:video',
      action: MiniProgramAction.miniProgram,
      url: '$webBaseUrl/video',
    ),
    MiniProgramEntry(
      key: 'music',
      label: '音乐',
      iconName: 'tabler:disc',
      action: MiniProgramAction.miniProgram,
      url: '$webBaseUrl/music',
    ),
    MiniProgramEntry(
      key: 'heat',
      label: '热度',
      iconName: 'tabler:flame',
      action: MiniProgramAction.miniProgram,
      url: '$webBaseUrl/heat',
    ),
    MiniProgramEntry(
      key: 'save',
      label: '收藏',
      iconName: 'tabler:bookmark',
      action: MiniProgramAction.miniProgram,
      url: '$webBaseUrl/save',
    ),
    MiniProgramEntry(
      key: 'history',
      label: '足迹',
      iconName: 'tabler:history',
      action: MiniProgramAction.miniProgram,
      url: '$webBaseUrl/history',
    ),
    MiniProgramEntry(
      key: 'partitions',
      label: '全部分区',
      iconName: 'tabler:apps',
      action: MiniProgramAction.miniProgram,
      url: '$webBaseUrl/partitions',
    ),
    MiniProgramEntry(
      key: 'search',
      label: '搜索',
      iconName: 'tabler:search',
      action: MiniProgramAction.miniProgram,
      url: '$webBaseUrl/search',
    ),
    MiniProgramEntry(
      key: 'feedback',
      label: '反馈',
      iconName: 'tabler:message-report',
      action: MiniProgramAction.miniProgram,
      url: '$webBaseUrl/feedback',
    ),
  ];

  /// 把接口应用转换为小程序条目；名称与内置入口重复的会被过滤。
  static List<MiniProgramEntry> mergeDynamicApps(
    List<MiniProgramAppItem> apps, {
    List<MiniProgramEntry> base = builtinEntries,
  }) {
    final builtinNames = base.map((e) => e.label).toSet();
    final dynamicEntries = <MiniProgramEntry>[];
    for (final app in apps) {
      if (app.name.isEmpty || builtinNames.contains(app.name)) continue;
      dynamicEntries.add(
        MiniProgramEntry(
          key: 'app-${app.appID}',
          label: app.name,
          iconName: app.icon,
          action: app.isRoute
              ? MiniProgramAction.miniProgram
              : MiniProgramAction.externalLink,
          url: app.isRoute ? webUrl(app.target) : app.target,
          colorBg: app.colorBg,
          colorFg: app.colorFg,
          isDynamic: true,
        ),
      );
    }
    return <MiniProgramEntry>[...base, ...dynamicEntries];
  }

  /// 分区转小程序条目。
  static List<MiniProgramEntry> partitionEntries() {
    return partitions
        .map(
          (p) => MiniProgramEntry(
            key: 'partition-${p.key}',
            label: p.name,
            iconName: p.iconName,
            action: MiniProgramAction.miniProgram,
            url: webUrl('/partition/${Uri.encodeComponent(p.name)}'),
            isPartition: true,
          ),
        )
        .toList(growable: false);
  }

  /// 根据 key 查条目（用于最近使用 / 我的小程序）。
  static MiniProgramEntry? findByKey(
    String key, {
    List<MiniProgramEntry>? extra,
  }) {
    for (final entry in builtinEntries) {
      if (entry.key == key) return entry;
    }
    for (final entry in partitionEntries()) {
      if (entry.key == key) return entry;
    }
    if (extra != null) {
      for (final entry in extra) {
        if (entry.key == key) return entry;
      }
    }
    return null;
  }

  /// Tabler 图标名 -> Material 图标。未知图标回退到网格图标。
  static IconData iconFor(String name) {
    const mapping = <String, IconData>{
      'tabler:trophy': Icons.emoji_events_outlined,
      'tabler:sparkles': Icons.auto_awesome_outlined,
      'tabler:star': Icons.star_outline_rounded,
      'tabler:book-2': Icons.menu_book_outlined,
      'tabler:file-cv': Icons.contact_page_outlined,
      'tabler:shopping-bag': Icons.shopping_bag_outlined,
      'tabler:external-link': Icons.open_in_new_rounded,
      'tabler:book': Icons.book_outlined,
      'tabler:coin': Icons.monetization_on_outlined,
      'tabler:video': Icons.play_circle_outline_rounded,
      'tabler:music': Icons.headphones_outlined,
      'tabler:headphones': Icons.headphones_outlined,
      'tabler:flame': Icons.local_fire_department_outlined,
      'tabler:apps': Icons.apps_rounded,
      'tabler:bookmark': Icons.bookmark_outline_rounded,
      'tabler:history': Icons.history_rounded,
      'tabler:search': Icons.search_rounded,
      'tabler:message-report': Icons.feedback_outlined,
      'tabler:school': Icons.school_outlined,
      'tabler:coffee': Icons.local_cafe_outlined,
      'tabler:users': Icons.groups_outlined,
      'tabler:briefcase': Icons.work_outline_rounded,
      'tabler:file-text': Icons.description_outlined,
      'tabler:home': Icons.home_outlined,
      'tabler:code': Icons.code_rounded,
      'tabler:user-plus': Icons.person_add_alt_1_outlined,
      'tabler:dots': Icons.more_horiz_rounded,
    };
    return mapping[name] ?? Icons.widgets_outlined;
  }

  /// 粉彩配色（与 web 工作台一致）；`dark` 时使用高饱和深色底。
  static ({Color bg, Color fg}) paletteFor(String key, {required bool dark}) {
    const light = <String, (Color, Color)>{
      'ranking': (Color(0xFFFEF3C7), Color(0xFFB45309)),
      'xiaoqiu': (Color(0xFFE0F2FE), Color(0xFF0369A1)),
      'rating': (Color(0xFFFEF9C3), Color(0xFFA16207)),
      'novel': (Color(0xFFEDE9FE), Color(0xFF6D28D9)),
      'resume': (Color(0xFFCCFBF1), Color(0xFF0F766E)),
      'shop': (Color(0xFFD1FAE5), Color(0xFF047857)),
      'iwiki': (Color(0xFFE0E7FF), Color(0xFF4338CA)),
      'course': (Color(0xFFFFEDD5), Color(0xFFC2410C)),
      'xuerenhui': (Color(0xFFE2E8F0), Color(0xFF334155)),
      'coin': (Color(0xFFFEF3C7), Color(0xFFB45309)),
      'video': (Color(0xFFFFE4E6), Color(0xFFBE123C)),
      'music': (Color(0xFFFCE7F3), Color(0xFFBE185D)),
      'heat': (Color(0xFFFFEDD5), Color(0xFFC2410C)),
      'save': (Color(0xFFE0E7FF), Color(0xFF4338CA)),
      'history': (Color(0xFFF1F5F9), Color(0xFF475569)),
      'partitions': (Color(0xFFCFFAFE), Color(0xFF0E7490)),
      'search': (Color(0xFFE0F2FE), Color(0xFF0369A1)),
      'feedback': (Color(0xFFFCE7F3), Color(0xFFBE185D)),
      'study': (Color(0xFFCFFAFE), Color(0xFF0E7490)),
      'daily-life': (Color(0xFFFCE7F3), Color(0xFFBE185D)),
      'club': (Color(0xFFEDE9FE), Color(0xFF6D28D9)),
      'internship': (Color(0xFFDBEAFE), Color(0xFF1D4ED8)),
      'materials': (Color(0xFFFEF9C3), Color(0xFFA16207)),
      'dormitory': (Color(0xFFFEF3C7), Color(0xFFB45309)),
      'tech': (Color(0xFFE0E7FF), Color(0xFF4338CA)),
      'team-up': (Color(0xFFFFE4E6), Color(0xFFBE123C)),
      'misc': (Color(0xFFF1F5F9), Color(0xFF475569)),
    };
    const deep = <String, (Color, Color)>{
      'ranking': (Color(0xFF78350F), Color(0xFFFDE68A)),
      'xiaoqiu': (Color(0xFF075985), Color(0xFFBAE6FD)),
      'rating': (Color(0xFF713F12), Color(0xFFFEF08A)),
      'novel': (Color(0xFF4C1D95), Color(0xFFDDD6FE)),
      'resume': (Color(0xFF115E59), Color(0xFF99F6E4)),
      'shop': (Color(0xFF064E3B), Color(0xFFA7F3D0)),
      'iwiki': (Color(0xFF312E81), Color(0xFFC7D2FE)),
      'course': (Color(0xFF7C2D12), Color(0xFFFED7AA)),
      'xuerenhui': (Color(0xFF334155), Color(0xFFE2E8F0)),
      'coin': (Color(0xFF78350F), Color(0xFFFDE68A)),
      'video': (Color(0xFF881337), Color(0xFFFECDD3)),
      'music': (Color(0xFF831843), Color(0xFFFBCFE8)),
      'heat': (Color(0xFF7C2D12), Color(0xFFFED7AA)),
      'save': (Color(0xFF312E81), Color(0xFFC7D2FE)),
      'history': (Color(0xFF334155), Color(0xFFCBD5E1)),
      'partitions': (Color(0xFF155E75), Color(0xFFA5F3FC)),
      'search': (Color(0xFF075985), Color(0xFFBAE6FD)),
      'feedback': (Color(0xFF831843), Color(0xFFFBCFE8)),
      'study': (Color(0xFF155E75), Color(0xFFA5F3FC)),
      'daily-life': (Color(0xFF831843), Color(0xFFFBCFE8)),
      'club': (Color(0xFF4C1D95), Color(0xFFDDD6FE)),
      'internship': (Color(0xFF1E3A8A), Color(0xFFBFDBFE)),
      'materials': (Color(0xFF713F12), Color(0xFFFEF08A)),
      'dormitory': (Color(0xFF78350F), Color(0xFFFDE68A)),
      'tech': (Color(0xFF312E81), Color(0xFFC7D2FE)),
      'team-up': (Color(0xFF881337), Color(0xFFFECDD3)),
      'misc': (Color(0xFF334155), Color(0xFFCBD5E1)),
    };
    final table = dark ? deep : light;
    final colors = table[key];
    if (colors != null) return (bg: colors.$1, fg: colors.$2);
    return dark
        ? (bg: const Color(0xFF334155), fg: const Color(0xFFCBD5E1))
        : (bg: const Color(0xFFF1F3F6), fg: const Color(0xFF475569));
  }
}
