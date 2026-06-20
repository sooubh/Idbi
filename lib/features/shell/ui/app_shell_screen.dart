import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:student_fin_os/core/router/app_router.dart';
import 'package:student_fin_os/features/accounts/ui/account_aggregator_screen.dart';
import 'package:student_fin_os/features/assistant/ui/voice_assistant_sheet.dart';
import 'package:student_fin_os/features/cashflow/ui/cash_flow_screen.dart';
import 'package:student_fin_os/features/dashboard/ui/dashboard_screen.dart';
import 'package:student_fin_os/features/insights/ui/insights_screen.dart';
import 'package:student_fin_os/features/savings/ui/savings_screen.dart';
import 'package:student_fin_os/features/profile/ui/risk_profile_screen.dart';
import 'package:student_fin_os/features/profile/ui/sdk_simulator_screen.dart';
import 'package:student_fin_os/features/transactions/ui/transactions_screen.dart';
import 'package:student_fin_os/features/profile/ui/profile_settings_screen.dart';
import 'package:student_fin_os/features/wealth_advisor/ui/wealth_advisor_screen.dart';
import 'package:student_fin_os/providers/auth_providers.dart';
import 'package:student_fin_os/features/shell/ui/alerts_sheet.dart';
import 'package:student_fin_os/features/assistant/ui/chat_assistant_screen.dart';

class AppShellScreen extends ConsumerStatefulWidget {
  const AppShellScreen({required this.initialIndex, super.key});

  final int initialIndex;

  @override
  ConsumerState<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends ConsumerState<AppShellScreen> {
  late int _index;
  static const List<int> _mobileTabIndexes = <int>[0, 1, 2, 3, 4];

  late final List<Widget> _pages = const <Widget>[
    DashboardScreen(),
    CashFlowScreen(),
    WealthAdvisorScreen(),
    SavingsScreen(),
    ProfileSettingsScreen(),
    AccountAggregatorScreen(),
    TransactionsScreen(),
    InsightsScreen(),
    RiskProfileScreen(),
    SdkSimulatorScreen(),
  ];

  late final List<NavigationDestination> _destinations =
      const <NavigationDestination>[
        NavigationDestination(icon: Icon(Icons.space_dashboard), label: 'Dashboard'),
        NavigationDestination(icon: Icon(Icons.timeline), label: 'CashFlow'),
        NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'Advisor'),
        NavigationDestination(icon: Icon(Icons.savings), label: 'Goals'),
        NavigationDestination(icon: Icon(Icons.account_circle), label: 'Profile'),
        NavigationDestination(icon: Icon(Icons.account_balance), label: 'Accounts'),
        NavigationDestination(icon: Icon(Icons.swap_horiz), label: 'Txns'),
        NavigationDestination(icon: Icon(Icons.lightbulb), label: 'Insights'),
        NavigationDestination(icon: Icon(Icons.psychology), label: 'Risk Profiler'),
        NavigationDestination(icon: Icon(Icons.developer_mode), label: 'SDK Simulator'),
      ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  void _onDestinationSelected(int value) {
    if (value < 0 || value >= AppRoutes.appTabs.length) {
      return;
    }
    setState(() {
      _index = value;
    });
    context.go(AppRoutes.appTabs[value]);
  }

  int _mobileSelectedIndex() {
    final int selected = _mobileTabIndexes.indexOf(_index);
    return selected < 0 ? 0 : selected;
  }

  Future<void> _openVoiceAssistant() async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return const FractionallySizedBox(
          heightFactor: 0.92,
          child: VoiceAssistantSheet(),
        );
      },
    );
  }

  Widget _buildCustomBottomNavigationBar(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final int selectedIndex = _mobileSelectedIndex();

    Widget buildNavItem(IconData icon, String label, int index) {
      final bool isSelected = selectedIndex == index;
      return Expanded(
        child: InkWell(
          onTap: () {
            _onDestinationSelected(_mobileTabIndexes[index]);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                height: 32,
                width: 56,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.secondaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isSelected
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ) ??
                    const TextStyle(),
                child: Text(label),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        color: colorScheme.surfaceContainer,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            buildNavItem(Icons.space_dashboard, 'Dashboard', 0),
            buildNavItem(Icons.timeline, 'CashFlow', 1),
            buildNavItem(Icons.auto_awesome, 'Advisor', 2),
            buildNavItem(Icons.savings, 'Goals', 3),
            buildNavItem(Icons.account_circle, 'Profile', 4),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool desktopLayout = MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
      appBar: _index == 2
          ? null
          : AppBar(
              leading: Builder(
                builder: (BuildContext context) {
                  return IconButton(
                    tooltip: 'Profile',
                    icon: const Icon(Icons.account_circle, size: 28),
                    onPressed: () {
                      _onDestinationSelected(4);
                    },
                  );
                }
              ),
        title: Container(
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            textInputAction: TextInputAction.search,
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => ChatAssistantScreen(initialMessage: value)));
              }
            },
            decoration: const InputDecoration(
              hintText: 'Ask FinMate anything...',
              prefixIcon: Icon(Icons.search, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ),
        actions: <Widget>[
          if (desktopLayout)
            IconButton(
              tooltip: 'Chat assistant',
              onPressed: () {
                context.push(AppRoutes.chatAssistant);
              },
              icon: const Icon(Icons.chat_bubble_outline),
            ),
          if (desktopLayout)
            IconButton(
              tooltip: 'Voice assistant',
              onPressed: _openVoiceAssistant,
              icon: const Icon(Icons.mic_none),
            ),
          IconButton(
            tooltip: 'Alerts',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const AlertsSheet(),
              );
            },
            icon: const Badge(child: Icon(Icons.notifications_none)),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: desktopLayout
          ? Row(
              children: <Widget>[
                NavigationRail(
                  selectedIndex: _index,
                  destinations: _destinations.map((NavigationDestination item) {
                    return NavigationRailDestination(
                      icon: item.icon,
                      label: Text(item.label),
                    );
                  }).toList(),
                  onDestinationSelected: (int value) {
                    _onDestinationSelected(value);
                  },
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.02, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<int>(_index),
                      child: _pages[_index],
                    ),
                  ),
                ),
              ],
            )
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.03, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(_index),
                child: _pages[_index],
              ),
            ),
      bottomNavigationBar: desktopLayout
          ? null
          : _buildCustomBottomNavigationBar(context),
    );
  }
}
