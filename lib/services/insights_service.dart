import 'package:flutter/foundation.dart';
import 'package:student_fin_os/models/ai_insight.dart';
import 'package:student_fin_os/models/finance_enums.dart';
import 'package:student_fin_os/models/finance_transaction.dart';
import 'package:student_fin_os/services/in_memory_db.dart';
import 'package:student_fin_os/services/lambda_api_service.dart';
import 'package:uuid/uuid.dart';

class InsightsService {
  InsightsService(this._apiService, this._uuid);

  final LambdaApiService _apiService;
  final Uuid _uuid;

  Stream<List<AiInsight>> watchInsights(String userId) async* {
    if (!_apiService.isConfigured) {
      final List<AiInsight> list = InMemoryDb.insights
          .where((AiInsight ins) => ins.userId == userId)
          .toList()
        ..sort((AiInsight a, AiInsight b) => b.createdAt.compareTo(a.createdAt));
      yield list.take(30).toList();
      return;
    }

    try {
      final dynamic response = await _apiService.get('/insights?userId=$userId');
      if (response is List) {
        final List<AiInsight> list = response
            .map((dynamic e) => AiInsight.fromMap(e['id'] ?? e['insightId'] ?? '', e as Map<String, dynamic>))
            .toList();
        yield list;
      } else {
        yield <AiInsight>[];
      }
    } catch (e) {
      debugPrint('[InsightsService] API watchInsights error: $e');
      final List<AiInsight> list = InMemoryDb.insights
          .where((AiInsight ins) => ins.userId == userId)
          .toList()
        ..sort((AiInsight a, AiInsight b) => b.createdAt.compareTo(a.createdAt));
      yield list.take(30).toList();
    }
  }

  Future<void> persistInsights(String userId, List<AiInsight> items) async {
    if (items.isEmpty) {
      return;
    }

    for (final AiInsight insight in items) {
      InMemoryDb.insights.removeWhere((AiInsight ins) => ins.id == insight.id);
      InMemoryDb.insights.add(insight);
    }

    if (_apiService.isConfigured) {
      try {
        final List<Map<String, dynamic>> payload = items.map((AiInsight i) => i.toMap()).toList();
        await _apiService.post('/insights', <String, dynamic>{
          'userId': userId,
          'insights': payload,
        });
      } catch (e) {
        debugPrint('[InsightsService] API persistInsights error: $e');
      }
    }
  }

