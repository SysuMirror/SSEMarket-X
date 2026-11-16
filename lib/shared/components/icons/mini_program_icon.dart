import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:sse_market_x/core/services/mini_program_catalog.dart';
import 'package:sse_market_x/core/services/mini_program_icon_data.dart';

/// 小程序入口图标：直接使用主站同款 Tabler 线性图标，而不是 Material 图标，
/// 避免和主站、以及其它小程序入口风格不一致/看起来“没加载完”。
class MiniProgramIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color color;

  const MiniProgramIcon({
    super.key,
    required this.name,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final body = kMiniProgramIconBodies[name];
    if (body == null) {
      return Icon(MiniProgramCatalog.iconFor(name), size: size, color: color);
    }
    final svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none">'
        '$body'
        '</svg>';
    return SvgPicture.string(
      svg,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}