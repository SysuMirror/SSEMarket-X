import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sse_market_x/core/skins/skin_service.dart';
import 'package:sse_market_x/shared/components/transitions/page_transitions.dart';

/// BuildContext 扩展，方便获取主题相关颜色
extension AppColorsExtension on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get backgroundColor => AppColors.getBackground(this);
  Color get surfaceColor => AppColors.getSurface(this);

  /// 页面级背景：皮肤激活时透明（露出 SkinBackground），否则用 surface。
  Color get pageColor => SkinService().hasBackgroundEnabled
      ? Colors.transparent
      : AppColors.getSurface(this);
  Color get textPrimaryColor => AppColors.getTextPrimary(this);
  Color get textSecondaryColor => AppColors.getTextSecondary(this);
  Color get textTertiaryColor => AppColors.getTextTertiary(this);
  Color get dividerColor => AppColors.getDivider(this);
  Color get inputFillColor => AppColors.getInputFill(this);
  Color get blurBackgroundColor => AppColors.getBlurBackground(this);
}

/// 应用颜色配置
/// 支持亮色和深色模式
class AppColors {
  // 主题色 - 两种模式共用
  static const Color primary = Color(0xFF007DFF);
  static const Color secondary = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF9800);

  // ===== 亮色模式颜色（与 web `mode.css` 的 slate 中性色对齐）=====
  static const Color _lightBackground = Color(0xFFF5F6F7);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightTextPrimary = Color(0xFF1E293B);
  static const Color _lightTextSecondary = Color(0xFF475569);
  static const Color _lightTextTertiary = Color(0xFF94A3B8);
  static const Color _lightDivider = Color(0xFFE2E8F0);

  // ===== 深色模式颜色（slate 深色，对齐 web dark-mode）=====
  static const Color _darkBackground = Color(0xFF0F172A);
  static const Color _darkSurface = Color(0xFF1E293B);
  static const Color _darkTextPrimary = Color(0xFFE2E8F0);
  static const Color _darkTextSecondary = Color(0xFFCBD5E1);
  static const Color _darkTextTertiary = Color(0xFF64748B);
  static const Color _darkDivider = Color(0xFF334155);

  // ===== 静态颜色（向后兼容，默认亮色） =====
  static const Color background = _lightBackground;
  static const Color surface = _lightSurface;
  static const Color textPrimary = _lightTextPrimary;
  static const Color textSecondary = _lightTextSecondary;
  static const Color textTertiary = _lightTextTertiary;
  static const Color divider = _lightDivider;

  // Rating Colors
  static const Color ratingStar = primary;
  static const Color ratingText = primary;
  static Color ratingBg = primary.withOpacity(0.1);

  // ===== 根据亮度获取颜色的方法 =====
  static Color getBackground(BuildContext context) {
    // 皮肤背景激活时页面透明，露出 MaterialApp 底层的 SkinBackground。
    if (SkinService().hasBackgroundEnabled) return Colors.transparent;
    return Theme.of(context).brightness == Brightness.dark
        ? _darkBackground
        : _lightBackground;
  }

  static Color getSurface(BuildContext context) {
    if (SkinService().hasBackgroundEnabled) {
      // 皮肤激活时让页面/卡片略微透明，背景图能透出来。
      return Theme.of(context).brightness == Brightness.dark
          ? const Color(0xE61E293B)
          : const Color(0xD9FFFFFF);
    }
    return Theme.of(context).brightness == Brightness.dark
        ? _darkSurface
        : _lightSurface;
  }

  static Color getTextPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? _darkTextPrimary
        : _lightTextPrimary;
  }

  static Color getTextSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? _darkTextSecondary
        : _lightTextSecondary;
  }

  static Color getTextTertiary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? _darkTextTertiary
        : _lightTextTertiary;
  }

  static Color getDivider(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? _darkDivider
        : _lightDivider;
  }

  static Color getRatingBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? primary.withOpacity(0.2)
        : primary.withOpacity(0.1);
  }

  // ===== 输入框填充色 =====
  static Color getInputFill(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF334155)
        : _lightSurface; // 亮色模式使用白色，与灰色背景区分
  }

  // ===== 模糊背景色（用于毛玻璃效果）=====
  /// 带有淡蓝色调的模糊背景色，提升视觉质感
  /// 亮色模式使用纯白但降低透明度，让内容透出来增加层次感
  /// 暗色模式使用深色表面色
  static Color getBlurBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? _darkSurface // 深色模式：使用表面色
        : _lightSurface; // 亮色模式：使用白色
  }

  // ===== 卡片阴影色 =====
  static Color getCardShadow(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.black.withOpacity(0.3)
        : Colors.black.withOpacity(0.08);
  }
}

/// 主题数据扩展
class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: Colors.transparent,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors._lightSurface,
      error: AppColors.error,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors._lightSurface,
      foregroundColor: AppColors._lightTextPrimary,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // 亮色模式用深色图标
        statusBarBrightness: Brightness.light, // iOS
      ),
    ),
    dividerColor: AppColors._lightDivider,
    cardColor: AppColors._lightSurface,
    // 页面切换动画
    pageTransitionsTheme: AppPageTransitionsTheme.theme,
    // 文字选择样式
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.primary,
      selectionColor: AppColors.primary.withOpacity(0.3),
      selectionHandleColor: AppColors.primary,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: Colors.transparent,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors._darkSurface,
      error: AppColors.error,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors._darkSurface,
      foregroundColor: AppColors._darkTextPrimary,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // 深色模式用浅色图标
        statusBarBrightness: Brightness.dark, // iOS
      ),
    ),
    dividerColor: AppColors._darkDivider,
    cardColor: AppColors._darkSurface,
    // 页面切换动画
    pageTransitionsTheme: AppPageTransitionsTheme.theme,
    // 文字选择样式
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.primary,
      selectionColor: AppColors.primary.withOpacity(0.4),
      selectionHandleColor: AppColors.primary,
    ),
  );
}
