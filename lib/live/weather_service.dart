import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

/// Thời tiết Open-Meteo. Ưu tiên vị trí IP (không xin GPS), fallback TP.HCM.
/// Có thể ghim lat/lon thủ công sau này qua prefs.
class WeatherService {
  static const _latDefault = 10.8231;
  static const _lonDefault = 106.6297;
  static const _placeDefault = 'TP.HCM';
  static const _kUseIp = 'kinh_weather_use_ip';

  WeatherSnapshot? last;
  DateTime? _lastFetch;
  bool useIpLocation = true;

  Future<void> loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    useIpLocation = p.getBool(_kUseIp) ?? true;
  }

  Future<void> setUseIpLocation(bool v) async {
    useIpLocation = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kUseIp, v);
    last = null;
    _lastFetch = null;
  }

  Future<WeatherSnapshot?> fetch({bool force = false}) async {
    if (!force &&
        last != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < const Duration(minutes: 20)) {
      return last;
    }
    try {
      double lat = _latDefault;
      double lon = _lonDefault;
      String place = _placeDefault;

      if (useIpLocation) {
        final loc = await _ipLocation();
        if (loc != null) {
          lat = loc.$1;
          lon = loc.$2;
          place = loc.$3;
        }
      }

      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lon'
        '&current=temperature_2m,weather_code'
        '&timezone=auto',
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
        place: place,
      );
      _lastFetch = DateTime.now();
      return last;
    } catch (_) {
      return last;
    }
  }

  /// (lat, lon, label)
  Future<(double, double, String)?> _ipLocation() async {
    try {
      final res = await http
          .get(Uri.parse('https://ipapi.co/json/'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      final lat = (j['latitude'] as num?)?.toDouble();
      final lon = (j['longitude'] as num?)?.toDouble();
      if (lat == null || lon == null) return null;
      final city = (j['city'] as String?) ?? '';
      final region = (j['region'] as String?) ?? '';
      final country = (j['country_code'] as String?) ?? '';
      final place = [city, region, country]
          .where((s) => s.trim().isNotEmpty)
          .join(', ');
      return (lat, lon, place.isEmpty ? 'IP location' : place);
    } catch (_) {
      return null;
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
