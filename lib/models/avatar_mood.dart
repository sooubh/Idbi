/// Avatar mood states that map to the Rive state machine in mascot.riv.
///
/// Open mascot.riv in https://rive.app and verify the exact names of:
///   1. The state machine  → [kStateMachine]
///   2. The boolean inputs → [kInputThinking], [kInputSpeaking]
///
/// If the file uses trigger inputs instead of booleans, swap [SMIBool]
/// for [SMITrigger] in [MascotController].
enum AvatarMood {
  /// Default resting state — plays the idle animation loop.
  idle,

  /// Displayed while a Gemini/AI API call is in flight.
  thinking,

  /// Displayed while text-to-speech is playing a response.
  speaking,
}

/// ── Rive configuration ──────────────────────────────────────────────────────
/// Adjust these constants to match the actual names inside mascot.riv.
/// You can discover the exact names at runtime by calling:
///   final names = await controller.getAvailableAnimations(); // (flutter_3d_controller)
/// or by inspecting the artboard inputs in the Rive editor.
/// ────────────────────────────────────────────────────────────────────────────
class RiveConfig {
  RiveConfig._();

  /// Name of the Rive State Machine inside mascot.riv.
  static const String stateMachine = 'State Machine 1';

  /// Boolean input name that drives the thinking state.
  /// Set to true while AI is processing; false otherwise.
  static const String inputThinking = 'isThinking';

  /// Boolean input name that drives the speaking state.
  /// Set to true while TTS is playing; false otherwise.
  static const String inputSpeaking = 'isSpeaking';
}
