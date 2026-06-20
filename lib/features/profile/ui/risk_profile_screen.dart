import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_fin_os/providers/risk_profile_provider.dart';
import 'package:student_fin_os/core/utils/demo_seeder.dart';
import 'package:student_fin_os/providers/dashboard_providers.dart';
import 'package:student_fin_os/providers/investment_providers.dart';
import 'package:student_fin_os/providers/auth_providers.dart';

class RiskProfileScreen extends ConsumerStatefulWidget {
  const RiskProfileScreen({super.key});

  @override
  ConsumerState<RiskProfileScreen> createState() => _RiskProfileScreenState();
}

class _RiskProfileScreenState extends ConsumerState<RiskProfileScreen> {
  int _currentStep = 0;
  final Map<int, int> _answers = {};

  final List<Map<String, dynamic>> _questions = [
    {
      'question': '1. What is your age group?',
      'options': [
        {'text': '18 – 30 years (High risk capacity)', 'score': 3},
        {'text': '31 – 45 years (Moderate risk capacity)', 'score': 2},
        {'text': '46 years or above (Conservative risk capacity)', 'score': 1},
      ]
    },
    {
      'question': '2. What is your primary investment objective?',
      'options': [
        {'text': 'Aggressive Growth: High growth, high volatility potential', 'score': 3},
        {'text': 'Balanced Growth: Income generation + capital growth', 'score': 2},
        {'text': 'Capital Preservation: Keep capital safe, beat inflation slowly', 'score': 1},
      ]
    },
    {
      'question': '3. How would you react if your investments fell by 15% in a market correction?',
      'options': [
        {'text': 'Opportunistic: Buy more at discounted rates', 'score': 3},
        {'text': 'Patient: Hold steady and wait for recovery', 'score': 2},
        {'text': 'Anxious: Sell immediately to prevent further losses', 'score': 1},
      ]
    },
    {
      'question': '4. What is your expected investment horizon?',
      'options': [
        {'text': 'Long-term: 5 years or longer', 'score': 3},
        {'text': 'Medium-term: 2 to 5 years', 'score': 2},
        {'text': 'Short-term: Less than 2 years', 'score': 1},
      ]
    }
  ];

  void _selectOption(int optionIndex) {
    setState(() {
      _answers[_currentStep] = optionIndex;
    });

    // Auto-advance after brief delay
    Future.delayed(const Duration(milliseconds: 250), () {
      if (_currentStep < _questions.length - 1) {
        setState(() {
          _currentStep++;
        });
      } else {
        _finishAssessment();
      }
    });
  }

  void _finishAssessment() {
    int totalScore = 0;
    _answers.forEach((key, value) {
      final List<Map<String, dynamic>> options = _questions[key]['options'] as List<Map<String, dynamic>>;
      totalScore += options[value]['score'] as int;
    });

    RiskProfile finalProfile;
    if (totalScore >= 10) {
      finalProfile = RiskProfile.aggressive;
    } else if (totalScore >= 7) {
      finalProfile = RiskProfile.moderate;
    } else {
      finalProfile = RiskProfile.conservative;
    }

    ref.read(riskProfileProvider.notifier).state = finalProfile;

    // Auto-reseed mock data matching the new risk profile
    final String userId = ref.read(currentUserIdProvider) ?? 'offline_user_id';
    switch (finalProfile) {
      case RiskProfile.conservative:
        DemoSeeder.seed(userId, DemoProfileType.conservative);
        break;
      case RiskProfile.moderate:
        DemoSeeder.seed(userId, DemoProfileType.moderate);
        break;
      case RiskProfile.aggressive:
        DemoSeeder.seed(userId, DemoProfileType.aggressive);
        break;
    }

    // Invalidate providers to force UI sync
    ref.invalidate(accountsProvider);
    ref.invalidate(transactionsProvider);
    ref.invalidate(savingsGoalsProvider);
    ref.invalidate(investmentsProvider);
    ref.invalidate(dashboardSnapshotProvider);
    ref.invalidate(aggregationSnapshotProvider);

    _showResultDialog(finalProfile);
  }

  void _showResultDialog(RiskProfile profile) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.stars, color: theme.colorScheme.primary, size: 28),
              const SizedBox(width: 8),
              const Text('Assessment Complete'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Risk Profile is:',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                profile.name,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                profile.description,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              const Text(
                'We have automatically seeded your dashboard with a matching investment portfolio and SIPs.',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Exit risk profiler screen
              },
              child: const Text('Go to Dashboard'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final double progress = (_currentStep + 1) / _questions.length;

    final q = _questions[_currentStep];
    final questionText = q['question'] as String;
    final options = q['options'] as List<Map<String, dynamic>>;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Risk Assessment'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Bar
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_currentStep + 1} of ${_questions.length}',
                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Question
              Text(
                questionText,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 24),

              // Options
              Expanded(
                child: ListView.builder(
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final isSelected = _answers[_currentStep] == index;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _selectOption(index),
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                                : colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? colorScheme.primary : colorScheme.outlineVariant.withValues(alpha: 0.3),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  options[index]['text'] as String,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle, color: colorScheme.primary)
                              else
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: colorScheme.outline),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Back Button (if not on first step)
              if (_currentStep > 0)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _currentStep--;
                      });
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
