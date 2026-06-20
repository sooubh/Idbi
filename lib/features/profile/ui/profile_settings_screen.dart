import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:student_fin_os/core/utils/currency_formatter.dart';
import 'package:student_fin_os/core/utils/demo_seeder.dart';
import 'package:student_fin_os/models/finance_transaction.dart';
import 'package:student_fin_os/providers/auth_providers.dart';
import 'package:student_fin_os/providers/dashboard_providers.dart';
import 'package:student_fin_os/providers/aws_providers.dart';
import 'package:student_fin_os/providers/investment_providers.dart';
import 'package:student_fin_os/providers/risk_profile_provider.dart';
import 'package:student_fin_os/features/profile/ui/risk_profile_screen.dart';
import 'package:student_fin_os/features/profile/ui/sdk_simulator_screen.dart';
import 'package:student_fin_os/core/widgets/gemini_key_manager_sheet.dart';

class ProfileSettingsScreen extends ConsumerWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentUser;
    final snapshot = ref.watch(dashboardSnapshotProvider);
    final List<FinanceTransaction> txList =
        ref.watch(transactionsProvider).value ?? const <FinanceTransaction>[];

    final _SpendingHabits habits = _buildSpendingHabits(snapshot, txList);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _profileHeader(context, user),
          const SizedBox(height: 12),
          _riskProfileSettingsCard(context, ref),
          const SizedBox(height: 12),
          _dataPrivacyCard(context),
          const SizedBox(height: 12),
          _spendingHabitsSection(context, habits),
          const SizedBox(height: 12),
          _geminiKeySettingsCard(context, ref),
          const SizedBox(height: 12),
          _quickFeedDemoDataCard(context, ref),
          const SizedBox(height: 12),
          _sdkSimulatorCard(context),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              subtitle: const Text('Log out from this device'),
              onTap: () {
                ref.read(authControllerProvider.notifier).signOut();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _geminiKeySettingsCard(BuildContext context, WidgetRef ref) {
    final hasKey = ref.watch(hasGeminiKeyProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: ListTile(
        leading: Icon(
          Icons.vpn_key_rounded,
          color: hasKey ? colorScheme.primary : Colors.orange,
        ),
        title: const Text('Gemini API Key'),
        subtitle: Text(
          hasKey ? 'Configured securely on device' : 'Tap to configure key for AI features',
        ),
        trailing: Icon(
          hasKey ? Icons.check_circle_outline : Icons.warning_amber_rounded,
          color: hasKey ? Colors.green : Colors.orange,
        ),
        onTap: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (BuildContext context) {
              return const GeminiKeyManagerSheet();
            },
          );
        },
      ),
    );
  }

  Widget _profileHeader(BuildContext context, dynamic user) {
    final String displayName =
        (user?.displayName as String?)?.trim().isNotEmpty == true
            ? user.displayName as String
            : 'Student';
    final String email =
        (user?.email as String?)?.trim().isNotEmpty == true
            ? user.email as String
            : 'No email linked';
    final String? photoUrl = user?.photoURL as String?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                  ? NetworkImage(photoUrl)
                  : null,
              child: (photoUrl == null || photoUrl.isEmpty)
                  ? Text(
                      displayName.isNotEmpty
                          ? displayName.substring(0, 1).toUpperCase()
                          : 'S',
                      style: Theme.of(context).textTheme.titleLarge,
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    displayName,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(email, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Smart goal-based investing & wealth planning',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _riskProfileSettingsCard(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(riskProfileProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology_rounded, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Investment Risk Profile',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.primaryContainer.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.description,
                          style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const RiskProfileScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Update Risk Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dataPrivacyCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security_rounded, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Text(
                  'Data Privacy & Security',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Your financial security is our highest priority. WealthQuest AI implements bank-grade compliance standards.',
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            _privacySwitchTile(
              context,
              icon: Icons.lock_outline,
              title: 'AES-256 Encryption at Rest',
              subtitle: 'Local cache and credentials are encrypted securely.',
              initialValue: true,
              enabled: false,
            ),
            _privacySwitchTile(
              context,
              icon: Icons.verified_user_outlined,
              title: 'AI Advisory Consent',
              subtitle: 'Allow Gemini to analyze spending for advice.',
              initialValue: true,
              enabled: true,
            ),
            _privacySwitchTile(
              context,
              icon: Icons.fingerprint,
              title: 'Biometric Lock',
              subtitle: 'Request fingerprint/FaceID on app startup.',
              initialValue: false,
              enabled: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _privacySwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool initialValue,
    required bool enabled,
  }) {
    final theme = Theme.of(context);
    return StatefulBuilder(
      builder: (context, setState) {
        bool value = initialValue;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, size: 24),
          title: Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
          trailing: Switch(
            value: value,
            onChanged: enabled
                ? (val) {
                    setState(() {
                      value = val;
                    });
                  }
                : null,
          ),
        );
      },
    );
  }

  Widget _spendingHabitsSection(BuildContext context, _SpendingHabits habits) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.insights_outlined),
                const SizedBox(width: 8),
                Text(
                  'Spending Habits',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(habits.summary),
            const SizedBox(height: 12),
            _habitRow(
              context,
              label: 'Top category',
              value: habits.topCategory,
            ),
            _habitRow(
              context,
              label: 'Average daily spend',
              value: CurrencyFormatter.inr(habits.avgDailySpend),
            ),
            _habitRow(
              context,
              label: 'Average transaction',
              value: CurrencyFormatter.inr(habits.avgTransactionAmount),
            ),
            _habitRow(
              context,
              label: 'Savings ratio',
              value: '${habits.savingsRatioPercent.toStringAsFixed(1)}%',
            ),
            _habitRow(
              context,
              label: 'Active spend days (this month)',
              value: '${habits.activeSpendDays}',
            ),
            const SizedBox(height: 8),
            Text(
              habits.actionTip,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _habitRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label)),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  _SpendingHabits _buildSpendingHabits(
    dynamic snapshot,
    List<FinanceTransaction> transactions,
  ) {
    final DateTime now = DateTime.now();
    final List<FinanceTransaction> monthTx = transactions.where((FinanceTransaction tx) {
      final DateTime local = tx.transactionAt.toLocal();
      return local.year == now.year && local.month == now.month && tx.isExpense;
    }).toList(growable: false);

    final double totalMonthExpense = monthTx.fold<double>(
      0,
      (double sum, FinanceTransaction tx) => sum + tx.amount,
    );
    final double avgTx = monthTx.isEmpty ? 0 : totalMonthExpense / monthTx.length;
    final double avgDaily = totalMonthExpense / now.day.clamp(1, 31);

    final Set<String> activeDates = monthTx.map((FinanceTransaction tx) {
      final DateTime local = tx.transactionAt.toLocal();
      return DateFormat('yyyy-MM-dd').format(local);
    }).toSet();

    final double savingsRatio = (snapshot.totalSavings + totalMonthExpense) <= 0
        ? 0
        : (snapshot.totalSavings / (snapshot.totalSavings + totalMonthExpense)) * 100;

    final String habitBand;
    if (snapshot.safeToSpend < 0) {
      habitBand = 'High pressure spending pattern';
    } else if (snapshot.burnRate > 700) {
      habitBand = 'Aggressive spending pattern';
    } else if (snapshot.burnRate > 350) {
      habitBand = 'Balanced spending pattern';
    } else {
      habitBand = 'Disciplined spending pattern';
    }

    final String summary =
        '$habitBand. You spend around ${CurrencyFormatter.inr(avgDaily)} per day this month, '
        'with ${snapshot.topCategory} as your largest category.';

    final String actionTip = snapshot.safeToSpend <= 0
        ? 'Action: hold optional purchases for 3-5 days to recover your safe-to-spend zone.'
        : 'Action: cap your daily optional spending under ${CurrencyFormatter.inr(snapshot.safeToSpend / 7)} for better consistency.';

    return _SpendingHabits(
      topCategory: snapshot.topCategory,
      avgDailySpend: avgDaily,
      avgTransactionAmount: avgTx,
      savingsRatioPercent: savingsRatio,
      activeSpendDays: activeDates.length,
      summary: summary,
      actionTip: actionTip,
    );
  }

  Widget _sdkSimulatorCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: ListTile(
        leading: Icon(
          Icons.developer_mode_rounded,
          color: colorScheme.primary,
        ),
        title: const Text('Partner Bank SDK Simulator'),
        subtitle: const Text('Test white-label integration in a simulator shell'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => const SdkSimulatorScreen(),
            ),
          );
        },
      ),
    );
  }

  Widget _quickFeedDemoDataCard(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: ListTile(
        leading: Icon(
          Icons.data_exploration_rounded,
          color: colorScheme.primary,
        ),
        title: const Text('Quick Feed Demo Data'),
        subtitle: const Text('Populate app with 5 customized mock profiles for AI testing'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          _showDemoDataSelectionDialog(context, ref);
        },
      ),
    );
  }

  void _showDemoDataSelectionDialog(BuildContext context, WidgetRef ref) {
    final user = ref.read(authServiceProvider).currentUser;
    final String userId = user?.uid ?? 'offline_user_id';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Mock Demo Profile',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Seeding a mock profile will overwrite the local database, feeding full financial context to the AI assistant.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                _demoProfileTile(
                  context, ref, userId,
                  title: 'Conservative Portfolio (Capital Preservation)',
                  description: 'Fixed Deposits, Sovereign Gold Bonds, and Debt Mutual Funds. Low risk.',
                  type: DemoProfileType.conservative,
                ),
                const SizedBox(height: 10),
                _demoProfileTile(
                  context, ref, userId,
                  title: 'Moderate Portfolio (Balanced Growth)',
                  description: 'Balanced mix of Nifty 50 Index Mutual Funds, Bluechip Equities, and FDs.',
                  type: DemoProfileType.moderate,
                ),
                const SizedBox(height: 10),
                _demoProfileTile(
                  context, ref, userId,
                  title: 'Aggressive Portfolio (Capital Appreciation)',
                  description: 'High-growth Tech stocks, Small-Cap Mutual Funds. High risk tolerance.',
                  type: DemoProfileType.aggressive,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _demoProfileTile(
    BuildContext context,
    WidgetRef ref,
    String userId, {
    required String title,
    required String description,
    required DemoProfileType type,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () {
        Navigator.pop(context); // Close sheet
        DemoSeeder.seed(userId, type);
        
        // Refresh/invalidate all dashboard and aggregators streams
        ref.invalidate(accountsProvider);
        ref.invalidate(transactionsProvider);
        ref.invalidate(savingsGoalsProvider);
        ref.invalidate(investmentsProvider);
        ref.invalidate(dashboardSnapshotProvider);
        ref.invalidate(aggregationSnapshotProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully seeded "$title" dataset!'),
            backgroundColor: Colors.green,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _SpendingHabits {
  const _SpendingHabits({
    required this.topCategory,
    required this.avgDailySpend,
    required this.avgTransactionAmount,
    required this.savingsRatioPercent,
    required this.activeSpendDays,
    required this.summary,
    required this.actionTip,
  });

  final String topCategory;
  final double avgDailySpend;
  final double avgTransactionAmount;
  final double savingsRatioPercent;
  final int activeSpendDays;
  final String summary;
  final String actionTip;
}
