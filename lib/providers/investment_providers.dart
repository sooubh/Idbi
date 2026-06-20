import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_fin_os/models/investment_holding.dart';
import 'package:student_fin_os/providers/auth_providers.dart';
import 'package:student_fin_os/providers/aws_providers.dart';

final investmentsProvider = StreamProvider.autoDispose<List<InvestmentHolding>>((ref) {
  final String? userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream<List<InvestmentHolding>>.value(const <InvestmentHolding>[]);
  }
  return ref.watch(investmentServiceProvider).watchInvestments(userId);
});

class InvestmentController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> addOrUpdateInvestment(InvestmentHolding holding) async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      throw StateError('Not authenticated.');
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(investmentServiceProvider).upsertInvestment(holding);
      ref.invalidate(investmentsProvider);
    });
  }

  Future<void> deleteInvestment(String holdingId) async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      throw StateError('Not authenticated.');
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(investmentServiceProvider).deleteInvestment(
            userId: userId,
            holdingId: holdingId,
          );
      ref.invalidate(investmentsProvider);
    });
  }
}

final investmentControllerProvider =
    AsyncNotifierProvider<InvestmentController, void>(InvestmentController.new);
