import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart';
import 'package:student_fin_os/models/avatar_mood.dart';
import 'package:student_fin_os/providers/wealth_advisor_providers.dart';

/// Rive-based avatar widget that reacts to [AvatarMood] driven by the
/// existing chat and voice assistant controllers.
///
/// State machine wiring:
///   [AvatarMood.idle]     → both inputs false  (Rive plays idle loop)
///   [AvatarMood.thinking] → isThinking = true   (Rive plays thinking loop)
///   [AvatarMood.speaking] → isSpeaking = true   (Rive plays speaking loop)
///
/// Adjust [RiveConfig.stateMachine], [RiveConfig.inputThinking], and
/// [RiveConfig.inputSpeaking] in avatar_mood.dart to match your mascot.riv.
class AvatarWidget extends ConsumerStatefulWidget {
  const AvatarWidget({
    super.key,
    this.width = 260,
    this.height = 260,
    this.fit = BoxFit.contain,
  });

  final double width;
  final double height;
  final BoxFit fit;

  @override
  ConsumerState<AvatarWidget> createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends ConsumerState<AvatarWidget> {
  StateMachineController? _smController;
  SMIBool? _isThinking;
  SMIBool? _isSpeaking;

  // Track last mood to avoid redundant Rive calls.
  AvatarMood _lastMood = AvatarMood.idle;

  void _onRiveInit(Artboard artboard) {
    final StateMachineController? controller =
        StateMachineController.fromArtboard(
      artboard,
      RiveConfig.stateMachine,
      onStateChange: _onStateChange,
    );

    if (controller == null) {
      debugPrint(
        '[AvatarWidget] ⚠️  State machine "${RiveConfig.stateMachine}" not '
        'found in mascot.riv. Available state machines: check the Rive editor.',
      );
      return;
    }

    artboard.addController(controller);
    _smController = controller;

    // Locate inputs by name — logs a warning if not found so the developer
    // can correct the names in RiveConfig without digging through the code.
    _isThinking =
        controller.findInput<bool>(RiveConfig.inputThinking) as SMIBool?;
    _isSpeaking =
        controller.findInput<bool>(RiveConfig.inputSpeaking) as SMIBool?;

    if (_isThinking == null) {
      debugPrint(
        '[AvatarWidget] ⚠️  Input "${RiveConfig.inputThinking}" not found. '
        'Check RiveConfig.inputThinking in avatar_mood.dart.',
      );
    }
    if (_isSpeaking == null) {
      debugPrint(
        '[AvatarWidget] ⚠️  Input "${RiveConfig.inputSpeaking}" not found. '
        'Check RiveConfig.inputSpeaking in avatar_mood.dart.',
      );
    }

    // Apply the current mood immediately after init (avoids one-frame glitch).
    _applyMood(ref.read(avatarMoodProvider));
  }

  void _onStateChange(String stateMachineName, String stateName) {
    // Optional: useful for debugging state transitions during development.
    debugPrint('[AvatarWidget] Rive state: $stateMachineName → $stateName');
  }

  void _applyMood(AvatarMood mood) {
    if (_smController == null) return;
    if (mood == _lastMood) return;
    _lastMood = mood;

    switch (mood) {
      case AvatarMood.idle:
        _isThinking?.value = false;
        _isSpeaking?.value = false;
      case AvatarMood.thinking:
        _isSpeaking?.value = false;
        _isThinking?.value = true;
      case AvatarMood.speaking:
        _isThinking?.value = false;
        _isSpeaking?.value = true;
    }
  }

  @override
  void dispose() {
    _smController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // React to mood changes driven by existing assistant controllers.
    ref.listen<AvatarMood>(avatarMoodProvider, (_, AvatarMood next) {
      _applyMood(next);
    });

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: RiveAnimation.asset(
        'assets/animations/mascot.riv',
        fit: widget.fit,
        stateMachines: const <String>[RiveConfig.stateMachine],
        onInit: _onRiveInit,
        placeHolder: const _AvatarPlaceholder(),
      ),
    );
  }
}

/// Shown while the Rive file is loading from the asset bundle.
class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    final Color shimmer =
        Theme.of(context).colorScheme.surfaceContainerHighest;
    return Container(
      decoration: BoxDecoration(
        color: shimmer,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}
