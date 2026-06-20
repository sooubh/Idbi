import 'package:student_fin_os/models/avatar_mood.dart';

class WealthHealth {
  const WealthHealth({
    required this.score,
    required this.label,
    required this.mood,
    required this.explanation,
  });

  final int score;
  final String label;
  final AvatarMood mood;
  final String explanation;
}
