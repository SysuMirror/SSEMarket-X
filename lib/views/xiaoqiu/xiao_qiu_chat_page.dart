import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sse_market_x/core/services/xiao_qiu_service.dart';
import 'package:sse_market_x/shared/components/utils/snackbar_helper.dart';
import 'package:sse_market_x/shared/components/markdown/latex_markdown.dart';
import 'package:sse_market_x/shared/theme/app_colors.dart';

enum _ItemKind { user, assistant, step }

class _ChatItem {
  final _ItemKind kind;
  String text;
  String label;
  bool done;
  String? runId;
  bool collapsed;

  _ChatItem({
    required this.kind,
    required this.text,
    this.label = '',
    this.done = true,
    this.runId,
    this.collapsed = true,
  });
}

/// 小秋 AI 对话页（交互对齐豆包 App）。
///
/// - 首次进入是欢迎语 + 热帖建议；
/// - 用户消息右侧蓝色气泡，AI 左侧无气泡正文；
/// - 流式输出、停止生成、复制、赞/踩；
/// - 底部输入栏：文本、语音/附件占位、发送/停止；
/// - 右上角历史会话与新建对话。
class XiaoQiuChatPage extends StatefulWidget {
  const XiaoQiuChatPage({super.key});

  @override
  State<XiaoQiuChatPage> createState() => _XiaoQiuChatPageState();
}

class _XiaoQiuChatPageState extends State<XiaoQiuChatPage> {
  final XiaoQiuService _service = XiaoQiuService();
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _focus = FocusNode();

  final List<_ChatItem> _items = <_ChatItem>[];
  List<String> _suggestions = const <String>[];

