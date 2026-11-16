import 'package:flutter/material.dart';

import 'package:sse_market_x/core/miniprogram/mini_program_runtime.dart';
import 'package:sse_market_x/shared/theme/app_colors.dart';

/// 主站的「小程序音频」入口：小程序被收起后仍然显示，可停止或重新打开。
class MiniProgramMediaBar extends StatelessWidget {
  const MiniProgramMediaBar({super.key});

  @override
  Widget build(BuildContext context) {
    final runtime = MiniProgramRuntime();
    return AnimatedBuilder(
      animation: runtime,
      builder: (context, _) {
        if (!runtime.mediaPlaying || runtime.isOpen) {
          return const SizedBox.shrink();
        }
        return Positioned(
          left: 12,
          right: 12,
          bottom: MediaQuery.of(context).padding.bottom + 134,
          child: Material(
            color: context.surfaceColor,
            elevation: 8,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.widgets_rounded,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${runtime.app?.name ?? '小程序'}正在播放',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimaryColor,
                          ),
                        ),
                        Text(
                          '小程序独立运行；点右侧可停止',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: context.textTertiaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: runtime.pauseMedia,
                    child: const Text('停止', style: TextStyle(fontSize: 12)),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: '打开小程序',
                    icon: Icon(Icons.open_in_full_rounded,
                        size: 18, color: context.textSecondaryColor),
                    onPressed: runtime.show,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
