/// 站内币体系模型（对齐 web `src/api/coin/coin.ts`）。
class CoinTask {
  final String event;
  final String label;
  final int target;
  final int progress;
  final int reward;
  final bool done;
  final bool available;

  const CoinTask({
    required this.event,
    required this.label,
    required this.target,
    required this.progress,
    required this.reward,
    required this.done,
    required this.available,
  });

  double get progressRatio =>
      target <= 0 ? 0.0 : (progress / target).clamp(0.0, 1.0);

  factory CoinTask.fromDynamic(dynamic raw) {
    if (raw is! Map) return CoinTask.empty;
    return CoinTask(
      event: raw['event']?.toString() ?? '',
      label: raw['label']?.toString() ?? '',
      target: _int(raw['target']),
      progress: _int(raw['progress']),
      reward: _int(raw['reward']),
      done: raw['done'] == true,
      available: raw['available'] == true,
    );
  }

  static const CoinTask empty = CoinTask(
    event: '',
    label: '',
    target: 0,
    progress: 0,
    reward: 0,
    done: false,
    available: false,
  );
}

class CoinSummary {
  final double coins;
  final String day;
  final List<CoinTask> tasks;
  final int thrownTotal;
  final int thrownExp;
  final double received;

  const CoinSummary({
    required this.coins,
    required this.day,
    required this.tasks,
    required this.thrownTotal,
    required this.thrownExp,
    required this.received,
  });

  factory CoinSummary.empty() => const CoinSummary(
        coins: 0,
        day: '',
        tasks: <CoinTask>[],
        thrownTotal: 0,
        thrownExp: 0,
        received: 0,
      );

  factory CoinSummary.fromDynamic(dynamic raw) {
    if (raw is! Map) return CoinSummary.empty();
    final tasksRaw = raw['tasks'];
    return CoinSummary(
      coins: _double(raw['coins']),
      day: raw['day']?.toString() ?? '',
      tasks: tasksRaw is List
          ? tasksRaw.map(CoinTask.fromDynamic).toList(growable: false)
          : const <CoinTask>[],
      thrownTotal: _int(raw['thrownTotal']),
      thrownExp: _int(raw['thrownExp']),
      received: _double(raw['received']),
    );
  }
}

class CoinLedgerItem {
  final int ledgerID;
  final String targetType;
  final int targetID;
  final String event;
  final String label;
  final int amount;
  final String createdAt;

  const CoinLedgerItem({
    required this.ledgerID,
    required this.targetType,
    required this.targetID,
    required this.event,
    required this.label,
    required this.amount,
    required this.createdAt,
  });

  factory CoinLedgerItem.fromDynamic(dynamic raw) {
    if (raw is! Map) {
      return const CoinLedgerItem(
        ledgerID: 0,
        targetType: '',
        targetID: 0,
        event: '',
        label: '',
        amount: 0,
        createdAt: '',
      );
    }
    return CoinLedgerItem(
      ledgerID: _int(raw['ledgerID']),
      targetType: raw['targetType']?.toString() ?? '',
      targetID: _int(raw['targetID']),
      event: raw['event']?.toString() ?? '',
      label: raw['label']?.toString() ?? '',
      amount: _int(raw['amount']),
      createdAt: raw['createdAt']?.toString() ?? '',
    );
  }
}

class CoinThrowResult {
  final double coins;
  final int total;
  final int exp;
  final double coinsLeft;
  final String targetType;
  final int targetID;

  const CoinThrowResult({
    required this.coins,
    required this.total,
    required this.exp,
    required this.coinsLeft,
    required this.targetType,
    required this.targetID,
  });

  factory CoinThrowResult.fromDynamic(dynamic raw) {
    if (raw is! Map) {
      return const CoinThrowResult(
        coins: 0,
        total: 0,
        exp: 0,
        coinsLeft: 0,
        targetType: '',
        targetID: 0,
      );
    }
    return CoinThrowResult(
      coins: _double(raw['coins']),
      total: _int(raw['total']),
      exp: _int(raw['exp']),
      coinsLeft: _double(raw['coinsLeft']),
      targetType: raw['targetType']?.toString() ?? '',
      targetID: _int(raw['targetID']),
    );
  }
}

class CoinActionOutcome {
  final bool ok;
  final String msg;
  final CoinThrowResult? result;

  const CoinActionOutcome({
    required this.ok,
    required this.msg,
    this.result,
  });
}

int _int(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

double _double(dynamic v) {
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0.0;
}
