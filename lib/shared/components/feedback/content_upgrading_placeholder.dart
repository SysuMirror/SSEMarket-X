import 'package:flutter/material.dart';

import 'package:sse_market_x/shared/theme/app_colors.dart';

/// 列表接口响应结构不兼容时显示的占位（内容升级中）
class ContentUpgradingPlaceholder extends StatelessWidget {
  const ContentUpgradingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.system_update_alt_outlined,
            size: 64,
            color: context.textTertiaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            '内容升级中',
            style: TextStyle(
              fontSize: 14,
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
