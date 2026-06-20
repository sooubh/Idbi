class FirestoreCodec {
  FirestoreCodec._();

  static DateTime readDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value)?.toUtc() ?? DateTime.now().toUtc();
    }
    return DateTime.now().toUtc();
  }

  static String writeDateTime(DateTime value) {
    return value.toUtc().toIso8601String();
  }

  static T readEnum<T extends Enum>(List<T> values, String? raw, T fallback) {
    if (raw == null) {
      return fallback;
    }
    for (final T value in values) {
      if (value.name == raw) {
        return value;
      }
    }
    return fallback;
  }

  static String writeEnum(Enum value) {
    return value.name;
  }
}
