import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_fin_os/services/account_service.dart';
import 'package:student_fin_os/services/aggregator_service.dart';
import 'package:student_fin_os/services/cognito_auth_service.dart';
import 'package:student_fin_os/services/cash_flow_service.dart';
import 'package:student_fin_os/services/insights_service.dart';
import 'package:student_fin_os/services/lambda_api_service.dart';
import 'package:student_fin_os/services/mock_bank_service.dart';
import 'package:student_fin_os/services/notification_service.dart';
import 'package:student_fin_os/services/savings_service.dart';
import 'package:student_fin_os/services/transaction_service.dart';
import 'package:student_fin_os/services/investment_service.dart';
import 'package:student_fin_os/services/gemini_key_service.dart';
import 'package:uuid/uuid.dart';

final lambdaApiServiceProvider = Provider<LambdaApiService>((Ref ref) {
  return LambdaApiService();
});

final authServiceProvider = Provider<CognitoAuthService>((Ref ref) {
  return CognitoAuthService();
});

final uuidProvider = Provider<Uuid>((Ref ref) {
  return const Uuid();
});

final accountServiceProvider = Provider<AccountService>((Ref ref) {
  return AccountService(ref.watch(lambdaApiServiceProvider));
});

final transactionServiceProvider = Provider<TransactionService>((Ref ref) {
  return TransactionService(ref.watch(lambdaApiServiceProvider));
});

final aggregatorServiceProvider = Provider<AggregatorService>((Ref ref) {
  return AggregatorService(
    ref.watch(accountServiceProvider),
    ref.watch(transactionServiceProvider),
  );
});

final investmentServiceProvider = Provider<InvestmentService>((Ref ref) {
  return InvestmentService(ref.watch(lambdaApiServiceProvider));
});

final savingsServiceProvider = Provider<SavingsService>((Ref ref) {
  return SavingsService(ref.watch(lambdaApiServiceProvider));
});

final insightsServiceProvider = Provider<InsightsService>((Ref ref) {
  return InsightsService(
    ref.watch(lambdaApiServiceProvider),
    ref.watch(uuidProvider),
  );
});

final cashFlowServiceProvider = Provider<CashFlowService>((Ref ref) {
  return CashFlowService();
});

final mockBankServiceProvider = Provider<MockBankService>((Ref ref) {
  return MockBankService(
    ref.watch(lambdaApiServiceProvider),
    ref.watch(uuidProvider),
  );
});

final notificationServiceProvider = Provider<NotificationService>((Ref ref) {
  return NotificationService(ref.watch(lambdaApiServiceProvider));
});

final geminiKeyServiceProvider = Provider<GeminiKeyService>((Ref ref) {
  return GeminiKeyService();
});

final hasGeminiKeyProvider = StateNotifierProvider<HasGeminiKeyNotifier, bool>((Ref ref) {
  return HasGeminiKeyNotifier(ref.watch(geminiKeyServiceProvider));
});

class HasGeminiKeyNotifier extends StateNotifier<bool> {
  HasGeminiKeyNotifier(this._keyService) : super(false) {
    checkKey();
  }

  final GeminiKeyService _keyService;

  Future<void> checkKey() async {
    state = await _keyService.hasKey();
  }

  void setHasKey(bool hasKey) {
    state = hasKey;
  }
}
