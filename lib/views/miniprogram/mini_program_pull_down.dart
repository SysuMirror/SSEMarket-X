import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 微信式真下拉：列表跟随手指向下移动，顶部露出小程序面板；
/// 松手后按阈值吸附到展开/收起，不是浮窗。
class MiniProgramPullDownHost extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext context, VoidCallback close) panelBuilder;
  final double topOffset;
  final ValueChanged<bool>? onOpenChanged;

  const MiniProgramPullDownHost({
    super.key,
    required this.child,
    required this.panelBuilder,
    required this.topOffset,
    this.onOpenChanged,
  });

  @override
  State<MiniProgramPullDownHost> createState() =>
      _MiniProgramPullDownHostState();
}

class _MiniProgramPullDownHostState extends State<MiniProgramPullDownHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _open = false;
  bool _armed = false;
  bool _closing = false;

  /// 抽屉完全拉开时占满整个屏幕；未展开时由下拉距离决定露出高度。
  double get _maxPanelHeight {
    final screen = MediaQuery.sizeOf(context);
    return math.max(0, screen.height - widget.topOffset);
  }

  double get _pull => _controller.value * _maxPanelHeight;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _handleScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    final max = _maxPanelHeight;

    if (notification is OverscrollNotification && !_open) {
      final atTop = notification.metrics.extentBefore <= 0;
      if (atTop && notification.overscroll < 0) {
        final next =
            (_controller.value * max - notification.overscroll).clamp(0.0, max);
        _controller.value = next / max;
        // 固定 90dp 的吸附阈值：接近微信下拉，不需要拖到屏幕一小半才展开。
        final armed = next >= 90;
        if (armed != _armed) {
          _armed = armed;
          if (armed) HapticFeedback.lightImpact();
        }
      }
    } else if (notification is ScrollEndNotification && !_open) {
      if (_pull >= 90) {
        _open = true;
        widget.onOpenChanged?.call(true);
        _controller.animateTo(1, curve: Curves.easeOutCubic);
      } else {
        _controller.animateBack(0, curve: Curves.easeOutCubic);
      }
      _armed = false;
    } else if (notification is ScrollUpdateNotification &&
        notification.metrics.pixels > 0 &&
        !_open &&
        _controller.value > 0) {
      // 正常向上滚动时收起未完全展开的下拉
      _controller.animateBack(0, duration: const Duration(milliseconds: 160));
    }
    return false;
  }

  Future<void> _close() async {
    if (_closing || (!_open && _controller.value == 0)) return;
    _closing = true;
    _open = false;
    _armed = false;
    await _controller.animateBack(0, curve: Curves.easeOutCubic);
    // 收起动画结束后再恢复底部导航，避免动画中途 body 高度突变。
    widget.onOpenChanged?.call(false);
    _closing = false;
  }

  /// 小程序面板拉到列表底部后继续上滑 → 收起抽屉，回到主页。
  /// 不依赖“取消”按钮，符合微信小程序面板的基本操作。
  bool _handlePanelScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification is OverscrollNotification &&
        notification.overscroll > 0 &&
        notification.metrics.extentAfter <= 0) {
      _close();
      return true;
    }
    return false;
  }

  bool _handlePanelDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -260) {
      _close();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final max = _maxPanelHeight;
    final pull = _pull;

    return Stack(
      children: [
        // 列表整体跟随下拉位移
        Transform.translate(
          offset: Offset(0, pull),
          child: NotificationListener<ScrollNotification>(
            onNotification: _handleScroll,
            child: widget.child,
          ),
        ),
        if (pull > 0.5)
          Positioned(
            top: widget.topOffset,
            left: 0,
            right: 0,
            height: pull.clamp(0.0, max),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(22),
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragEnd: _handlePanelDragEnd,
                child: NotificationListener<ScrollNotification>(
                  onNotification: _handlePanelScroll,
                  child: OverflowBox(
                    alignment: Alignment.topCenter,
                    minHeight: max,
                    maxHeight: max,
                    child: widget.panelBuilder(context, _close),
                  ),
                ),
              ),
            ),
          ),
        // 展开后点列表区域收起（豆包/微信式）
        if (_open)
          Positioned(
            top: widget.topOffset + max,
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _close,
              child: const SizedBox.expand(),
            ),
          ),
      ],
    );
  }
}
