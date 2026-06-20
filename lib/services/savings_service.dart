import 'package:flutter/foundation.dart';
import 'package:student_fin_os/models/finance_enums.dart';
import 'package:student_fin_os/models/savings_goal.dart';
import 'package:student_fin_os/services/in_memory_db.dart';
import 'package:student_fin_os/services/lambda_api_service.dart';

class SavingsService {
  SavingsService(this._apiService);

  final LambdaApiService _apiService;

  Stream<List<SavingsGoal>> watchGoals(String userId) async* {
    if (!_apiService.isConfigured) {
      final List<SavingsGoal> list = InMemoryDb.goals
          .where((SavingsGoal g) => g.userId == userId)
          .toList()
        ..sort((SavingsGoal a, SavingsGoal b) {
          final int p = a.priority.compareTo(b.priority);
          if (p != 0) return p;
          return a.deadline.compareTo(b.deadline);
        });
      yield list;
      return;
    }

    try {
      final dynamic response = await _apiService.get('/goals?userId=$userId');
      if (response is List) {
        final List<SavingsGoal> list = response
            .map((dynamic e) => SavingsGoal.fromMap(e['id'] ?? e['goalId'] ?? '', e as Map<String, dynamic>))
            .toList();
        yield list;
      } else {
        yield <SavingsGoal>[];
      }
    } catch (e) {
      debugPrint('[SavingsService] API watchGoals error: $e');
      final List<SavingsGoal> list = InMemoryDb.goals
          .where((SavingsGoal g) => g.userId == userId)
          .toList()
        ..sort((SavingsGoal a, SavingsGoal b) {
          final int p = a.priority.compareTo(b.priority);
          if (p != 0) return p;
          return a.deadline.compareTo(b.deadline);
        });
      yield list;
    }
  }

  Future<void> upsertGoal(SavingsGoal goal) async {
    final int idx = InMemoryDb.goals.indexWhere((SavingsGoal g) => g.id == goal.id);
    if (idx != -1) {
      InMemoryDb.goals[idx] = goal;
    } else {
      InMemoryDb.goals.add(goal);
    }

    if (_apiService.isConfigured) {
      try {
        await _apiService.post('/goals', goal.toMap());
      } catch (e) {
        debugPrint('[SavingsService] API upsertGoal error: $e');
      }
    }
  }

  Future<void> contributeToGoal({
    required String userId,
    required String goalId,
    required double amount,
  }) async {
    final int idx = InMemoryDb.goals.indexWhere((SavingsGoal g) => g.id == goalId);
    if (idx != -1) {
      final SavingsGoal goal = InMemoryDb.goals[idx];
      final double updatedSavedAmount = goal.savedAmount + amount;
      final GoalStatus status = updatedSavedAmount >= goal.targetAmount
          ? GoalStatus.achieved
          : GoalStatus.active;
      InMemoryDb.goals[idx] = SavingsGoal(
        id: goal.id,
        userId: goal.userId,
        title: goal.title,
        targetAmount: goal.targetAmount,
        savedAmount: updatedSavedAmount,
        deadline: goal.deadline,
        priority: goal.priority,
        status: status,
        createdAt: goal.createdAt,
        updatedAt: DateTime.now().toUtc(),
      );
    }

    if (_apiService.isConfigured) {
      try {
        await _apiService.post('/goals/contribute', <String, dynamic>{
          'userId': userId,
          'goalId': goalId,
          'amount': amount,
        });
      } catch (e) {
        debugPrint('[SavingsService] API contributeToGoal error: $e');
      }
    }
  }

  double recommendedMonthlyContribution(SavingsGoal goal) {
    final DateTime now = DateTime.now().toUtc();
    final int monthsLeft =
        (goal.deadline.difference(now).inDays / 30).ceil().clamp(1, 120);
    final double pending = (goal.targetAmount - goal.savedAmount).clamp(0, 1e12);
    return pending / monthsLeft;
  }

  double calculateSafeToSpend({
    required double totalBalance,
    required double weeklyExpectedSpend,
    required double monthlyGoalContribution,
  }) {
    final double reserve = weeklyExpectedSpend * 1.4;
    final double safe = totalBalance - reserve - monthlyGoalContribution;
    return safe < 0 ? 0 : safe;
  }
}