  List<AiInsight> generateRuleBasedInsights({
    required String userId,
    required List<FinanceTransaction> recentTransactions,
    required double totalBalance,
    required double safeToSpend,
  }) {
    final DateTime now = DateTime.now().toUtc();
    final List<FinanceTransaction> expenses = recentTransactions
        .where((FinanceTransaction tx) => tx.type == TransactionType.expense)
        .toList();

    final List<AiInsight> insights = <AiInsight>[];

    final double weeklyExpense = _sumAmount(
      expenses.where((FinanceTransaction tx) {
        return now.difference(tx.transactionAt).inDays <= 7;
      }).toList(),
    );

    final double previousWeekExpense = _sumAmount(
      expenses.where((FinanceTransaction tx) {
        final int days = now.difference(tx.transactionAt).inDays;
        return days > 7 && days <= 14;
      }).toList(),
    );

    if (previousWeekExpense > 0 && weeklyExpense > previousWeekExpense * 1.25) {
      insights.add(_build(
        userId: userId,
        title: 'You are spending faster this week',
        message:
            'Your spend is ${((weeklyExpense / previousWeekExpense) * 100).round()}% of last week. Try a short no-spend streak on non-essentials.',
        severity: InsightSeverity.warning,
      ));
    }

    final double foodExpense = _sumAmount(
      expenses
          .where((FinanceTransaction tx) =>
              tx.category.toLowerCase() == 'food' ||
              tx.category.toLowerCase() == 'eating out')
          .toList(),
    );

    if (weeklyExpense > 0 && foodExpense / weeklyExpense > 0.45) {
      insights.add(_build(
        userId: userId,
        title: 'Food is taking a big share',
        message:
            'Food is ${((foodExpense / weeklyExpense) * 100).round()}% of weekly spend. 1-2 home-cooked days can lower this quickly.',
        severity: InsightSeverity.info,
      ));
    }

    if (safeToSpend < totalBalance * 0.15) {
      insights.add(_build(
        userId: userId,
        title: 'Your safe-to-spend is low',
        message:
            'You are close to your safety buffer. Keep spending to essentials until next income.',
        severity: InsightSeverity.critical,
      ));
    }

    final DateTime monthStart = DateTime.utc(now.year, now.month, 1);
    final DateTime previousMonthStart = DateTime.utc(now.year, now.month - 1, 1);
    final DateTime previousMonthEnd = monthStart.subtract(const Duration(days: 1));

    final double currentMonthFood = _sumAmount(
      expenses.where((FinanceTransaction tx) {
        return (tx.transactionAt.isAfter(monthStart) ||
                tx.transactionAt.isAtSameMomentAs(monthStart)) &&
            tx.category.toLowerCase() == 'food';
      }).toList(),
    );

    final double previousMonthFood = _sumAmount(
      expenses.where((FinanceTransaction tx) {
        final DateTime date = tx.transactionAt;
        return (date.isAfter(previousMonthStart) || date.isAtSameMomentAs(previousMonthStart)) &&
            (date.isBefore(previousMonthEnd) || date.isAtSameMomentAs(previousMonthEnd)) &&
            tx.category.toLowerCase() == 'food';
      }).toList(),
    );

    if (previousMonthFood > 0 && currentMonthFood > previousMonthFood * 1.3) {
      insights.add(_build(
        userId: userId,
        title: 'Food spending jumped this month',
        message:
            'You spent ${((currentMonthFood - previousMonthFood) / previousMonthFood * 100).round()}% more on food vs last month.',
        severity: InsightSeverity.warning,
      ));
    }

    final double recent14DayExpense = _sumAmount(
      expenses.where((FinanceTransaction tx) {
        return now.difference(tx.transactionAt).inDays <= 14;
      }).toList(),
    );
    final double dailyRunRate = recent14DayExpense / 14;
    if (dailyRunRate > 0) {
      final int projectedDays = (totalBalance / dailyRunRate).floor();
      if (projectedDays <= 5) {
        insights.add(_build(
          userId: userId,
          title: 'Your balance may get tight soon',
          message: 'At this pace, funds may run low in about $projectedDays days. Slow spending this week if possible.',
          severity: InsightSeverity.critical,
        ));
      }
    }

    final bool noIncomeInTwoWeeks = recentTransactions.where((FinanceTransaction tx) {
      return tx.type == TransactionType.income &&
          now.difference(tx.transactionAt).inDays <= 14;
    }).isEmpty;

    if (noIncomeInTwoWeeks) {
      insights.add(_build(
        userId: userId,
        title: 'No income seen in 14 days',
        message:
            'No income landed in the last 14 days. Keep your plan conservative until next credit.',
        severity: InsightSeverity.warning,
      ));
    }

    final DateTime currentMonthStart = DateTime.utc(now.year, now.month, 1);
    final List<FinanceTransaction> currentMonthTransactions = recentTransactions
        .where((FinanceTransaction tx) {
        return tx.transactionAt.isAfter(currentMonthStart) ||
          tx.transactionAt.isAtSameMomentAs(currentMonthStart);
        })
        .toList(growable: false);

    final double currentMonthIncome = _sumAmount(
      currentMonthTransactions
          .where((FinanceTransaction tx) => tx.type == TransactionType.income)
          .toList(growable: false),
    );
    final double currentMonthExpense = _sumAmount(
      currentMonthTransactions
          .where((FinanceTransaction tx) => tx.type == TransactionType.expense)
          .toList(growable: false),
    );

    if (currentMonthIncome > 0) {
      final double monthlyNet = currentMonthIncome - currentMonthExpense;
      if (monthlyNet > 0) {
        final double suggestedSip = (monthlyNet * 0.2).clamp(500, monthlyNet).toDouble();
        final double suggestedReserve =
            (monthlyNet * 0.3).clamp(500, monthlyNet).toDouble();

        insights.add(_build(
          userId: userId,
          title: 'Monthly surplus available',
          message:
              'You have a surplus of Rs ${monthlyNet.toStringAsFixed(0)} this month. A good split is SIP Rs ${suggestedSip.toStringAsFixed(0)} and reserve Rs ${suggestedReserve.toStringAsFixed(0)}.',
          severity: InsightSeverity.info,
        ));

        insights.add(_build(
          userId: userId,
          title: 'SIP suggestion from your cashflow',
          message:
              'Based on your current month pattern, consider starting a SIP near Rs ${suggestedSip.toStringAsFixed(0)} and increase by 10% every 6 months.',
          severity: InsightSeverity.info,
        ));
      } else {
        insights.add(_build(
          userId: userId,
          title: 'No monthly surplus yet',
          message:
              'Current month spend is above or close to income. Reduce optional categories first, then start a small SIP plan.',
          severity: InsightSeverity.warning,
        ));
      }
    }

    if (safeToSpend > 0) {
      final double suggestedDailyCap = (safeToSpend / 7).clamp(50, safeToSpend).toDouble();
      insights.add(_build(
        userId: userId,
        title: 'Weekly spending cap suggestion',
        message:
            'To stay safe this week, keep non-essential spend near Rs ${suggestedDailyCap.toStringAsFixed(0)} per day.',
        severity: InsightSeverity.info,
      ));
    }

    return insights.take(10).toList(growable: false);
  }

  AiInsight _build({
    required String userId,
    required String title,
    required String message,
    required InsightSeverity severity,
  }) {
    final String slug = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final String stableId =
      'rule_${severity.name}_${slug.isEmpty ? _uuid.v4() : slug}';

    return AiInsight(
      id: stableId,
      userId: userId,
      title: title,
      message: message,
      severity: severity,
      createdAt: DateTime.now().toUtc(),
      isRead: false,
    );
  }

  double _sumAmount(List<FinanceTransaction> transactions) {
    double total = 0;
    for (final FinanceTransaction tx in transactions) {
      total += tx.amount;
    }
    return total;
  }
}
