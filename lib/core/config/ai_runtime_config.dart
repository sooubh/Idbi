import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiRuntimeConfig {
  static const String _defineChatFastModel = String.fromEnvironment(
    'AI_CHAT_FAST_MODEL',
    defaultValue: 'gemini-2.5-flash',
  );
  static const String _defineChatDeepModel = String.fromEnvironment(
    'AI_CHAT_DEEP_MODEL',
    defaultValue: 'gemini-1.5-pro',
  );
  static const String _defineVoiceModel = String.fromEnvironment(
    'AI_VOICE_MODEL',
    defaultValue: 'models/gemini-3.1-flash-live-preview',
  );
  static const String _defineLiveVoiceName = String.fromEnvironment(
    'AI_LIVE_VOICE_NAME',
    defaultValue: 'Puck',
  );
  static const String _defineLiveInputSampleRate = String.fromEnvironment(
    'AI_LIVE_INPUT_SAMPLE_RATE',
    defaultValue: '16000',
  );
  static const String _defineLiveOutputSampleRate = String.fromEnvironment(
    'AI_LIVE_OUTPUT_SAMPLE_RATE',
    defaultValue: '24000',
  );
  static const String _defineEnableDeviceSpeechFallback = String.fromEnvironment(
    'AI_ENABLE_DEVICE_SPEECH_FALLBACK',
    defaultValue: 'false',
  );

  static const String _defineApiKey = String.fromEnvironment(
    'AI_API_KEY',
    defaultValue: '',
  );

  static String? userGeminiApiKey;

  static String get apiKey {
    final String userKey = (userGeminiApiKey ?? '').trim();
    if (userKey.isNotEmpty) {
      return userKey;
    }
    return _readAny(<String>['AI_API_KEY', 'GEMINI_API_KEY'], _defineApiKey);
  }

  static String get chatFastModel {
    final String val = _readAny(<String>['AI_CHAT_FAST_MODEL', 'GEMINI_CHAT_FAST_MODEL'], _defineChatFastModel);
    if (val.contains('fast-model')) {
      return 'gemini-2.5-flash';
    }
    return val;
  }

  static String get chatDeepModel {
    final String val = _readAny(<String>['AI_CHAT_DEEP_MODEL', 'GEMINI_CHAT_DEEP_MODEL'], _defineChatDeepModel);
    if (val.contains('deep-model')) {
      return 'gemini-1.5-pro';
    }
    return val;
  }

  static String get voiceModel {
    final String val = _readAny(<String>['AI_VOICE_MODEL', 'GEMINI_VOICE_MODEL'], _defineVoiceModel);
    if (val == 'models/gemini-3.1-flash-live-preview' || val == 'models/voice-model' || val == 'voice-model') {
      return 'models/gemini-3.1-flash-live-preview';
    }
    return val;
  }

    static String get liveVoiceName =>
      _readAny(<String>['AI_LIVE_VOICE_NAME', 'GEMINI_LIVE_VOICE_NAME'], _defineLiveVoiceName);

    static int get liveInputSampleRate =>
      _readIntAny(
        <String>['AI_LIVE_INPUT_SAMPLE_RATE', 'GEMINI_LIVE_INPUT_SAMPLE_RATE'],
        _defineLiveInputSampleRate,
      );

    static int get liveOutputSampleRate =>
      _readIntAny(
        <String>['AI_LIVE_OUTPUT_SAMPLE_RATE', 'GEMINI_LIVE_OUTPUT_SAMPLE_RATE'],
        _defineLiveOutputSampleRate,
      );

  static bool get enableDeviceSpeechFallback =>
      _readBoolAny(
        <String>['AI_ENABLE_DEVICE_SPEECH_FALLBACK', 'GEMINI_ENABLE_DEVICE_SPEECH_FALLBACK'],
        _defineEnableDeviceSpeechFallback,
      );

  static String _read(String key, String fallback) {
    final String? raw = dotenv.env[key];
    if (raw != null && raw.trim().isNotEmpty) {
      return raw.trim();
    }
    return fallback;
  }

  static String _readAny(List<String> keys, String fallback) {
    for (final String key in keys) {
      final String value = _read(key, '');
      if (value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return fallback;
  }

  static int _readIntAny(List<String> keys, String fallback) {
    final String value = _readAny(keys, fallback);
    return int.tryParse(value) ?? int.tryParse(fallback) ?? 16000;
  }

  static bool _readBoolAny(List<String> keys, String fallback) {
    final String value = _readAny(keys, fallback);
    return _parseBool(value) ?? _parseBool(fallback) ?? false;
  }

  static bool? _parseBool(String value) {
    final String normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
    return null;
  }
}
