import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:sse_market_x/core/miniprogram/mini_program_runtime.dart';
import 'package:sse_market_x/shared/theme/app_colors.dart';

/// 全局小程序容器：WebView 常驻，`hide()` 后仍然保留（音频继续播放），
/// 只有 `destroy()` 才真正释放。
class MiniProgramHost extends StatelessWidget {
  const MiniProgramHost({super.key});

  @override
  Widget build(BuildContext context) {
    final runtime = MiniProgramRuntime();
    return AnimatedBuilder(
      animation: runtime,
      builder: (context, _) {
        if (!runtime.hasController && !runtime.isOpen) {
          return const SizedBox.shrink();
        }
        return Offstage(
          offstage: !runtime.isOpen,
          child: _MiniProgramPanel(runtime: runtime),
        );
      },
    );
  }
}

class _MiniProgramPanel extends StatelessWidget {
  final MiniProgramRuntime runtime;

  const _MiniProgramPanel({required this.runtime});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.surfaceColor,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildBar(context),
            if (runtime.isLoading)
              LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: context.dividerColor.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            Expanded(
              child: Stack(
                children: [
                  if (runtime.controller != null)
                    WebViewWidget(controller: runtime.controller!),
                  if (runtime.error != null)
                    Positioned.fill(
                      child: ColoredBox(
                        color: context.surfaceColor,
                        child: _buildError(context),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(BuildContext context) {
    return Container(
      height: 48,
      color: context.surfaceColor,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Stack(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: context.textPrimaryColor),
                tooltip: '收起（继续后台运行）',
                onPressed: runtime.hide,
              ),
              const Spacer(),
              if (runtime.mediaPlaying)
                IconButton(
                  tooltip: '暂停小程序音频',
                  icon: const Icon(Icons.volume_off_rounded,
                      size: 19, color: Color(0xFFFFB020)),
                  onPressed: runtime.pauseMedia,
                ),
              Container(
                width: 84,
                height: 30,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border:
                      Border.all(color: context.dividerColor.withOpacity(0.9)),
                  color: context.backgroundColor.withOpacity(0.6),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(15)),
                        onTap: () => _showMenu(context),
                        child: Center(
                          child: Icon(Icons.more_horiz_rounded,
                              size: 18, color: context.textPrimaryColor),
                        ),
                      ),
                    ),
                    Container(
                        width: 0.5, height: 16, color: context.dividerColor),
                    Expanded(
                      child: InkWell(
                        borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(15)),
                        onTap: runtime.hide,
                        child: Center(
                          child: Icon(Icons.radio_button_unchecked_rounded,
                              size: 15, color: context.textPrimaryColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // 标题单独居中，不受左右按钮宽度影响。
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 110),
                  child: Text(
                    runtime.app?.name ?? '小程序',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showMenu(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.refresh_rounded,
                    color: context.textPrimaryColor),
                title: Text('刷新',
                    style: TextStyle(color: context.textPrimaryColor)),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  runtime.refresh();
                },
              ),
              ListTile(
                leading: Icon(Icons.volume_off_rounded,
                    color: context.textPrimaryColor),
                title: Text('暂停小程序音频',
                    style: TextStyle(color: context.textPrimaryColor)),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  runtime.pauseMedia();
                },
              ),
              ListTile(
                leading: Icon(Icons.open_in_browser_rounded,
                    color: context.textPrimaryColor),
                title: Text('在浏览器打开',
                    style: TextStyle(color: context.textPrimaryColor)),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final url = await runtime.controller?.currentUrl();
                  final uri = url == null ? null : Uri.tryParse(url);
                  if (uri != null) {
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              ListTile(
                leading:
                    Icon(Icons.close_rounded, color: context.textPrimaryColor),
                title: Text('关闭小程序（停止音频）',
                    style: TextStyle(color: context.textPrimaryColor)),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  runtime.destroy();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 48, color: context.textTertiaryColor),
            const SizedBox(height: 12),
            Text(
              '小程序暂时打不开',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              runtime.error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: context.textTertiaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {
                    final app = runtime.app;
                    if (app != null) runtime.open(app);
                  },
                  child: const Text('重试'),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: runtime.destroy,
                  child: const Text('关闭'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
