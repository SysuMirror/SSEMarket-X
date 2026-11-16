/// 全站皮肤定义（对齐 web `src/skins/types.ts`）。
class SkinDefinition {
  final String id;
  final String name;
  final String description;
  final String splashMobile;
  final String splashDesktop;
  final String backgroundMobile;
  final String backgroundDesktop;
  final List<SkinSticker> stickers;

  const SkinDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.splashMobile,
    required this.splashDesktop,
    required this.backgroundMobile,
    required this.backgroundDesktop,
    this.stickers = const <SkinSticker>[],
  });
}

class SkinSticker {
  final String id;
  final String file;
  final String label;
  final String note;

  const SkinSticker({
    required this.id,
    required this.file,
    required this.label,
    this.note = '',
  });
}

const String skinAssetRoot = 'assets/skins';

const SkinDefinition programmersDay2026 = SkinDefinition(
  id: 'programmers-day-2026',
  name: '2026 程序员节',
  description: '致敬每一位用代码创造更好世界的你',
  splashMobile: '$skinAssetRoot/programmers-day-2026/splash-mobile.webp',
  splashDesktop: '$skinAssetRoot/programmers-day-2026/splash-desktop.webp',
  backgroundMobile: '$skinAssetRoot/programmers-day-2026/bg-mobile.webp',
  backgroundDesktop: '$skinAssetRoot/programmers-day-2026/bg-desktop.webp',
  stickers: <SkinSticker>[
    SkinSticker(
        id: 'grumpy',
        file: 'stickers/01.webp',
        label: '气鼓鼓',
        note: 'Bug 怎么又回来了'),
    SkinSticker(
        id: 'surrender',
        file: 'stickers/02.webp',
        label: '举手投降',
        note: '这需求做不了'),
    SkinSticker(
        id: 'shock', file: 'stickers/03.webp', label: '震惊', note: '产品经理又改需求了'),
    SkinSticker(
        id: 'fired-up', file: 'stickers/04.webp', label: '握拳', note: '今天必须上线'),
    SkinSticker(
        id: 'giggle', file: 'stickers/05.webp', label: '偷笑', note: '代码一次跑通'),
    SkinSticker(
        id: 'cpu-burn', file: 'stickers/06.webp', label: '混乱', note: 'CPU 已烧'),
    SkinSticker(
        id: 'selfie',
        file: 'stickers/07.webp',
        label: '自拍',
        note: '记录第 100 次提交'),
    SkinSticker(
        id: 'heart', file: 'stickers/08.webp', label: '比心', note: '谢谢你的 Star'),
    SkinSticker(
        id: 'why', file: 'stickers/09.webp', label: '疑惑', note: '为什么本地能跑'),
    SkinSticker(
        id: 'sleepy', file: 'stickers/10.webp', label: '困倦', note: '再改一行就睡'),
    SkinSticker(
        id: 'lgtm', file: 'stickers/11.webp', label: '点赞', note: 'LGTM'),
    SkinSticker(id: 'yay', file: 'stickers/12.webp', label: '欢呼', note: '下班！'),
  ],
);

const List<SkinDefinition> skinList = <SkinDefinition>[programmersDay2026];

SkinDefinition? getSkin(String? id) {
  if (id == null || id.isEmpty) return null;
  for (final skin in skinList) {
    if (skin.id == id) return skin;
  }
  return null;
}

bool isSkinId(String id) => getSkin(id) != null;

/// 皮肤接口返回的活动时间窗。
class ThemeEvent {
  final String themeId;
  final String name;
  final bool active;
  final String startsAt;
  final String endsAt;
  final String serverTime;

  const ThemeEvent({
    required this.themeId,
    required this.name,
    required this.active,
    required this.startsAt,
    required this.endsAt,
    this.serverTime = '',
  });

  factory ThemeEvent.fromDynamic(dynamic raw) {
    if (raw is! Map) {
      return const ThemeEvent(
        themeId: '',
        name: '',
        active: false,
        startsAt: '',
        endsAt: '',
      );
    }
    return ThemeEvent(
      themeId: raw['themeId']?.toString() ?? '',
      name: raw['name']?.toString() ?? '',
      active: raw['active'] == true,
      startsAt: raw['startsAt']?.toString() ?? '',
      endsAt: raw['endsAt']?.toString() ?? '',
      serverTime: raw['serverTime']?.toString() ?? '',
    );
  }
}

class ThemeSettings {
  final String themeMode; // auto | default | <skinID>
  final bool splashEnabled;
  final bool backgroundEnabled;
  final String backgroundSource; // default | custom
  final String customBackgroundUrl;

  const ThemeSettings({
    this.themeMode = 'auto',
    this.splashEnabled = true,
    this.backgroundEnabled = true,
    this.backgroundSource = 'default',
    this.customBackgroundUrl = '',
  });

  ThemeSettings copyWith({
    String? themeMode,
    bool? splashEnabled,
    bool? backgroundEnabled,
    String? backgroundSource,
    String? customBackgroundUrl,
  }) {
    return ThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      splashEnabled: splashEnabled ?? this.splashEnabled,
      backgroundEnabled: backgroundEnabled ?? this.backgroundEnabled,
      backgroundSource: backgroundSource ?? this.backgroundSource,
      customBackgroundUrl: customBackgroundUrl ?? this.customBackgroundUrl,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'themeMode': themeMode,
        'splashEnabled': splashEnabled,
        'backgroundEnabled': backgroundEnabled,
        'backgroundSource': backgroundSource,
        'customBackgroundUrl': customBackgroundUrl,
      };

  factory ThemeSettings.fromDynamic(dynamic raw) {
    if (raw is! Map) return const ThemeSettings();
    final source = raw['backgroundSource']?.toString() ?? 'default';
    return ThemeSettings(
      themeMode: raw['themeMode']?.toString() ?? 'auto',
      splashEnabled:
          raw['splashEnabled'] is bool ? raw['splashEnabled'] as bool : true,
      backgroundEnabled: raw['backgroundEnabled'] is bool
          ? raw['backgroundEnabled'] as bool
          : true,
      backgroundSource: source == 'custom' ? 'custom' : 'default',
      customBackgroundUrl: raw['customBackgroundUrl']?.toString() ?? '',
    );
  }
}
