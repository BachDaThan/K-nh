/// Hai bản cài song song:
/// - core  → `Kinh.apk` / `Kinh-Windows.zip`  (applicationId com.bachdathan.kinh)
/// - plus  → `Kinh-Plus.apk` / `Kinh-Plus-Windows.zip` (com.bachdathan.kinh.plus)
///
/// Build: `--dart-define=KINH_EDITION=plus`
class AppEdition {
  static const raw =
      String.fromEnvironment('KINH_EDITION', defaultValue: 'core');

  static bool get isPlus => raw == 'plus';
  static bool get isCore => !isPlus;

  static String get displayName => isPlus ? 'Kính Plus' : 'Kính';

  static String get subtitle => isPlus
      ? 'Bản A — tiện ích giả (CSS/JS/filter list)'
      : 'Bản gốc — dashboard + trình duyệt';
}
