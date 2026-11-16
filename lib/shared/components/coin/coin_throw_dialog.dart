import 'package:flutter/material.dart';

import 'package:sse_market_x/core/api/api_service.dart';
import 'package:sse_market_x/core/models/coin_model.dart';
import 'package:sse_market_x/shared/components/utils/snackbar_helper.dart';
import 'package:sse_market_x/shared/theme/app_colors.dart';

/// B 站式投币弹窗：1 币 / 2 币卡片、显示余额、可取消投币。
class CoinThrowDialog extends StatefulWidget {
  final ApiService apiService;
  final String targetType;
  final int targetID;
  final int myCoins;
  final int coinCount;
  final void Function(CoinThrowResult result, {required bool cancelled})
      onChanged;

  const CoinThrowDialog({
    super.key,
    required this.apiService,
    required this.targetType,
    required this.targetID,
    required this.myCoins,
    required this.coinCount,
    required this.onChanged,
  });

  @override
  State<CoinThrowDialog> createState() => _CoinThrowDialogState();
}

class _CoinThrowDialogState extends State<CoinThrowDialog> {
  CoinSummary? _summary;
  bool _loading = true;
  bool _submitting = false;
  int _selected = 1;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final summary = await widget.apiService.getCoinSummary();
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _loading = false;
      final remaining = (2 - widget.myCoins).clamp(0, 2);
      _selected = remaining >= 2 ? 2 : (remaining == 1 ? 1 : 0);
    });
  }

  Future<void> _throw() async {
    if (_submitting) return;
    if (_selected <= 0) return;
    setState(() => _submitting = true);
    final outcome = await widget.apiService.throwCoin(
      targetType: widget.targetType,
      targetID: widget.targetID,
      coins: _selected,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    final result = outcome.result;
    if (outcome.ok && result != null) {
      widget.onChanged(result, cancelled: false);
      if (mounted) Navigator.of(context).pop();
    } else {
      SnackBarHelper.show(context, outcome.msg);
    }
  }

  Future<void> _cancel() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final outcome = await widget.apiService.cancelCoin(
      targetType: widget.targetType,
      targetID: widget.targetID,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    final result = outcome.result;
    if (outcome.ok && result != null) {
      widget.onChanged(result, cancelled: true);
      if (mounted) Navigator.of(context).pop();
    } else {
      SnackBarHelper.show(context, outcome.msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final coins = _summary?.coins ?? 0;
    final maxSelectable = (2 - widget.myCoins).clamp(0, 2);

    return Dialog(
      backgroundColor: context.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.monetization_on_rounded,
                    color: Color(0xFFFFB020), size: 22),
                const SizedBox(width: 6),
                Text(
                  '投币',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimaryColor,
                  ),
                ),
                const Spacer(),
                if (_loading)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.8),
                  )
                else
                  Text(
                    '余额 ${coins.toStringAsFixed(coins == coins.roundToDouble() ? 0 : 2)} 币',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textSecondaryColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              widget.myCoins > 0
                  ? '你已投 ${widget.myCoins} 币，每人每个内容最多 2 币'
                  : '每个内容最多投 2 币，投 1 币自己 +10 经验',
              style: TextStyle(fontSize: 12, color: context.textTertiaryColor),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _buildCoinCard(1, maxSelectable >= 1),
                const SizedBox(width: 12),
                _buildCoinCard(2, maxSelectable >= 2),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                if (widget.myCoins > 0)
                  TextButton(
                    onPressed: _submitting ? null : _cancel,
                    child: const Text('取消投币'),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('关闭'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed:
                      _submitting || _selected <= 0 || _selected > maxSelectable
                          ? null
                          : _throw,
                  child: Text(_submitting ? '处理中...' : '确定投 $_selected 币'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoinCard(int value, bool enabled) {
    final selected = _selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: enabled ? () => setState(() => _selected = value) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFFFF4D6)
                : context.backgroundColor.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFFFFB020)
                  : context.dividerColor.withOpacity(0.7),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.monetization_on_rounded,
                size: 30,
                color: enabled
                    ? const Color(0xFFFFB020)
                    : context.textTertiaryColor,
              ),
              const SizedBox(height: 6),
              Text(
                '$value 币',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: enabled
                      ? context.textPrimaryColor
                      : context.textTertiaryColor,
                ),
              ),
              if (!enabled) ...[
                const SizedBox(height: 2),
                Text(
                  '已达上限',
                  style: TextStyle(
                    fontSize: 10,
                    color: context.textTertiaryColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
