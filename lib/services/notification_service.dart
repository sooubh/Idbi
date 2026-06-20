import 'package:flutter/foundation.dart';
import 'package:student_fin_os/services/in_memory_db.dart';
import 'package:student_fin_os/services/lambda_api_service.dart';

class NotificationService {
  NotificationService(this._apiService);

  final LambdaApiService _apiService;

  Future<void> upsertDailyReminder({
    required String userId,
    required bool enabled,
    required String localTime,
  }) async {
    final Map<String, dynamic> data = <String, dynamic>{
      'enabled': enabled,
      'localTime': localTime,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };

    final int idx = InMemoryDb.notifications.indexWhere((Map<String, dynamic> e) => e['id'] == 'daily_spend');
    if (idx != -1) {
      InMemoryDb.notifications[idx] = <String, dynamic>{'id': 'daily_spend', ...data};
    } else {
      InMemoryDb.notifications.add(<String, dynamic>{'id': 'daily_spend', ...data});
    }

    if (_apiService.isConfigured) {
      try {
        await _apiService.post('/preferences/daily-reminder', <String, dynamic>{
          'userId': userId,
          ...data,
        });
      } catch (e) {
        debugPrint('[NotificationService] API upsertDailyReminder error: $e');
      }
    }
  }

  Future<void> upsertBudgetAlert({
    required String userId,
    required bool enabled,
    required double monthlyLimit,
  }) async {
    final Map<String, dynamic> data = <String, dynamic>{
      'enabled': enabled,
      'monthlyLimit': monthlyLimit,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };

    final int idx = InMemoryDb.notifications.indexWhere((Map<String, dynamic> e) => e['id'] == 'budget_alert');
    if (idx != -1) {
      InMemoryDb.notifications[idx] = <String, dynamic>{'id': 'budget_alert', ...data};
    } else {
      InMemoryDb.notifications.add(<String, dynamic>{'id': 'budget_alert', ...data});
    }

    if (_apiService.isConfigured) {
      try {
        await _apiService.post('/preferences/budget-alert', <String, dynamic>{
          'userId': userId,
          ...data,
        });
      } catch (e) {
        debugPrint('[NotificationService] API upsertBudgetAlert error: $e');
      }
    }
  }

  Stream<Map<String, dynamic>> watchPreferences(String userId) async* {
    if (!_apiService.isConfigured) {
      final Map<String, dynamic> result = <String, dynamic>{};
      for (final Map<String, dynamic> e in InMemoryDb.notifications) {
        final String? id = e['id'] as String?;
        if (id != null) {
          result[id] = e;
        }
      }
      yield result;
      return;
    }

    try {
      final dynamic response = await _apiService.get('/preferences?userId=$userId');
      if (response is Map<String, dynamic>) {
        yield response;
      } else {
        yield <String, dynamic>{};
      }
    } catch (e) {
      debugPrint('[NotificationService] API watchPreferences error: $e');
      final Map<String, dynamic> result = <String, dynamic>{};
      for (final Map<String, dynamic> e in InMemoryDb.notifications) {
        final String? id = e['id'] as String?;
        if (id != null) {
          result[id] = e;
        }
      }
      yield result;
    }
  }
}
