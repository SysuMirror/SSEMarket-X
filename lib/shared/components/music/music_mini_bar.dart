import 'package:flutter/material.dart';

import 'package:sse_market_x/core/services/music_player_service.dart';
import 'package:sse_market_x/shared/theme/app_colors.dart';

/// 主站「正在播放」浮动条：帖子内嵌音乐播放时出现，提供暂停/停止。
class MusicMiniBar extends StatelessWidget {
  const MusicMiniBar({super.key});

  @override
  Widget build(BuildContext context) {
    final player = MusicPlayerService();
    return ValueListenableBuilder(
      valueListenable: player.current,
      builder: (context, music, _) {
        if (music == null) return const SizedBox.shrink();
        return ValueListenableBuilder(
          valueListenable: player.playing,
          builder: (context, playing, __) {
            return Positioned(
              left: 12,
              right: 12,
              bottom: MediaQuery.of(context).padding.bottom + 78,
              child: Material(
                color: context.surfaceColor,
                elevation: 8,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.music_note_rounded,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              music.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: context.textPrimaryColor,
                              ),
                            ),
                            Text(
                              music.artist.isEmpty ? '未知歌手' : music.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: context.textTertiaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          playing
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                        onPressed: player.toggle,
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: '关闭音乐',
                        icon: Icon(Icons.close_rounded,
                            color: context.textSecondaryColor, size: 20),
                        onPressed: player.stop,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