  String _sessionId = '';
  bool _loading = true;
  bool _streaming = false;
  StreamSubscription<({String event, Map<String, dynamic> data})>? _streamSub;
  bool _hasUserMessage = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _bootstrap({String? sessionId}) async {
    setState(() => _loading = true);
    try {
      final data = await _service.bootstrap(sessionId: sessionId);
      if (!mounted) return;
      setState(() {
        _sessionId = data.sessionId.isEmpty
            ? 'app-${DateTime.now().millisecondsSinceEpoch}'
            : data.sessionId;
        _items
          ..clear()
          ..addAll(
            data.messages.where((m) => m.content.trim().isNotEmpty).map(
                  (m) => _ChatItem(
                    kind:
                        m.role == 'user' ? _ItemKind.user : _ItemKind.assistant,
                    text: m.content,
                  ),
                ),
          );
        if (_items.isEmpty) _seedWelcome();
        _hasUserMessage = _items.any((e) => e.kind == _ItemKind.user);
        _loading = false;
      });
      final suggestions = await _service.suggestions();
      if (mounted) setState(() => _suggestions = suggestions);
      _scrollToBottom(force: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _seedWelcome();
      });
      SnackBarHelper.show(context, '小秋暂时连不上，请稍后重试');
    }
  }

  void _seedWelcome() {
    _items.add(
      _ChatItem(
        kind: _ItemKind.assistant,
        text: '你好，我是小秋。\n集市里的事都可以问我：查帖子、写内容、找资料、解决问题。',
      ),
    );
  }

  Future<void> _newChat() async {
    if (_streaming) {
      SnackBarHelper.show(context, '小秋正在回复，请先停止或稍等');
      return;
    }
    final id =
        'app-${DateTime.now().millisecondsSinceEpoch}-${DateTime.now().microsecond % 1000}';
    try {
      await _service.bootstrap(sessionId: id);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _sessionId = id;
      _items..clear();
      _seedWelcome();
      _hasUserMessage = false;
    });
    _scrollToBottom(force: true);
  }

  Future<void> _openHistory() async {
    if (_streaming) {
      SnackBarHelper.show(context, '小秋正在回复，请先停止或稍等');
      return;
    }
    List<({String id, String title, String updatedAt})> list = const [];
    try {
      list = await _service.conversations();
    } catch (_) {}
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.62,
            child: Column(
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                  child: Row(
                    children: [
                      Text(
                        '历史对话',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          _newChat();
                        },
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('新对话'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: list.isEmpty
                      ? Center(
                          child: Text(
                            '还没有历史对话',
                            style: TextStyle(
                              fontSize: 13,
                              color: context.textTertiaryColor,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: list.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: context.dividerColor.withOpacity(0.5),
                          ),
                          itemBuilder: (context2, index) {
                            final conv = list[index];
                            return ListTile(
                              title: Text(
                                conv.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: context.textPrimaryColor,
                                ),
                              ),
                              subtitle: Text(
                                conv.updatedAt
                                    .replaceFirst('T', ' ')
                                    .split('.')
                                    .first,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.textTertiaryColor,
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete_outline_rounded,
                                    size: 19, color: context.textTertiaryColor),
                                onPressed: () async {
                                  try {
                                    await _service.deleteConversation(conv.id);
                                  } catch (_) {}
                                  if (sheetContext.mounted) {
                                    Navigator.of(sheetContext).pop();
                                  }
                                  if (conv.id == _sessionId) _newChat();
                                },
                              ),
                              onTap: () async {
                                Navigator.of(sheetContext).pop();
                                await _switchConversation(conv.id);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _switchConversation(String id) async {
    if (id == _sessionId) return;
    setState(() => _loading = true);
    try {
      final messages = await _service.messages(id);
      if (!mounted) return;
      setState(() {
        _sessionId = id;
        _items
          ..clear()
          ..addAll(
            messages.where((m) => m.content.trim().isNotEmpty).map(
                  (m) => _ChatItem(
                    kind:
                        m.role == 'user' ? _ItemKind.user : _ItemKind.assistant,
                    text: m.content,
                  ),
                ),
          );
        if (_items.isEmpty) _seedWelcome();
        _hasUserMessage = _items.any((e) => e.kind == _ItemKind.user);
        _loading = false;
      });
      _scrollToBottom(force: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      SnackBarHelper.show(context, '加载历史对话失败');
    }
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _streaming || _loading) return;
    _input.clear();
    setState(() {
      _hasUserMessage = true;
      _suggestions = const <String>[];
      _items.add(_ChatItem(kind: _ItemKind.user, text: text));
      _items.add(_ChatItem(
        kind: _ItemKind.assistant,
        text: '',
        done: false,
      ));
      _streaming = true;
    });
    _scrollToBottom(force: true);

    final assistant = _items.last;
    try {
      _streamSub =
          _service.streamTask(sessionId: _sessionId, task: text).listen(
        (event) {
          if (!mounted) return;
          setState(() {
            if (event.event == 'content') {
              final payload = event.data;
              final mode = payload['mode']?.toString() ?? '';
              final delta = payload['text']?.toString() ?? '';
              if (mode == 'final') {
                assistant.text = delta;
                assistant.done = true;
                assistant.runId = payload['run_id']?.toString();
              } else if (mode == 'append') {
                assistant.text += delta;
              } else {
                assistant.text = delta;
              }
            } else if (event.event == 'status') {
              final tool = event.data['tool']?.toString() ?? '工具';
              final args = event.data['args']?.toString() ?? '';
              _items.add(_ChatItem(
                kind: _ItemKind.step,
                label: '【$tool】',
                text: args.isEmpty ? '正在调用工具…' : args,
              ));
            } else if (event.event == 'error') {
              final msg = event.data['message']?.toString() ?? '对话服务异常';
              assistant.text =
                  assistant.text.trim().isEmpty ? msg : assistant.text;
              assistant.done = true;
            }
          });
          _scrollToBottom();
        },
        onError: (Object e) {
          if (!mounted) return;
          setState(() {
            if (assistant.text.trim().isEmpty) {
              assistant.text = '小秋暂时无法回复，请稍后重试。';
            }
            assistant.done = true;
            _streaming = false;
          });
        },
        onDone: () {
          if (!mounted) return;
          setState(() {
            if (assistant.text.trim().isEmpty) {
              assistant.text = '当前没有生成有效回复，请稍后重试。';
            }
            assistant.done = true;
            _streaming = false;
          });
          _scrollToBottom();
        },
        cancelOnError: true,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        assistant.text = '发送失败，请检查网络后重试。';
        assistant.done = true;
        _streaming = false;
      });
    }
  }

  Future<void> _stop() async {
    await _streamSub?.cancel();
    _streamSub = null;
    if (!mounted) return;
    setState(() {
      if (_items.isNotEmpty && !_items.last.done) {
        if (_items.last.text.trim().isEmpty) {
          _items.last.text = '已停止生成。';
        }
        _items.last.done = true;
      }
      _streaming = false;
    });
  }

  void _scrollToBottom({bool force = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final position = _scroll.position;
      if (!force && position.maxScrollExtent - position.pixels > 160) return;
      _scroll.animateTo(
        position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 19, color: context.textPrimaryColor),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Row(
          children: [
            _xiaoQiuAvatar(size: 28),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '小秋',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimaryColor,
                  ),
                ),
                Text(
                  '集市 AI 助手',
                  style: TextStyle(
                    fontSize: 10,
                    color: context.textTertiaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '历史对话',
            icon: Icon(Icons.history_rounded,
                size: 21, color: context.textPrimaryColor),
            onPressed: _openHistory,
          ),
          IconButton(
            tooltip: '新对话',
            icon: Icon(Icons.edit_rounded,
                size: 20, color: context.textPrimaryColor),
            onPressed: _newChat,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _hasUserMessage
                    ? _buildMessageList()
                    : _buildWelcome(),
          ),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      children: [
        Center(child: _xiaoQiuAvatar(size: 64)),
        const SizedBox(height: 18),
        Text(
          '你好，我是小秋',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: context.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '集市里的 AI 助手，可以帮你查帖子、写内容、找资料、解决问题。',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.6,
            color: context.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 26),
        if (_suggestions.isNotEmpty)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 10,
            children: _suggestions
                .map(
                  (text) => ActionChip(
                    label: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textPrimaryColor,
                        ),
                      ),
                    ),
                    backgroundColor: context.surfaceColor,
                    side: BorderSide(
                      color: context.dividerColor.withOpacity(0.7),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    onPressed: () => _send(text),
                  ),
                )
                .toList(growable: false),
          ),
      ],
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        if (item.kind == _ItemKind.user) return _buildUserBubble(item);
        if (item.kind == _ItemKind.step) return _buildStep(item);
        return _buildAssistant(item, isLast: index == _items.length - 1);
      },
    );
  }

  Widget _buildUserBubble(_ChatItem item) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: const BoxDecoration(
          color: Color(0xFF0A84FF),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(5),
          ),
        ),
        child: SelectableText(
          item.text,
          style: const TextStyle(
            fontSize: 15,
            height: 1.5,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildAssistant(_ChatItem item, {required bool isLast}) {
    final streaming = !item.done;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _xiaoQiuAvatar(size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.text.isEmpty && streaming)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: _TypingDots(color: context.textTertiaryColor),
                  )
                else
                  LatexMarkdown(
                    data: _chatMarkdown(
                      streaming ? '${item.text}▍' : item.text,
                    ),
                    selectable: true,
                    shrinkWrap: true,
                    fontSize: 15,
                  ),
                if (!streaming && item.text.trim().isNotEmpty)
                  _buildMessageActions(item, isLast: isLast),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _chatMarkdown(String raw) {
    // post://123 -> 可点击的帖子链接
    return raw.replaceAllMapped(
      RegExp(r'post://(\d+)', caseSensitive: false),
      (m) =>
          '[帖子 #${m.group(1)}](https://ssemarket.cn/postdetail/${m.group(1)})',
    );
  }

  Widget _buildMessageActions(_ChatItem item, {required bool isLast}) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          _actionIcon(Icons.copy_rounded, '复制', () {
            Clipboard.setData(ClipboardData(text: item.text));
            SnackBarHelper.show(context, '已复制');
          }),
          _actionIcon(Icons.thumb_up_alt_outlined, '有帮助', () {
            final runId = item.runId;
            if (runId != null) {
              _service.feedback(runId, _sessionId, 1).catchError((_) {});
            }
            SnackBarHelper.show(context, '感谢反馈');
          }),
          _actionIcon(Icons.thumb_down_alt_outlined, '没帮助', () {
            final runId = item.runId;
            if (runId != null) {
              _service.feedback(runId, _sessionId, -1).catchError((_) {});
            }
            SnackBarHelper.show(context, '收到，我们会改进');
          }),
          if (isLast)
            _actionIcon(Icons.refresh_rounded, '重新生成', () {
              if (_streaming) return;
              final lastUser = _items
                  .where((e) => e.kind == _ItemKind.user)
                  .toList(growable: false);
              if (lastUser.isNotEmpty) _send(lastUser.last.text);
            }),
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon, String tooltip, VoidCallback onTap) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      tooltip: tooltip,
      icon: Icon(icon, size: 16, color: context.textTertiaryColor),
      onPressed: onTap,
    );
  }

  Widget _buildStep(_ChatItem item) {
    return Padding(
      padding: const EdgeInsets.only(left: 36, bottom: 10, right: 20),
      child: Material(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => item.collapsed = !item.collapsed),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.build_circle_outlined,
                        size: 15, color: context.textTertiaryColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${item.label} ${item.collapsed ? '' : ''}',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.textTertiaryColor,
                        ),
                      ),
                    ),
                    Icon(
                      item.collapsed
                          ? Icons.expand_more_rounded
                          : Icons.expand_less_rounded,
                      size: 16,
                      color: context.textTertiaryColor,
                    ),
                  ],
                ),
                if (!item.collapsed) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.text,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.5,
                      color: context.textSecondaryColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(
          top: BorderSide(color: context.dividerColor.withOpacity(0.6)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                tooltip: '附件',
                onPressed: () => SnackBarHelper.show(context, '图片/文件输入即将上线'),
                icon: Icon(Icons.add_circle_outline_rounded,
                    size: 24, color: context.textSecondaryColor),
              ),
              Expanded(
                child: Container(
                  constraints:
                      const BoxConstraints(minHeight: 42, maxHeight: 132),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F3F5),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: TextField(
                    controller: _input,
                    focusNode: _focus,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: context.textPrimaryColor,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: '给小秋发消息…',
                      hintStyle: TextStyle(
                        fontSize: 15,
                        color: context.textTertiaryColor,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: '语音',
                onPressed: () => SnackBarHelper.show(context, '语音输入即将上线'),
                icon: Icon(Icons.mic_none_rounded,
                    size: 24, color: context.textSecondaryColor),
              ),
              const SizedBox(width: 2),
              GestureDetector(
                onTap: _streaming ? _stop : () => _send(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _streaming || _input.text.trim().isNotEmpty
                        ? const Color(0xFF0A84FF)
                        : const Color(0xFFD9DBE0),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _streaming
                        ? Icons.stop_rounded
                        : Icons.arrow_upward_rounded,
                    size: 22,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _xiaoQiuAvatar({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/images/xiaoqiu_avatar.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF6EA8FF), Color(0xFF9B7BFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            size: size * 0.55,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  final Color color;

  const _TypingDots({required this.color});

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final active = (_controller.value * 3).floor() % 3;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: index == active
                    ? widget.color
                    : widget.color.withOpacity(0.35),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
