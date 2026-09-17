// 工作台动态应用数据模型
//
// 对应 /auth/workbench/apps 返回的裸陣列条目（全站唯一匿名 /auth/* 端点）。
// groupName/source/invokerSlug/sortOrder/createdAt 前端未使用，不解析；
// 字段一律 null 容错（参考 ranking_model.dart 写法）。

int _readInt(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final v = map[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      final parsed = int.tryParse(v);
      if (parsed != null) return parsed;
    }
  }
  return 0;
}

String _readString(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final v = map[key];
    if (v is String) return v;
  }
  return '';
}

bool _readBool(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final v = map[key];
    if (v is bool) return v;
    if (v is int) return v != 0;
    if (v is String) return v.toLowerCase() == 'true' || v == '1';
  }
  return false;
}

/// 后端动态下发的工作台应用入口
class WorkbenchApp {
  final int appId;
  final String name;

  /// tabler/ph 图标标识（如 tabler:database），App 无对应资源，不渲染
  final String icon;

  /// "link"（外连）| "route"（内部路由）
  final String targetType;
  final String target;
  final bool isVisible;

  /// 实测样本为空字符串，本批忽略不渲染；遇非空值原样保留供排查
  final String colorBg;
  final String colorFg;

  const WorkbenchApp({
    required this.appId,
    required this.name,
    required this.icon,
    required this.targetType,
    required this.target,
    required this.isVisible,
    required this.colorBg,
    required this.colorFg,
  });

  factory WorkbenchApp.fromDynamic(dynamic raw) {
    if (raw is! Map) {
      return const WorkbenchApp(
        appId: 0,
        name: '',
        icon: '',
        targetType: '',
        target: '',
        isVisible: false,
        colorBg: '',
        colorFg: '',
      );
    }
    final map = raw.cast<String, dynamic>();
    return WorkbenchApp(
      appId: _readInt(map, ['appID', 'AppID', 'id']),
      name: _readString(map, ['name', 'Name']),
      icon: _readString(map, ['icon', 'Icon']),
      targetType: _readString(map, ['targetType', 'TargetType']),
      target: _readString(map, ['target', 'Target']),
      isVisible: _readBool(map, ['isVisible', 'IsVisible']),
      colorBg: _readString(map, ['colorBg', 'ColorBg']),
      colorFg: _readString(map, ['colorFg', 'ColorFg']),
    );
  }
}
