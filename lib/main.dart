import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_fin_os/app/student_fin_os_app.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:student_fin_os/core/config/ai_runtime_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeEnv();

  try {
    const secureStorage = FlutterSecureStorage();
    final savedKey = await secureStorage.read(key: 'gemini_api_key');
    if (savedKey != null && savedKey.trim().isNotEmpty) {
      AiRuntimeConfig.userGeminiApiKey = savedKey.trim();
    }
  } catch (e) {
    debugPrint('[Main] Error reading secure storage API key: $e');
  }

  runApp(const ProviderScope(child: StudentFinOsApp()));
}

Future<void> _initializeEnv() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Fallback to --dart-define when .env is not present.
  }
}
