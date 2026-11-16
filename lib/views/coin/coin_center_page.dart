import 'package:flutter/material.dart';

import 'package:sse_market_x/core/api/api_service.dart';
import 'package:sse_market_x/core/models/coin_model.dart';
import 'package:sse_market_x/shared/theme/app_colors.dart';

/// 币中心：余额、今日任务、投币/收币统计、流水。
class CoinCenterPage extends StatefulWidget {
  final ApiService apiService;

  const CoinCenterPage({super.key, required this.apiService});

  @override
  State<CoinCenterPage> createState() => _CoinCenterPageState();
}

class _CoinCenterPageState extends State<CoinCenterPage> {
  CoinSummary? _summary;
  List<CoinLedgerItem> _ledger = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      widget.apiService.getCoinSummary(),
      widget.apiService.getCoinLedger(limit: 30),
    ]);
    if (!mounted) return;
    setState(() {
      _summary = results[0] as CoinSummary?;
      _ledger = (results[1] as ({List<CoinLedgerItem> items, int total})).items;
      _loading = false;
    });
  }

  String _formatAmount(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '币中心',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.textPrimaryColor,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: _loading
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  _buildBalanceCard(),
                  const SizedBox(height: 14),
                  _buildStatsCard(),
                  const SizedBox(height: 14),
                  _buildTasksCard(),
                  const SizedBox(height: 14),
                  _buildLedgerCard(),
                ],
              ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    final coins = _summary?.coins ?? 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF4D6), Color(0xFFFFE3A3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monetization_on_rounded,
                  color: Color(0xFFB7791F), size: 22),
              const SizedBox(width: 6),
              const Text(
                '我的币',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF92400E),
                ),
              ),
              const Spacer(),
              Text(
                _summary?.day ?? '',
                style: const TextStyle(fontSize: 11, color: Color(0xFFB7791F)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _formatAmount(coins),
            style: const TextStyle(
              fontSize: 40,
              height: 1.05,
              fontWeight: FontWeight.w800,
              color: Color(0xFF7C2D12),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '投 1 币，自己 +10 主页经验；每人每个内容最多 2 币',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF92400E)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final summary = _summary ?? CoinSummary.empty();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildStat('累计投出', '${summary.thrownTotal} 币'),
          _buildDivider(),
          _buildStat('投币经验', '+${summary.thrownExp}'),
          _buildDivider(),
          _buildStat('累计收到', _formatAmount(summary.received)),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: context.textTertiaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 26, color: context.dividerColor);
  }

  Widget _buildTasksCard() {
    final tasks = _summary?.tasks ?? const <CoinTask>[];
    return _card(
      title: '今日任务',
      child: tasks.isEmpty
          ? Text(
              '暂无任务',
              style: TextStyle(fontSize: 12, color: context.textTertiaryColor),
            )
          : Column(
              children: tasks
                  .map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  task.label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: context.textPrimaryColor,
                                  ),
                                ),
                              ),
                              Text(
                                task.done ? '已领取' : '+${task.reward} 币',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: task.done
                                      ? context.textTertiaryColor
                                      : const Color(0xFFB7791F),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: task.done ? 1 : task.progressRatio,
                              minHeight: 5,
                              backgroundColor:
                                  context.dividerColor.withOpacity(0.35),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFFFB020),
                              ),
                            ),
                          ),
                          if (task.target > 0) ...[
                            const SizedBox(height: 3),
                            Text(
                              '${task.progress}/${task.target}',
                              style: TextStyle(
                                fontSize: 10,
                                color: context.textTertiaryColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }

  Widget _buildLedgerCard() {
    return _card(
      title: '币流水',
      child: _ledger.isEmpty
          ? Text(
              '还没有流水',
              style: TextStyle(fontSize: 12, color: context.textTertiaryColor),
            )
          : Column(
              children: _ledger
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.label.isEmpty ? item.event : item.label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: context.textPrimaryColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.createdAt
                                      .replaceFirst('T', ' ')
                                      .split('+')
                                      .first,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: context.textTertiaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${item.amount > 0 ? '+' : ''}${item.amount}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: item.amount >= 0
                                  ? const Color(0xFFB7791F)
                                  : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
