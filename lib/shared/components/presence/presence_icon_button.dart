import 'package:flutter/material.dart';

import 'package:sse_market_x/core/services/presence_service.dart';
import 'package:sse_market_x/shared/theme/app_colors.dart';

/// 顶部在线人数入口：一个图标 + 数字角标，点开查看详情。
///
/// 替代原来占一整行文字的存在感徽标，避免把标题挤成“软…”。
class PresenceIconButton extends StatelessWidget {
  const PresenceIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    final presence = PresenceService();
    return ValueListenableBuilder(
      valueListenable: presence.snapshot,
      builder: (context, snapshot, _) {
        final online = snapshot?.online ?? 0;
        return IconButton(
          tooltip: '在线人数',
          onPressed: () => _showDetails(context, snapshot),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.people_alt_outlined,
                size: 22,
                color: context.textPrimaryColor,
              ),
              Positioned(
                right: -7,
                top: -6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  constraints:
                      const BoxConstraints(minWidth: 15, minHeight: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      online > 99 ? '99+' : '$online',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDetails(BuildContext context, dynamic snapshot) {
    final online = snapshot?.online ?? 0;
    final viewers = snapshot?.viewers ?? 0;
    final scene = PresenceService().scene;
    final showViewers = scene != 'home' && viewers > 0;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '在线人数',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '$online',
                  style: const TextStyle(
                    fontSize: 40,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '全站最近 2.5 分钟内有心跳的登录用户',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textTertiaryColor,
                  ),
                ),
                if (showViewers) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: context.backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.visibility_outlined,
                            size: 18, color: context.textSecondaryColor),
                        const SizedBox(width: 8),
                        Text(
                          '本页 $viewers 人正在看',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('知道了'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
