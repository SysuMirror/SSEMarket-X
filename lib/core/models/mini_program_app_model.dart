/// 工作台应用（接口 `/api/auth/workbench/apps` 返回的条目）。
///
/// 后端字段口径见 Go `controller/workbench_controller.go`：
/// `targetType` 为 `route` 时 `target` 是站内路径（如 `/novel`），
/// 为 `link` 时 `target` 是完整外链。
class MiniProgramAppItem {
  final int appID;
  final String name;
  final String icon;
  final String targetType;
  final String target;
  final String? colorBg;
  final String? colorFg;

  const MiniProgramAppItem({
    required this.appID,
    required this.name,
    required this.icon,
    required this.targetType,
    required this.target,
    this.colorBg,
    this.colorFg,
  });

  bool get isRoute => targetType == 'route';

  factory MiniProgramAppItem.fromJson(Map<String, dynamic> json) {
    return MiniProgramAppItem(
      appID: _toInt(json['appID'] ?? json['AppID']),
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      icon: (json['icon'] ?? json['Icon'] ?? '').toString(),
      targetType:
          (json['targetType'] ?? json['TargetType'] ?? 'route').toString(),
      target: (json['target'] ?? json['Target'] ?? '').toString(),
      colorBg: _toNullableString(json['colorBg'] ?? json['ColorBg']),
      colorFg: _toNullableString(json['colorFg'] ?? json['ColorFg']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String? _toNullableString(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
