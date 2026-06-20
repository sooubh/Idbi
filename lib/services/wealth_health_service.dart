import 'package:student_fin_os/models/avatar_mood.dart';
import 'package:student_fin_os/models/dashboard_snapshot.dart';
import 'package:student_fin_os/models/wealth_health.dart';

class WealthHealthService {
  WealthHealthService._();

  static WealthHealth calculateWealthHealth(DashboardSnapshot snapshot) {
    // 1. Savings Score (30%)
    final double totalAssets = snapshot.totalBalance + snapshot.totalSavings;
    double savingsScore = 0;
    if (totalAssets > 0) {
      final double ratio = snapshot.totalSavings / totalAssets;
      // If 20% or more of assets is in savings, full points.
      savingsScore = (ratio / 0.20 * 100).clamp(0.0, 100.0);
    }

    // 2. Spending Trend Score (25%)
    // Lower spending vs previous month is better
    double spendingScore = 0;
    final double trend = snapshot.monthlyTrendPercent;
    if (trend <= 0) {
      spendingScore = 100;
    } else {
      // 50% increase in spend relative to previous month scales down to 0
      spendingScore = (100 - (trend * 2)).clamp(0.0, 100.0);
    }

    // 3. Safe-to-Spend Score (25%)
    double safeToSpendScore = 0;
    if (snapshot.safeToSpend > 0) {
      safeToSpendScore = 100;
    } else if (snapshot.safeToSpend < 0) {
      final double penaltyRatio = snapshot.monthlySpend > 0 
          ? (snapshot.safeToSpend.abs() / snapshot.monthlySpend) 
          : 1.0;
      safeToSpendScore = (100 - (penaltyRatio * 100)).clamp(0.0, 100.0);
    } else {
      safeToSpendScore = 50;
    }

    // 4. Burn Rate / Runway Score (20%)
    double runwayScore = 0;
    if (snapshot.monthlySpend > 0) {
      final double monthsRunway = snapshot.totalBalance / snapshot.monthlySpend;
      // 3 months of runway is ideal (100 points)
      runwayScore = (monthsRunway / 3.0 * 100).clamp(0.0, 100.0);
    } else {
      runwayScore = snapshot.totalBalance > 0 ? 100 : 0;
    }

    final double weightedScore = (savingsScore * 0.3) +
        (spendingScore * 0.25) +
        (safeToSpendScore * 0.25) +
        (runwayScore * 0.2);

    final int score = weightedScore.round().clamp(0, 100);

    String label;
    AvatarMood mood;
    String explanation;

    if (score >= 85) {
      label = 'Excellent';
      mood = AvatarMood.idle;
      explanation = 'Your financial health is outstanding! You have a high savings rate, a healthy runway, and your spending is under control.';
    } else if (score >= 70) {
      label = 'Good';
      mood = AvatarMood.idle;
      explanation = 'Your finances are in stable shape. Consider optimizing your monthly budget to convert more safety buffer into investments.';
    } else if (score >= 50) {
      label = 'Needs Attention';
      mood = AvatarMood.idle;
      explanation = 'Your savings rate or cash buffer is low relative to your monthly expenses. Let\'s try trimming non-essential spending.';
    } else {
      label = 'Risk Area';
      mood = AvatarMood.idle;
      explanation = 'Your current runway is short and your safe-to-spend is in the negative. Let\'s review your budget to cut expenses immediately.';
    }

    return WealthHealth(
      score: score,
      label: label,
      mood: mood,
      explanation: explanation,
    );
  }
}
