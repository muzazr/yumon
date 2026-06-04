class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://yumon-api.vercel.app/api',
  );
}
