/// 在线人数快照（对齐 web `src/api/presence/presence.ts`）。
class PresenceSnapshot {
  final int online;
  final int viewers;
  final String scene;
  final int targetID;
  final int windowSeconds;
  final int heartbeatSeconds;

  const PresenceSnapshot({
    this.online = 0,
    this.viewers = 0,
    this.scene = '',
    this.targetID = 0,
    this.windowSeconds = 150,
    this.heartbeatSeconds = 60,
  });

  factory PresenceSnapshot.fromDynamic(dynamic raw) {
    if (raw is! Map) return const PresenceSnapshot();
    int readInt(String key) {
      final v = raw[key];
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return PresenceSnapshot(
      online: readInt('online'),
      viewers: readInt('viewers'),
      scene: raw['scene']?.toString() ?? '',
      targetID: readInt('targetID'),
      windowSeconds:
          readInt('windowSeconds') == 0 ? 150 : readInt('windowSeconds'),
      heartbeatSeconds:
          readInt('heartbeatSeconds') == 0 ? 60 : readInt('heartbeatSeconds'),
    );
  }
}
