import 'package:flutter/material.dart';

import 'package:sse_market_x/core/services/presence_service.dart';
import 'package:sse_market_x/shared/theme/app_colors.dart';

/// 在线人数徽标（对齐 web `PresenceBadge.vue`）。
///
/// 传 scene + targetID 时显示「M 人正在看 · 全站 N 人在线」；
/// 只传 scene=home 时只显示全站在线人数。
class PresenceBadge extends StatefulWidget {
  final String scene;
  final int targetID;
  final String label;
  final bool compact;

  const PresenceBadge({
    super.key,
    this.scene = 'home',
    this.targetID = 0,
    this.label = '正在看',
    this.compact = false,
  });

  @override
  State<PresenceBadge> createState() => _PresenceBadgeState();
}

class _PresenceBadgeState extends State<PresenceBadge> {
  final PresenceService _presence = PresenceService();

  bool get _hasViewers => widget.scene != 'home' && widget.targetID > 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _presence.setTarget(widget.scene, targetID: widget.targetID);
    });
  }

  @override
  void didUpdateWidget(covariant PresenceBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scene != widget.scene ||
        oldWidget.targetID != widget.targetID) {
      _presence.setTarget(widget.scene, targetID: widget.targetID);
    }
  }

  @override
  void dispose() {
    if (_hasViewers) {
      // 离开内容页时回到 home，避免在线场景残留。
      _presence.setTarget('home');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _presence.snapshot,
      builder: (context, snapshot, _) {
        final online = snapshot?.online ?? 0;
        final viewers = snapshot?.viewers ?? 0;
        final text = _hasViewers
            ? '$viewers 人${widget.label} · 全站 $online 人在线'
            : '全站 $online 人在线';

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 7 : 9,
            vertical: widget.compact ? 2 : 3,
          ),
          decoration: BoxDecoration(
            color: context.surfaceColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: context.dividerColor, width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: widget.compact ? 5 : 6,
                height: widget.compact ? 5 : 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: widget.compact ? 10.5 : 11.5,
                    height: 1.3,
                    color: context.textSecondaryColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
