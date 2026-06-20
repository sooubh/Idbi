import 'package:flutter/material.dart';

/// Configuration options for initializing the WealthQuest AI Partner SDK.
class WealthSdkConfig {
  const WealthSdkConfig({
    required this.apiKey,
    required this.userId,
    this.partnerBankName = 'Global Partner Bank',
    this.themeMode = ThemeMode.system,
    this.sandboxMode = true,
  });

  final String apiKey;
  final String userId;
  final String partnerBankName;
  final ThemeMode themeMode;
  final bool sandboxMode;
}

/// The main entrypoint for the WealthQuest AI SDK.
class WealthSdk {
  WealthSdk._();

  static bool _initialized = false;
  static final List<String> _logs = [];
  static late WealthSdkConfig _config;

  static bool get isInitialized => _initialized;
  static List<String> get logs => List.unmodifiable(_logs);
  static WealthSdkConfig get config => _config;

  /// Initialize the Wealth Advisor SDK with client credentials and configuration telemetry.
  static Future<void> initialize(WealthSdkConfig config) async {
    _logs.clear();
    _log('SDK: Initializing WealthQuest AI Partner SDK module...');
    _log('SDK: Target Client Authentication User ID: ${config.userId}');
    _log('SDK: Partner Bank Entity: ${config.partnerBankName}');
    _log('SDK: Client telemetry context syncing initiated...');
    
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _log('SDK: Fetched user bank accounts (checking, savings) securely.');
    
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _log('SDK: Syncing category-wise spending habits context with Gemini API...');
    
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _log('SDK: Context loaded. Client profile: Moderate Risk Portfolio.');
    _log('SDK: Connection established successfully. Status: Ready.');
    
    _config = config;
    _initialized = true;
  }

  static void _log(String msg) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    _logs.add('[$timestamp] $msg');
  }
}

/// An embeddable banner/widget that partner banks can place on their home screen.
class WealthSdkBannerWidget extends StatelessWidget {
  const WealthSdkBannerWidget({
    required this.onTapOpen,
    super.key,
  });

  final VoidCallback onTapOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'POWERED BY WEALTHQUEST AI',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Unlock AI-Powered Advisory',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Let your personal avatar optimize your savings, investment SIPs, and risk profile.',
            style: TextStyle(
              color: Color(0xDEFFFFFF),
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: onTapOpen,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Launch Advisor',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
