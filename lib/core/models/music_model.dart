/// 音乐（对齐 web `MusicSummary`）。
class MusicModel {
  final int musicID;
  final String title;
  final String artist;
  final String album;
  final int durationSec;
  final String format;
  final bool hasCover;
  final int playCount;
  final String uploaderName;
  final String postTime;

  const MusicModel({
    required this.musicID,
    required this.title,
    this.artist = '',
    this.album = '',
    this.durationSec = 0,
    this.format = '',
    this.hasCover = false,
    this.playCount = 0,
    this.uploaderName = '',
    this.postTime = '',
  });

  factory MusicModel.fromDynamic(dynamic raw) {
    if (raw is! Map) return const MusicModel(musicID: 0, title: '');
    int readInt(String key) {
      final v = raw[key];
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return MusicModel(
      musicID: readInt('musicID'),
      title: raw['title']?.toString() ?? '',
      artist: raw['artist']?.toString() ?? '',
      album: raw['album']?.toString() ?? '',
      durationSec: readInt('durationSec'),
      format: raw['format']?.toString() ?? '',
      hasCover: raw['hasCover'] == true,
      playCount: readInt('playCount'),
      uploaderName: raw['uploaderName']?.toString() ?? '',
      postTime: raw['postTime']?.toString() ?? '',
    );
  }

  String get fileUrl => 'https://ssemarket.cn/api/music/file/$musicID';
  String? get coverUrl =>
      hasCover ? 'https://ssemarket.cn/api/music/cover/$musicID' : null;
}
