import 'package:flutter/foundation.dart';
import 'package:student_fin_os/models/account.dart';
import 'package:student_fin_os/models/finance_enums.dart';
import 'package:student_fin_os/models/finance_transaction.dart';
import 'package:student_fin_os/services/in_memory_db.dart';
import 'package:student_fin_os/services/lambda_api_service.dart';

class TransactionService {
  TransactionService(this._apiService);

  final LambdaApiService _apiService;

  Stream<List<FinanceTransaction>> watchTransactions(
    String userId, {
    int limit = 60,
  }) async* {
    if (!_apiService.isConfigured) {
      final List<FinanceTransaction> list = InMemoryDb.transactions
          .where((FinanceTransaction tx) => tx.userId == userId)
          .toList()
        ..sort((FinanceTransaction a, FinanceTransaction b) => b.transactionAt.compareTo(a.transactionAt));
      yield list.take(limit).toList();
      return;
    }

    try {
      final dynamic response = await _apiService.get('/transactions?userId=$userId&limit=$limit');
      if (response is List) {
        final List<FinanceTransaction> list = response
            .map((dynamic e) => FinanceTransaction.fromMap(e['id'] ?? e['transactionId'] ?? '', e as Map<String, dynamic>))
            .toList();
        yield list;
      } else {
        yield <FinanceTransaction>[];
      }
    } catch (e) {
      debugPrint('[TransactionService] API watchTransactions error: $e');
      final List<FinanceTransaction> list = InMemoryDb.transactions
          .where((FinanceTransaction tx) => tx.userId == userId)
          .toList()
        ..sort((FinanceTransaction a, FinanceTransaction b) => b.transactionAt.compareTo(a.transactionAt));
      yield list.take(limit).toList();
    }
  }

  Future<void> createTransaction(FinanceTransaction tx) async {
    final int accountIdx = InMemoryDb.accounts.indexWhere((Account a) => a.id == tx.accountId);
    if (accountIdx != -1) {
      final Account account = InMemoryDb.accounts[accountIdx];
      final double delta = tx.type == TransactionType.expense ? -tx.amount : tx.amount;
      InMemoryDb.accounts[accountIdx] = Account(
        id: account.id,
        userId: account.userId,
        name: account.name,
        type: account.type,
        provider: account.provider,
        balance: account.balance + delta,
        isActive: account.isActive,
        icon: account.icon,
        transactionIds: <String>[...account.transactionIds, tx.id],
        createdAt: account.createdAt,
        updatedAt: DateTime.now().toUtc(),
      );
    }
    InMemoryDb.transactions.add(tx);

    if (_apiService.isConfigured) {
      try {
        await _apiService.post('/transactions', tx.toMap());
      } catch (e) {
        debugPrint('[TransactionService] API createTransaction error: $e');
      }
    }
  }

  Future<void> deleteTransaction(FinanceTransaction tx) async {
    final int accountIdx = InMemoryDb.accounts.indexWhere((Account a) => a.id == tx.accountId);
    if (accountIdx != -1) {
      final Account account = InMemoryDb.accounts[accountIdx];
      final double delta = tx.type == TransactionType.expense ? tx.amount : -tx.amount;
      final List<String> nextTxIds = List<String>.from(account.transactionIds)..remove(tx.id);
      InMemoryDb.accounts[accountIdx] = Account(
        id: account.id,
        userId: account.userId,
        name: account.name,
        type: account.type,
        provider: account.provider,
        balance: account.balance + delta,
        isActive: account.isActive,
        icon: account.icon,
        transactionIds: nextTxIds,
        createdAt: account.createdAt,
        updatedAt: DateTime.now().toUtc(),
      );
    }
    InMemoryDb.transactions.removeWhere((FinanceTransaction t) => t.id == tx.id);

    if (_apiService.isConfigured) {
      try {
        await _apiService.post('/transactions/delete', <String, dynamic>{
          'userId': tx.userId,
          'transactionId': tx.id,
          'accountId': tx.accountId,
        });
      } catch (e) {
        debugPrint('[TransactionService] API deleteTransaction error: $e');
      }
    }
  }

  Future<void> overrideTransactionCategory({
    required String userId,
    required String transactionId,
    required String category,
  }) async {
    final int idx = InMemoryDb.transactions.indexWhere((FinanceTransaction t) => t.id == transactionId);
    if (idx != -1) {
      final FinanceTransaction tx = InMemoryDb.transactions[idx];
      InMemoryDb.transactions[idx] = FinanceTransaction(
        id: tx.id,
        userId: tx.userId,
        accountId: tx.accountId,
        title: tx.title,
        amount: tx.amount,
        type: tx.type,
        category: category,
        isCategoryOverridden: true,
        source: tx.source,
        channel: tx.channel,
        transactionAt: tx.transactionAt,
        tags: tx.tags,
        note: tx.note,
        createdAt: tx.createdAt,
        updatedAt: DateTime.now().toUtc(),
      );
    }

    if (_apiService.isConfigured) {
      try {
        await _apiService.post('/transactions/override-category', <String, dynamic>{
          'userId': userId,
          'transactionId': transactionId,
          'category': category,
        });
      } catch (e) {
        debugPrint('[TransactionService] API overrideTransactionCategory error: $e');
      }
    }
  }
}
