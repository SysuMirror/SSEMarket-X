import 'dart:async';

import 'package:flutter/material.dart';

import 'package:sse_market_x/core/skins/skin_service.dart';
import 'package:sse_market_x/shared/theme/app_colors.dart';

/// 全站皮肤背景层 + 开场画面。
///
/// 包在 MaterialApp.builder 里：先铺一层基础底色，再叠皮肤图片和可读性蒙层，
/// 最后放页面内容。页面 Scaffold 在皮肤激活时使用透明背景，皮肤才能透出来。
class SkinBackground extends StatelessWidget {
  final Widget child;

  const SkinBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final skin = SkinService();
    return AnimatedBuilder(
      animation: skin,
      builder: (context, _) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        final wide = MediaQuery.sizeOf(context).width >= 600;
        final asset = skin.backgroundAsset(wide: wide);
        final customUrl = skin.customBackgroundUrl;
        final baseColor = dark ? const Color(0xFF0F172A) : AppColors.background;
        final hasImage = asset != null || customUrl != null;

        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: baseColor),
            if (asset != null)
              Image.asset(
                asset,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              )
            else if (customUrl != null)
              Image.network(
                customUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            if (hasImage)
              ColoredBox(
                color: dark
                    ? Colors.black.withOpacity(0.48)
                    : Colors.white.withOpacity(0.58),
              ),
            child,
            if (skin.splashOpen && skin.splashAsset(wide: wide) != null)
              _SkinSplashOverlay(asset: skin.splashAsset(wide: wide)!),
          ],
        );
      },
    );
  }
}

class _SkinSplashOverlay extends StatefulWidget {
  final String asset;

  const _SkinSplashOverlay({required this.asset});

  @override
  State<_SkinSplashOverlay> createState() => _SkinSplashOverlayState();
}

class _SkinSplashOverlayState extends State<_SkinSplashOverlay> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), _close);
  }

  void _close() {
    _timer?.cancel();
    SkinService().closeSplash();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: _close,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              widget.asset,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: Colors.black),
            ),
            Positioned(
              right: 20,
              top: MediaQuery.of(context).padding.top + 16,
              child: Material(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: _close,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    child: Text(
                      '跳过',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
