class InvestmentHolding {
  const InvestmentHolding({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.investedAmount,
    required this.currentValue,
    required this.returnsPercent,
    required this.lastUpdated,
  });

  final String id;
  final String userId;
  final String name;
  final String category; // 'Equity', 'Mutual Fund', 'Fixed Deposit', 'Gold'
  final double investedAmount;
  final double currentValue;
  final double returnsPercent;
  final DateTime lastUpdated;

  double get returnsAmount => currentValue - investedAmount;

  factory InvestmentHolding.fromJson(Map<String, dynamic> json) {
    return InvestmentHolding(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      investedAmount: (json['investedAmount'] as num?)?.toDouble() ?? 0.0,
      currentValue: (json['currentValue'] as num?)?.toDouble() ?? 0.0,
      returnsPercent: (json['returnsPercent'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'category': category,
      'investedAmount': investedAmount,
      'currentValue': currentValue,
      'returnsPercent': returnsPercent,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}
