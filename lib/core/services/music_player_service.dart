import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'package:sse_market_x/core/api/api_service.dart';
import 'package:sse_market_x/core/models/music_model.dart';

/// 主站内嵌音乐播放器（帖子里的 `::music id::` 占位卡片）。
///
/// 与小程序音频互不影响：小程序音频由 WebView 自己播放，这里只负责主站
/// 帖子占位音乐的试听。播放器是全局单例，切换页面不会停。
class MusicPlayerService extends ChangeNotifier {
  static final MusicPlayerService _instance = MusicPlayerService._internal();
  factory MusicPlayerService() => _instance;
  MusicPlayerService._internal();

  final AudioPlayer _player = AudioPlayer();
  final ValueNotifier<MusicModel?> current = ValueNotifier<MusicModel?>(null);
  final ValueNotifier<bool> playing = ValueNotifier<bool>(false);
  final ValueNotifier<Duration> position =
      ValueNotifier<Duration>(Duration.zero);
  final ValueNotifier<Duration?> duration = ValueNotifier<Duration?>(null);
  final ValueNotifier<String?> error = ValueNotifier<String?>(null);

  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;
  bool _initialized = false;

  bool get isSupported {
    if (kIsWeb) return true; // just_audio_web
    return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
  }

  void _ensureListeners() {
    if (_initialized) return;
    _initialized = true;
    _stateSub = _player.playerStateStream.listen((state) {
      playing.value =
          state.playing && state.processingState != ProcessingState.completed;
      if (state.processingState == ProcessingState.completed) {
        playing.value = false;
      }
    });
    _posSub = _player.positionStream.listen((p) => position.value = p);
    _durSub = _player.durationStream.listen((d) => duration.value = d);
  }

  Future<bool> play(MusicModel music) async {
    _ensureListeners();
    try {
      error.value = null;
      if (current.value?.musicID != music.musicID) {
        await _player.setUrl(music.fileUrl);
        current.value = music;
        await ApiService().reportMusicPlayed(music.musicID);
      }
      await _player.play();
      return true;
    } catch (e) {
      error.value = '音频播放失败';
      playing.value = false;
      debugPrint('播放音乐失败: $e');
      return false;
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (_) {}
  }

  Future<void> toggle() async {
    if (_player.playing) {
      await pause();
    } else {
      final music = current.value;
      if (music != null) await play(music);
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
      await _player.seek(Duration.zero);
    } catch (_) {}
    playing.value = false;
    current.value = null;
    position.value = Duration.zero;
    duration.value = null;
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}
