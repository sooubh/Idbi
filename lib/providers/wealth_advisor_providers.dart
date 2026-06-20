import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_fin_os/models/assistant_models.dart';
import 'package:student_fin_os/models/avatar_mood.dart';
import 'package:student_fin_os/models/wealth_health.dart';
import 'package:student_fin_os/providers/assistant_providers.dart';
import 'package:student_fin_os/providers/dashboard_providers.dart';
import 'package:student_fin_os/services/wealth_health_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Avatar Mood Provider
//
// Derives the current [AvatarMood] from existing assistant state — no
// modifications to assistant_providers.dart required.
//
// Mapping:
//   ChatAssistantState.isTyping == true              → thinking
//   VoiceAssistantState.status == processing         → thinking
//   VoiceAssistantState.status == speaking           → speaking
//   else                                             → idle
// ─────────────────────────────────────────────────────────────────────────────

/// Writable mood override. Used by [MascotController] to drive speaking state
/// from TTS callbacks that live outside Riverpod (flutter_tts callbacks).
final avatarMoodOverrideProvider = StateProvider<AvatarMood?>((ref) => null);

/// The resolved avatar mood. Watches both assistant controllers and the manual
/// override so any pathway (chat, voice, TTS) drives a single mood.
final avatarMoodProvider = Provider<AvatarMood>((ref) {
  // Manual override wins — used to signal TTS speaking from widget callbacks.
  final AvatarMood? override = ref.watch(avatarMoodOverrideProvider);
  if (override != null) return override;

  // Chat assistant: isTyping → thinking
  final ChatAssistantState chatState =
      ref.watch(chatAssistantControllerProvider);
  if (chatState.isTyping) return AvatarMood.thinking;

  // Voice assistant: processing → thinking, speaking → speaking
  final VoiceAssistantState voiceState =
      ref.watch(voiceAssistantControllerProvider);
  if (voiceState.status == VoiceAssistantStatus.processing) {
    return AvatarMood.thinking;
  }
  if (voiceState.status == VoiceAssistantStatus.speaking) {
    return AvatarMood.speaking;
  }

  return AvatarMood.idle;
});

/// Computes the overall wealth health score and status from the dashboard snapshot.
final wealthHealthProvider = Provider<WealthHealth>((ref) {
  final snapshot = ref.watch(dashboardSnapshotProvider);
  return WealthHealthService.calculateWealthHealth(snapshot);
});

// ─────────────────────────────────────────────────────────────────────────────
// Wealth-specific quick prompts (wealth-reframed, replaces student prompts)
// ─────────────────────────────────────────────────────────────────────────────
final wealthQuickPromptsProvider = Provider<List<String>>((ref) {
  return const <String>[
    'How am I doing financially this month?',
    'Can I invest some money right now?',
    'Where am I overspending?',
    'Am I on track for my savings goals?',
    'What should I do to improve my finances?',
  ];
});
