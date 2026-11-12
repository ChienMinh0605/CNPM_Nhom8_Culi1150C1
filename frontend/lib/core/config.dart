/// Cấu hình lấy lúc build: flutter run --dart-define=API_BASE_URL=http://...
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
}
