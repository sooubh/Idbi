import 'package:student_fin_os/models/avatar_mood.dart';

class WealthAdvisoryReply {
  const WealthAdvisoryReply({
    required this.summary,
    required this.mood,
    required this.healthScore,
    required this.spokenLine,
    required this.recommendations,
    required this.actions,
    this.isFallback = false,
  });

  final String summary;
  final AvatarMood mood;
  final int healthScore;           // 0-100
  final String spokenLine;         // short TTS line
  final List<String> recommendations;
  final List<String> actions;
  final bool isFallback;
}
