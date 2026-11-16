import 'package:flutter/material.dart';
import 'package:sse_market_x/shared/components/inputs/segmented_control.dart';
import 'package:sse_market_x/shared/theme/app_colors.dart';

/// 颜文字小类 key 列表
const List<String> kKaomojiSubKeys = [
  'happy',
  'sad',
  'angry',
  'love',
  'surprise',
  'cute',
  'cool',
];

const Map<String, String> kEmojiTabLabels = {
  'happy': '开心',
  'sad': '难过',
  'angry': '愤怒',
  'love': '爱心',
  'surprise': '惊讶',
  'cute': '可爱',
  'cool': '酷炫',
  'emoji': 'Emoji',
};

const Map<String, List<String>> kKaomojis = {
  'happy': [
    '(´∀｀)',
    '(￣▽￣)',
    '(´▽｀)',
    '(￣ω￣)',
    '(´ω｀)',
    '(￣∀￣)',
    '(๑´ㅂ`๑)',
    '(｡♥‿♥｡)',
    '(◕‿◕)',
    '(*´▽`*)',
    '(ﾉ◕ヮ◕)ﾉ*:･ﾟ✧',
    '(＾◡＾)',
    '(◠‿◠)',
    '(´꒳`)',
    '(◡ ω ◡)',
    '(´｡• ᵕ •｡`)',
    '(◕ᴗ◕✿)',
    '(ﾉ◕ヮ◕)ﾉ',
    '(≧∇≦)',
    '(＾▽＾)',
    '(◉‿◉)',
    '(´∇｀)',
    '(◕‿◕)♡'
  ],
  'sad': [
    '(´；ω；｀)',
    '(｡•́︿•̀｡)',
    '(╥_╥)',
    '(T_T)',
    '(;_;)',
    '(ಥ﹏ಥ)',
    '(இ﹏இ`｡)',
    '(┳Д┳)',
    '(个_个)',
    '(´-ω-`)',
    '(｡•́ - •̀｡)',
    '(╯︵╰)',
    '(｡╯︵╰｡)',
    '(´°̥̥̥̥̥̥̥̥ω°̥̥̥̥̥̥̥̥｀)',
    '(｡•́︿•̀｡)',
    '(◞‸◟)',
    '(╥﹏╥)',
    '(ಥ_ಥ)',
    '(´；д；`)',
    '(｡•́︿•̀｡)',
    '(╯_╰)',
    '(´Д｀)'
  ],
  'angry': [
    '(╬ಠ益ಠ)',
    '(ಠ_ಠ)',
    '(¬_¬)',
    '(►_►)',
    '(҂◡_◡)',
    '(ꐦ°᷄д°᷅)',
    '(╯°□°）╯︵ ┻━┻',
    '(ノಠ益ಠ)ノ',
    '(눈_눈)',
    '(⋋▂⋌)',
    '(-_-メ)',
    '(｀皿´＃)',
    '(╯‵□′)╯︵┻━┻',
    '(ﾉ｀Д´)ﾉ彡┻━┻',
    '(ಠ益ಠ)',
    '(◣_◢)',
    '(╬⁽⁽ ⁰ ⁾⁾ Д ⁽⁽ ⁰ ⁾⁾)',
    '(ﾉ°益°)ﾉ',
    '(｀ε´)',
    '(ﾉ｀⌒´)ﾉ┫：・┻┻',
    '(ﾒ｀ﾛ´)/',
    '(ﾉ｀□´)ﾉ⌒┻━┻'
  ],
  'love': [
    '(｡♥‿♥｡)',
    '(´∀｀)♡',
    '(◍•ᴗ•◍)❤',
    '(｡・//ε//・｡)',
    '(๑˃̵ᴗ˂̵)و',
    '(✿◠‿◠)',
    '(⺣◡⺣)♡*',
    '(灬º‿º灬)♡',
    '(ღ˘⌣˘ღ)',
    '(♥ω♥*)',
    '(´ε｀ )',
    '(´∀｀)♡',
    '(◕‿◕)♡',
    '(｡♥‿♥｡)',
    '(◍•ᴗ•◍)♡',
    '(´｡• ω •｡`) ♡',
    '(◡ ‿ ◡)♡',
    '(´∀｀)♡',
    '(◕ᴗ◕)♡',
    '(◍•ᴗ•◍)❤',
    '(´♡‿♡`)',
    '(◕‿◕)♡'
  ],
  'surprise': [
    '(゜o゜;)',
    '(O_O)',
    '(⊙_⊙)',
    '(°ロ°)',
    '(◎_◎;)',
    '(✪ω✪)',
    '(⊙ω⊙)',
    '(◉_◉)',
    '(°△°|||)',
    '(☉_☉)',
    '(ʘᗩʘ)',
    '(⊙０⊙)',
    '(◉０◉)',
    '(°o°)',
    '(⊙.⊙)',
    '(◎０◎)',
    '(°□°)',
    '(⊙▽⊙)',
    '(◉‿◉)',
    '(°▽°)',
    '(⊙ω⊙)',
    '(◎_◎)',
    '(°０°)'
  ],
  'emoji': [
    '😀',
    '😃',
    '😄',
    '😁',
    '😆',
    '😅',
    '🤣',
    '😂',
    '🙂',
    '🙃',
    '😉',
    '😊',
    '😇',
    '🥰',
    '😍',
    '🤩',
    '😘',
    '😗',
    '☺️',
    '😚',
    '😙',
    '🥲',
    '😋',
    '😛',
    '😜',
    '🤪',
    '😝',
    '🤑',
    '🤗',
    '🤭',
    '🤫',
    '🤔',
    '🤐',
    '🤨',
    '😐',
    '😑',
    '😶',
    '😏',
    '😒',
    '🙄',
    '😬',
    '🤥',
    '😔',
    '😪',
    '🤤',
    '😴',
    '😷',
    '🤒'
  ],
  'cute': [
    '(◕‿◕)',
    '(◡ ω ◡)',
    '(´｡• ᵕ •｡`)',
    '(◕ᴗ◕✿)',
    '(´꒳`)',
    '(◠‿◠)',
    '(｡◕‿◕｡)',
    '(◕‿◕)♡',
    '(◍•ᴗ•◍)',
    '(´∀｀)',
    '(◡‿◡)',
    '(◕ω◕)',
    '(◉‿◉)',
    '(◕‿◕)✿',
    '(◍•ᴗ•◍)✧*',
    '(◕‿◕)♪',
    '(◡ ‿ ◡)',
    '(◕‿◕)☆',
    '(◍•ᴗ•◍)♡',
    '(◕‿◕)♫',
    '(◡ ω ◡)♡',
    '(◕‿◕)✨',
    '(◍•ᴗ•◍)♪',
    '(◕‿◕)♬'
  ],
  'cool': [
    '(⌐■_■)',
    '(▀̿Ĺ̯▀̿ ̿)',
    '(◣_◢)',
    '(¬‿¬)',
    '(ಠ_ಠ)',
    '(¬_¬)',
    '(►_►)',
    '(◉_◉)',
    '(⊙_⊙)',
    '(◎_◎)',
    '(°_°)',
    '(-_-)',
    '(¯\\_(ツ)_/¯)',
    '(╯°□°）╯',
    '(ಠ益ಠ)',
    '(◣_◢)',
    '(⌐■_■)',
    '(▀̿Ĺ̯▀̿ ̿)',
    '(¬‿¬)',
    '(ಠ_ಠ)',
    '(¬_¬)',
    '(►_►)',
    '(◉_◉)',
    '(⊙_⊙)'
  ],
};

