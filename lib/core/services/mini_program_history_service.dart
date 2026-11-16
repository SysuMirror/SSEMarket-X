import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 小程序的「最近使用」与「我的小程序」。
///
/// 对应微信下拉面板里的两栏：最近使用按打开时间倒序；
/// 我的小程序由小程序右上角菜单手动添加，本地持久化。
class MiniProgramHistoryService {
  static final MiniProgramHistoryService _instance =
      MiniProgramHistoryService._internal();
  factory MiniProgramHistoryService() => _instance;
  MiniProgramHistoryService._internal();

  static const String _recentKey = 'mini_program_recent_keys';
  static const String _favoriteKey = 'mini_program_favorite_keys';
  static const int maxRecent = 20;

  final ValueNotifier<List<String>> recentNotifier =
      ValueNotifier<List<String>>(const <String>[]);
  final ValueNotifier<List<String>> favoriteNotifier =
      ValueNotifier<List<String>>(const <String>[]);

  bool _initialized = false;

  List<String> get recentKeys => recentNotifier.value;
  List<String> get favoriteKeys => favoriteNotifier.value;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    final prefs = await SharedPreferences.getInstance();
    recentNotifier.value = prefs.getStringList(_recentKey) ?? const <String>[];
    favoriteNotifier.value =
        prefs.getStringList(_favoriteKey) ?? const <String>[];
  }

  /// 打开小程序时记录最近使用（去重后置顶）。
  Future<void> recordOpen(String key) async {
    if (key.isEmpty) return;
    final next = <String>[key, ...recentKeys.where((k) => k != key)];
    if (next.length > maxRecent) next.removeRange(maxRecent, next.length);
    recentNotifier.value = List<String>.unmodifiable(next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentKey, next);
  }

  Future<void> removeRecent(String key) async {
    final next = recentKeys.where((k) => k != key).toList(growable: false);
    recentNotifier.value = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentKey, next);
  }

  bool isFavorite(String key) => favoriteKeys.contains(key);

  /// 添加/移除「我的小程序」，返回操作后是否在收藏中。
  Future<bool> toggleFavorite(String key) async {
    final next = <String>[...favoriteKeys];
    final bool added;
    if (next.contains(key)) {
      next.remove(key);
      added = false;
    } else {
      next.insert(0, key);
      added = true;
    }
    favoriteNotifier.value = List<String>.unmodifiable(next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoriteKey, next);
    return added;
  }
}
