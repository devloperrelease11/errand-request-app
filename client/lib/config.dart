class AppConfig {
  const AppConfig._();

  static const String environmentKey = 'API_BASE_URL';

  static bool get isConfigured => const String.fromEnvironment(environmentKey).isNotEmpty;

  static String get apiBaseUrl {
    final value = const String.fromEnvironment(environmentKey);
    if (value.isEmpty) {
      throw StateError(
        'API_BASE_URL is not set. Run with --dart-define-from-file=config.json',
      );
    }
    return value.replaceFirst(RegExp(r'/+$'), '');
  }
}