// ========== 表情内容网格组件==========

/// 单格：仅文字有按压回弹，与邻格用 divider 分隔
/// [span] 仅颜文字有效：1=占一格，2=占两格（长颜文字可多行显示）
class _EmojiCell extends StatefulWidget {
  final String content;
  final bool isEmoji;
  final int span;
  final bool showRightDivider;
  final bool showBottomDivider;
  final VoidCallback onTap;

  const _EmojiCell({
    required this.content,
    required this.isEmoji,
    this.span = 1,
    this.showRightDivider = true,
    this.showBottomDivider = true,
    required this.onTap,
  });

  @override
  State<_EmojiCell> createState() => _EmojiCellState();
}

class _EmojiCellState extends State<_EmojiCell>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cellBg = isDark
        ? const Color(0xFF2C2C2E).withOpacity(0.8)
        : const Color(0xFFE5E5EA).withOpacity(0.6);
    final dividerColor = context.dividerColor;
    const dividerWidth = 0.5;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cellBg,
          border: Border(
            right: widget.showRightDivider
                ? BorderSide(color: dividerColor, width: dividerWidth)
                : BorderSide.none,
            bottom: widget.showBottomDivider
                ? BorderSide(color: dividerColor, width: dividerWidth)
                : BorderSide.none,
          ),
        ),
        child: ScaleTransition(
          scale: _scale,
          child: Text(
            widget.content,
            style: TextStyle(
              fontSize: widget.isEmoji ? 22 : 14,
              color: context.textPrimaryColor,
              height: 1.2,
            ),
            maxLines: widget.span >= 2 && !widget.isEmoji ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// 颜文字长度阈值：超过则占 2 格，否则占 1 格（每行 3 格）
const int kKaomojiLongThreshold = 10;

/// 将颜文字列表按每行 3 格打包成行，每项占 1 或 2 格（按长度）
List<List<({String item, int span})>> _packKaomojiRows(List<String> items) {
  const int unitsPerRow = 3;
  final List<List<({String item, int span})>> rows = [];
  List<({String item, int span})> currentRow = [];
  int currentUnits = 0;

  for (final item in items) {
    final span = item.length >= kKaomojiLongThreshold ? 2 : 1;
    if (currentUnits + span > unitsPerRow && currentRow.isNotEmpty) {
      rows.add(List.from(currentRow));
      currentRow = [];
      currentUnits = 0;
    }
    currentRow.add((item: item, span: span));
    currentUnits += span;
  }
  if (currentRow.isNotEmpty) rows.add(currentRow);
  return rows;
}

/// 表情内容网格：展示颜文字/Emoji 列表
/// 颜文字：短占 1 格、长占 2 格，每行 3 格自动换行；Emoji：固定 6 列
class EmojiGridContent extends StatelessWidget {
  final List<String> items;
  final bool isEmoji;
  final ValueChanged<String> onItemSelected;
  final double height;

  const EmojiGridContent({
    super.key,
    required this.items,
    required this.isEmoji,
    required this.onItemSelected,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerBg =
        isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: isEmoji ? _buildEmojiGrid(context) : _buildKaomojiGrid(context),
      ),
    );
  }

  Widget _buildEmojiGrid(BuildContext context) {
    const crossAxisCount = 6;
    final totalRows = (items.length + crossAxisCount - 1) ~/ crossAxisCount;

    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.0,
        crossAxisSpacing: 0,
        mainAxisSpacing: 0,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final column = index % crossAxisCount;
        final row = index ~/ crossAxisCount;
        return _EmojiCell(
          content: item,
          isEmoji: true,
          span: 1,
          showRightDivider: column < crossAxisCount - 1,
          showBottomDivider: row < totalRows - 1,
          onTap: () => onItemSelected(item),
        );
      },
    );
  }

  static const double _kaomojiRowHeight = 44.0;

  Widget _buildKaomojiGrid(BuildContext context) {
    final rows = _packKaomojiRows(items);
    return ListView.builder(
      padding: EdgeInsets.zero,
      physics: const ClampingScrollPhysics(),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        final isLastRow = index == rows.length - 1;
        return SizedBox(
          height: _kaomojiRowHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < row.length; i++)
                Expanded(
                  flex: row[i].span,
                  child: _EmojiCell(
                    content: row[i].item,
                    isEmoji: false,
                    span: row[i].span,
                    showRightDivider: i < row.length - 1,
                    showBottomDivider: !isLastRow,
                    onTap: () => onItemSelected(row[i].item),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ========== 可复用表情选择面板==========

/// 可复用的颜文字/Emoji 选择面板（两级 SegmentedControl + 表情内容网格）
/// 用于评论输入、消息界面等，统一数据与样式，便于维护。
class EmojiSelectorPanel extends StatefulWidget {
  final ValueChanged<String> onEmojiSelected;

  /// 选中后是否触发关闭（如评论里选中即关 overlay，消息里可选关）
  final VoidCallback? onClose;

  const EmojiSelectorPanel({
    super.key,
    required this.onEmojiSelected,
    this.onClose,
  });

  @override
  State<EmojiSelectorPanel> createState() => _EmojiSelectorPanelState();
}

class _EmojiSelectorPanelState extends State<EmojiSelectorPanel> {
  /// 0..6 = 颜文字小类，7 = Emoji
  static const int _emojiPageIndex = 7;

  late PageController _pageController;
  int _currentPage = 0;

  String get _emojiMainCategory =>
      _currentPage < _emojiPageIndex ? 'kaomoji' : 'emoji';
  String get _kaomojiSubCategory =>
      kKaomojiSubKeys[_currentPage.clamp(0, kKaomojiSubKeys.length - 1)];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSelect(String emoji) {
    widget.onEmojiSelected(emoji);
    widget.onClose?.call();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  @override
  Widget build(BuildContext context) {
    final isEmoji = _currentPage == _emojiPageIndex;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedControl<String>(
            segments: const ['kaomoji', 'emoji'],
            selectedSegment: _emojiMainCategory,
            onSegmentChanged: (v) {
              final index = v == 'emoji'
                  ? _emojiPageIndex
                  : (_currentPage < _emojiPageIndex ? _currentPage : 0);
              setState(() => _currentPage = index);
              _pageController.jumpToPage(index);
            },
            labelBuilder: (v) => v == 'kaomoji' ? '颜文字' : 'Emoji',
            height: 28,
            fontSize: 12,
          ),
          const SizedBox(height: 10),
          if (!isEmoji) ...[
            SegmentedControl<String>(
              segments: kKaomojiSubKeys,
              selectedSegment: _kaomojiSubCategory,
              onSegmentChanged: (v) {
                final index = kKaomojiSubKeys.indexOf(v);
                if (index >= 0) {
                  setState(() => _currentPage = index);
                  _pageController.jumpToPage(index);
                }
              },
              labelBuilder: (k) => kEmojiTabLabels[k]!,
              height: 26,
              fontSize: 11,
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            height: 160,
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: [
                for (int i = 0; i < kKaomojiSubKeys.length; i++)
                  EmojiGridContent(
                    items: kKaomojis[kKaomojiSubKeys[i]]!,
                    isEmoji: false,
                    onItemSelected: _onSelect,
                  ),
                EmojiGridContent(
                  items: kKaomojis['emoji']!,
                  isEmoji: true,
                  onItemSelected: _onSelect,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ========== 对外使用的颜文字/表情选择器==========

/// 颜文字/表情选择器组件（内部使用 [EmojiSelectorPanel]）
class EmojiPicker extends StatelessWidget {
  final Function(String) onEmojiSelected;
  final VoidCallback? onClose;

  const EmojiPicker({
    super.key,
    required this.onEmojiSelected,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return EmojiSelectorPanel(
      onEmojiSelected: onEmojiSelected,
      onClose: onClose,
    );
  }
}

/// 表情选择器按钮组件 - 用于在输入框旁边显示
class EmojiPickerButton extends StatefulWidget {
  final TextEditingController controller;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const EmojiPickerButton({
    super.key,
    required this.controller,
    this.size = 32,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<EmojiPickerButton> createState() => _EmojiPickerButtonState();
}

class _EmojiPickerButtonState extends State<EmojiPickerButton> {
  final GlobalKey _buttonKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _removeOverlay();
    super.dispose();
  }

  /// 仅移除 overlay，不调用 setState
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    if (_isDisposed) return;
    _removeOverlay();

    final RenderBox? renderBox =
        _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // 点击外部关闭
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideOverlay,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          // 表情选择器
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).size.height - position.dy + 8,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: EmojiPicker(
                onEmojiSelected: _insertEmoji,
                onClose: _hideOverlay,
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {});
  }

  void _hideOverlay() {
    _removeOverlay();
    if (!_isDisposed && mounted) setState(() {});
  }

  void _toggleOverlay() {
    if (_overlayEntry != null) {
      _hideOverlay();
    } else {
      _showOverlay();
    }
  }

  void _insertEmoji(String emoji) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;

    final newText = text.replaceRange(start, end, emoji);
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: start + emoji.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _overlayEntry != null;
    return Container(
      key: _buttonKey,
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(widget.size / 2),
        border: Border.all(
          color: context.dividerColor,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: _toggleOverlay,
        icon: Icon(Icons.emoji_emotions_outlined, size: widget.size * 0.5),
        color: isActive
            ? (widget.activeColor ?? AppColors.primary)
            : (widget.inactiveColor ?? context.textSecondaryColor),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }
}
