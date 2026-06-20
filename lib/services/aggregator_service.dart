import 'dart:async';
import 'package:student_fin_os/models/account.dart';
import 'package:student_fin_os/models/account_aggregation_snapshot.dart';
import 'package:student_fin_os/models/finance_transaction.dart';
import 'package:student_fin_os/services/account_service.dart';
import 'package:student_fin_os/services/transaction_service.dart';

class AggregatorService {
  AggregatorService(this._accountService, this._transactionService);

  final AccountService _accountService;
  final TransactionService _transactionService;

  Stream<AccountAggregationSnapshot> watchUnifiedSnapshot(
    String userId, {
    int transactionLimit = 150,
  }) {
    final Stream<List<Account>> accountsStream = _accountService.watchAccounts(userId);
    final Stream<List<FinanceTransaction>> transactionsStream =
        _transactionService.watchTransactions(userId, limit: transactionLimit);

    return Stream<AccountAggregationSnapshot>.multi((
      MultiStreamController<AccountAggregationSnapshot> controller,
    ) {
      List<Account> accounts = const <Account>[];
      List<FinanceTransaction> transactions = const <FinanceTransaction>[];

      void emit() {
        controller.add(
          AccountAggregationSnapshot.fromData(
            accounts: accounts,
            transactions: transactions,
          ),
        );
      }

      final StreamSubscription<List<Account>> accountSub =
          accountsStream.listen((List<Account> nextAccounts) {
        accounts = nextAccounts;
        emit();
      }, onError: controller.addError);

      final StreamSubscription<List<FinanceTransaction>> txSub =
          transactionsStream.listen((List<FinanceTransaction> nextTransactions) {
        transactions = nextTransactions;
        emit();
      }, onError: controller.addError);

      controller.onCancel = () async {
        await accountSub.cancel();
        await txSub.cancel();
      };
    });
  }
}
