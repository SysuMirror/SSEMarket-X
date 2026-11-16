import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 首页下拉手势检测：模仿微信聊天列表下拉打开「最近使用的小程序」。
///
/// 列表在顶部继续向下拉时累计 overscroll，松手（ScrollEnd）超过阈值即触发；
/// 不干扰正常的上下滚动。
class MiniProgramPullDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onTriggered;
  final double threshold;

  const MiniProgramPullDetector({
    super.key,
    required this.child,
    required this.onTriggered,
    this.threshold = 72,
  });

  @override
  State<MiniProgramPullDetector> createState() =>
      _MiniProgramPullDetectorState();
}

class _MiniProgramPullDetectorState extends State<MiniProgramPullDetector> {
  double _pull = 0;
  bool _armed = false;

  bool _handleNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    if (notification is OverscrollNotification) {
      final atTop = notification.metrics.extentBefore <= 0;
      if (atTop && notification.overscroll < 0) {
        _pull += -notification.overscroll;
        if (!_armed && _pull >= widget.threshold) {
          _armed = true;
          HapticFeedback.lightImpact();
          setState(() {});
        } else if (!_armed) {
          setState(() {});
        }
      }
    } else if (notification is ScrollUpdateNotification) {
      if (notification.metrics.pixels > 0 && _pull != 0) {
        setState(() {
          _pull = 0;
          _armed = false;
        });
      }
    } else if (notification is ScrollEndNotification) {
      if (_armed) {
        widget.onTriggered();
      }
      if (_pull != 0 || _armed) {
        setState(() {
          _pull = 0;
          _armed = false;
        });
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_pull / widget.threshold).clamp(0.0, 1.0);
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _handleNotification,
          child: widget.child,
        ),
        // 下拉时的轻量提示（微信的面板会跟随下拉出现，这里用提示条过渡）。
        if (progress > 0)
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Opacity(
                  opacity: progress,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.72),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _armed
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _armed ? '松开打开小程序' : '下拉打开小程序',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
