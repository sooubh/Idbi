import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wealth_sdk/wealth_sdk.dart';
import 'package:student_fin_os/providers/aws_providers.dart';
import 'package:student_fin_os/features/wealth_advisor/ui/wealth_advisor_screen.dart';

class SdkSimulatorScreen extends ConsumerStatefulWidget {
  const SdkSimulatorScreen({super.key});

  @override
  ConsumerState<SdkSimulatorScreen> createState() => _SdkSimulatorScreenState();
}

class _SdkSimulatorScreenState extends ConsumerState<SdkSimulatorScreen> {
  final TextEditingController _apiKeyController = TextEditingController(text: 'wq_live_api_key_xxxxxxxx');
  bool _isInitializing = false;
  bool _isInitialized = false;
  List<String> _consoleLogs = [];

  @override
  void initState() {
    super.initState();
    if (WealthSdk.isInitialized) {
      _isInitialized = true;
      _consoleLogs = List.from(WealthSdk.logs);
    } else {
      _consoleLogs.add('[Console] SDK not initialized yet. Press "Initialize SDK" to begin.');
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _initializeSdk() async {
    final user = ref.read(authServiceProvider).currentUser;
    final String userId = user?.uid ?? 'mock_bank_user_id';

    setState(() {
      _isInitializing = true;
      _consoleLogs.add('[Console] Launching WealthSdk.initialize()...');
    });

    final config = WealthSdkConfig(
      apiKey: _apiKeyController.text,
      userId: userId,
      partnerBankName: 'State Bank of India (SBI)',
    );

    // Call library initialization
    await WealthSdk.initialize(config);

    // Read logs sequentially to simulate terminal console rendering
    for (int i = _consoleLogs.length; i < WealthSdk.logs.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() {
          _consoleLogs.add(WealthSdk.logs[i]);
        });
      }
    }

    if (mounted) {
      setState(() {
        _isInitializing = false;
        _isInitialized = true;
        _consoleLogs.add('[Console] WealthQuest AI SDK successfully integrated in Partner Bank shell!');
      });
    }
  }

  void _launchSdkAdvisor() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: const FractionallySizedBox(
            heightFactor: 0.95,
            child: Scaffold(
              body: WealthAdvisorScreen(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner Bank SDK Simulator'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header info
          Text(
            'Partner Integration Console',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Demonstrates how legacy banks embed the WealthQuest AI advisor as a path-dependency module.',
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),

          // SDK Configuration Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SDK Credentials Configuration',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _apiKeyController,
                    decoration: const InputDecoration(
                      labelText: 'API Client Key',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.vpn_key),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isInitializing ? null : _initializeSdk,
                        icon: _isInitializing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.settings_input_component),
                        label: Text(_isInitializing ? 'Connecting...' : 'Initialize SDK'),
                      ),
                      const SizedBox(width: 12),
                      if (_isInitialized)
                        Icon(Icons.check_circle, color: Colors.green.shade600)
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // SDK Live Terminal Console
          Text(
            'SDK Terminal output',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            height: 180,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: ListView.builder(
              itemCount: _consoleLogs.length,
              itemBuilder: (context, index) {
                final log = _consoleLogs[index];
                Color color = Colors.greenAccent;
                if (log.startsWith('[Console]')) {
                  color = Colors.amberAccent;
                } else if (log.contains('Ready')) {
                  color = Colors.cyanAccent;
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    log,
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 12,
                      color: color,
                      height: 1.3,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Simulated Embedded Widget
          Text(
            'Simulated Embedded Partner Widget',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (!_isInitialized)
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(
                  'Widget offline. Initialize SDK to load.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            // Render the banner exported directly from our separate Flutter package
            WealthSdkBannerWidget(
              onTapOpen: _launchSdkAdvisor,
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
