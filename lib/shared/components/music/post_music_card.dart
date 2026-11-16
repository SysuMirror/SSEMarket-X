import 'package:flutter/material.dart';

import 'package:sse_market_x/core/api/api_service.dart';
import 'package:sse_market_x/core/models/music_model.dart';
import 'package:sse_market_x/core/services/music_player_service.dart';
import 'package:sse_market_x/shared/components/utils/snackbar_helper.dart';
import 'package:sse_market_x/shared/theme/app_colors.dart';

/// 帖子正文里的 `::music <id>::` 占位卡片：
/// 点击直接试听；也可以一键进入「音乐视频」小程序。
class PostMusicCard extends StatefulWidget {
  final int musicID;

  const PostMusicCard({super.key, required this.musicID});

  @override
  State<PostMusicCard> createState() => _PostMusicCardState();
}

class _PostMusicCardState extends State<PostMusicCard> {
  static final Map<int, MusicModel> _cache = <int, MusicModel>{};

  MusicModel? _music;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cached = _cache[widget.musicID];
    if (cached != null) {
      setState(() {
        _music = cached;
        _loading = false;
      });
      return;
    }
    final list = await ApiService().getMusicList(ids: <int>[widget.musicID]);
    if (!mounted) return;
    setState(() {
      _music = list.isEmpty ? null : list.first;
      if (_music != null) _cache[widget.musicID] = _music!;
      _loading = false;
    });
  }

  Future<void> _play() async {
    final music = _music;
    if (music == null) return;
    final player = MusicPlayerService();
    if (!player.isSupported) {
      if (mounted) SnackBarHelper.show(context, '当前平台暂不支持内嵌播放');
      return;
    }
    if (player.current.value?.musicID == music.musicID) {
      await player.toggle();
      return;
    }
    final ok = await player.play(music);
    if (!ok && mounted) {
      SnackBarHelper.show(context, '音频播放失败，请稍后重试');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text('正在加载音乐…',
                style:
                    TextStyle(fontSize: 12, color: context.textTertiaryColor)),
          ],
        ),
      );
    }

    final music = _music;
    if (music == null) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('音频已失效',
            style: TextStyle(fontSize: 12, color: context.textTertiaryColor)),
      );
    }

    final player = MusicPlayerService();
    return ValueListenableBuilder(
      valueListenable: player.current,
      builder: (context, current, _) {
        return ValueListenableBuilder(
          valueListenable: player.playing,
          builder: (context, playing, __) {
            final isCurrent = current?.musicID == music.musicID;
            final isPlaying = isCurrent && playing;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.dividerColor.withOpacity(0.6),
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: music.coverUrl == null
                          ? Container(
                              color: AppColors.primary.withOpacity(0.1),
                              child: const Icon(Icons.music_note_rounded,
                                  color: AppColors.primary),
                            )
                          : Image.network(
                              music.coverUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppColors.primary.withOpacity(0.1),
                                child: const Icon(Icons.music_note_rounded,
                                    color: AppColors.primary),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
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
                        const SizedBox(height: 2),
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
                    tooltip: isPlaying ? '暂停' : '播放',
                    icon: Icon(
                      isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_fill_rounded,
                      size: 30,
                      color: AppColors.primary,
                    ),
                    onPressed: _play,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
