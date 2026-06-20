import 'package:flutter/foundation.dart';
import 'package:student_fin_os/models/account.dart';
import 'package:student_fin_os/services/in_memory_db.dart';
import 'package:student_fin_os/services/lambda_api_service.dart';

class AccountService {
  AccountService(this._apiService);

  final LambdaApiService _apiService;

  Stream<List<Account>> watchAccounts(String userId) async* {
    if (!_apiService.isConfigured) {
      yield InMemoryDb.accounts.where((Account a) => a.isActive).toList();
      return;
    }

    try {
      final dynamic response = await _apiService.get('/accounts?userId=$userId');
      if (response is List) {
        final List<Account> accounts = response
            .map((dynamic e) => Account.fromMap(e['id'] ?? e['accountId'] ?? '', e as Map<String, dynamic>))
            .toList();
        yield accounts;
      } else {
        yield InMemoryDb.accounts.where((Account a) => a.isActive).toList();
      }
    } catch (e) {
      debugPrint('[AccountService] API watchAccounts error: $e');
      yield InMemoryDb.accounts.where((Account a) => a.isActive).toList();
    }
  }

  Future<void> upsertAccount(Account account) async {
    final int idx = InMemoryDb.accounts.indexWhere((Account a) => a.id == account.id);
    if (idx != -1) {
      InMemoryDb.accounts[idx] = account;
    } else {
      InMemoryDb.accounts.add(account);
    }

    if (_apiService.isConfigured) {
      try {
        await _apiService.post('/accounts', account.toMap());
      } catch (e) {
        debugPrint('[AccountService] API upsertAccount error: $e');
      }
    }
  }

  Future<void> archiveAccount({
    required String userId,
    required String accountId,
  }) async {
    final int idx = InMemoryDb.accounts.indexWhere((Account a) => a.id == accountId);
    if (idx != -1) {
      final Account account = InMemoryDb.accounts[idx];
      InMemoryDb.accounts[idx] = Account(
        id: account.id,
        userId: account.userId,
        name: account.name,
        type: account.type,
        provider: account.provider,
        balance: account.balance,
        isActive: false,
        icon: account.icon,
        transactionIds: account.transactionIds,
        createdAt: account.createdAt,
        updatedAt: DateTime.now().toUtc(),
      );
    }

    if (_apiService.isConfigured) {
      try {
        await _apiService.post('/accounts/archive', <String, dynamic>{
          'userId': userId,
          'accountId': accountId,
        });
      } catch (e) {
        debugPrint('[AccountService] API archiveAccount error: $e');
      }
    }
  }

  Future<double> getUnifiedBalance(String userId) async {
    if (!_apiService.isConfigured) {
      return InMemoryDb.accounts
          .where((Account a) => a.isActive)
          .fold<double>(0.0, (double sum, Account a) => sum + a.balance);
    }

    try {
      final dynamic response = await _apiService.get('/accounts/unified-balance?userId=$userId');
      if (response is Map<String, dynamic>) {
        return (response['balance'] as num?)?.toDouble() ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      debugPrint('[AccountService] API getUnifiedBalance error: $e');
      return InMemoryDb.accounts
          .where((Account a) => a.isActive)
          .fold<double>(0.0, (double sum, Account a) => sum + a.balance);
    }
  }
}
