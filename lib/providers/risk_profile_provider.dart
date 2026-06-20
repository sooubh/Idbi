import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RiskProfile {
  conservative,
  moderate,
  aggressive,
}

extension RiskProfileExtension on RiskProfile {
  String get name {
    switch (this) {
      case RiskProfile.conservative:
        return 'Conservative';
      case RiskProfile.moderate:
        return 'Moderate';
      case RiskProfile.aggressive:
        return 'Aggressive';
    }
  }

  String get description {
    switch (this) {
      case RiskProfile.conservative:
        return 'Low risk tolerance. Focuses on capital preservation, steady returns, and liquidity. Allocation: 70% Debt/FDs, 15% Mutual Funds, 10% Gold, 5% Equities.';
      case RiskProfile.moderate:
        return 'Balanced risk tolerance. Seeks reasonable growth with moderate stability. Allocation: 40% Mutual Funds, 30% Equities, 20% Debt/FDs, 10% Gold.';
      case RiskProfile.aggressive:
        return 'High risk tolerance. Focuses on long-term capital appreciation. Allocation: 65% Equities, 25% Mutual Funds, 5% Gold, 5% Cash.';
    }
  }

  Map<String, double> get targetAllocation {
    switch (this) {
      case RiskProfile.conservative:
        return {'Fixed Deposits': 70.0, 'Mutual Funds': 15.0, 'Gold': 10.0, 'Equities': 5.0};
      case RiskProfile.moderate:
        return {'Mutual Funds': 40.0, 'Equities': 30.0, 'Fixed Deposits': 20.0, 'Gold': 10.0};
      case RiskProfile.aggressive:
        return {'Equities': 65.0, 'Mutual Funds': 25.0, 'Gold': 5.0, 'Cash / Liquid': 5.0};
    }
  }
}

final riskProfileProvider = StateProvider<RiskProfile>((ref) {
  return RiskProfile.moderate;
});
