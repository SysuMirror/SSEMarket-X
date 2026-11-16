/// 职位账号（web 端编辑器 @ 开发人员用）。
class StaffAliasModel {
  final int userID;
  final String alias;
  final String title;

  const StaffAliasModel({
    required this.userID,
    required this.alias,
    this.title = '',
  });

  factory StaffAliasModel.fromDynamic(dynamic raw) {
    if (raw is! Map) return const StaffAliasModel(userID: 0, alias: '');
    int readInt(String key) {
      final v = raw[key];
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return StaffAliasModel(
      userID: readInt('userID'),
      alias: raw['alias']?.toString() ?? '',
      title: raw['title']?.toString() ?? '',
    );
  }
}