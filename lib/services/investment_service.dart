import 'package:flutter/foundation.dart';
import 'package:student_fin_os/models/investment_holding.dart';
import 'package:student_fin_os/services/in_memory_db.dart';
import 'package:student_fin_os/services/lambda_api_service.dart';

class InvestmentService {
  InvestmentService(this._apiService);

  final LambdaApiService _apiService;

  Stream<List<InvestmentHolding>> watchInvestments(String userId) async* {
    if (!_apiService.isConfigured) {
      yield InMemoryDb.investments;
      return;
    }

    try {
      final dynamic response = await _apiService.get('/investments?userId=$userId');
      if (response is List) {
        final List<InvestmentHolding> holdings = response
            .map((dynamic e) => InvestmentHolding.fromJson(e as Map<String, dynamic>))
            .toList();
        yield holdings;
      } else {
        yield InMemoryDb.investments;
      }
    } catch (e) {
      debugPrint('[InvestmentService] API watchInvestments error: $e');
      yield InMemoryDb.investments;
    }
  }

  Future<void> upsertInvestment(InvestmentHolding holding) async {
    final int idx = InMemoryDb.investments.indexWhere((InvestmentHolding h) => h.id == holding.id);
    if (idx != -1) {
      InMemoryDb.investments[idx] = holding;
    } else {
      InMemoryDb.investments.add(holding);
    }

    if (_apiService.isConfigured) {
      try {
        await _apiService.post('/investments', holding.toJson());
      } catch (e) {
        debugPrint('[InvestmentService] API upsertInvestment error: $e');
      }
    }
  }

  Future<void> deleteInvestment({
    required String userId,
    required String holdingId,
  }) async {
    InMemoryDb.investments.removeWhere((InvestmentHolding h) => h.id == holdingId);

    if (_apiService.isConfigured) {
      try {
        await _apiService.post('/investments/delete', <String, dynamic>{
          'userId': userId,
          'holdingId': holdingId,
        });
      } catch (e) {
        debugPrint('[InvestmentService] API deleteInvestment error: $e');
      }
    }
  }
}
