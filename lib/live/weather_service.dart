import 'dart:convert';
import 'package:http/http.dart' as http;

/// Thời tiết live qua Open-Meteo (không cần API key).
class WeatherSnapshot {
  final double tempC;
  final String label;
  final String place;

  WeatherSnapshot({
    required this.tempC,
    required this.label,
    required this.place,
  });

  String get headline => '${tempC.toStringAsFixed(0)}°C · $label';
}

class WeatherService {
  // Mặc định TP.HCM — không xin quyền GPS.
  static const _lat = 10.8231;
  static const _lon = 106.6297;
  static const _place = 'TP.HCM';

  WeatherSnapshot? last;
  DateTime? _lastFetch;

  Future<WeatherSnapshot?> fetch({bool force = false}) async {
    if (!force &&
        last != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < const Duration(minutes: 20)) {
      return last;
    }
    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$_lat&longitude=$_lon'
        '&current=temperature_2m,weather_code'
        '&timezone=Asia%2FHo_Chi_Minh',
      );
      final res =
          await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return last;
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      final cur = j['current'] as Map<String, dynamic>?;
      if (cur == null) return last;
      final temp = (cur['temperature_2m'] as num?)?.toDouble() ?? 0;
      final code = (cur['weather_code'] as num?)?.toInt() ?? 0;
      last = WeatherSnapshot(
        tempC: temp,
        label: _codeToLabel(code),
        place: _place,
      );
      _lastFetch = DateTime.now();
      return last;
    } catch (_) {
      return last;
    }
  }

  static String _codeToLabel(int code) {
    if (code == 0) return 'Quang';
    if (code <= 3) return 'Ít mây';
    if (code <= 48) return 'Sương';
    if (code <= 67) return 'Mưa';
    if (code <= 77) return 'Tuyết';
    if (code <= 82) return 'Mưa rào';
    if (code <= 99) return 'Giông';
    return '—';
  }
}
