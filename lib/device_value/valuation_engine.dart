import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'device_specs.dart';

/// Định giá **tham khảo** local-first.
/// Không gửi IMEI/serial. Không hardcode “giá thật thị trường” cố định —
/// dùng snapshot JSON (asset + tùy chọn URL remote).
class ValuationEngine {
  static const _cacheKey = 'kinh_price_snapshot_v1';
  static const _cacheAtKey = 'kinh_price_snapshot_at_v1';

  /// URL tùy chọn (GitHub raw / Pages). Để trống = chỉ asset.
  static const remoteSnapshotUrl = '';

  Map<String, dynamic>? _table;
  DateTime? _asOf;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    final at = prefs.getString(_cacheAtKey);
    if (cached != null) {
      try {
        _table = jsonDecode(cached) as Map<String, dynamic>;
        _asOf = at != null ? DateTime.tryParse(at) : null;
      } catch (_) {}
    }
    // Asset baseline
    try {
      final raw = await rootBundle.loadString('assets/price_snapshot.json');
      final j = jsonDecode(raw) as Map<String, dynamic>;
      if (_table == null) {
        _table = j;
        _asOf = DateTime.tryParse('${j['asOf'] ?? ''}');
      }
    } catch (_) {}

    if (remoteSnapshotUrl.isNotEmpty) {
      try {
        final r = await http
            .get(Uri.parse(remoteSnapshotUrl))
            .timeout(const Duration(seconds: 8));
        if (r.statusCode == 200) {
          final j = jsonDecode(r.body) as Map<String, dynamic>;
          _table = j;
          _asOf = DateTime.tryParse('${j['asOf'] ?? ''}') ?? DateTime.now();
          await prefs.setString(_cacheKey, r.body);
          await prefs.setString(_cacheAtKey, _asOf!.toIso8601String());
        }
      } catch (_) {}
    }
  }

  /// Giá cơ sở VND theo model/brand (rất thô — chỉ tham khảo).
  int _basePrice(DeviceSpecs s) {
    final models = (_table?['models'] as Map?)?.cast<String, dynamic>() ?? {};
    final key = s.model.toLowerCase();
    final brand = s.brand.toLowerCase();
    for (final e in models.entries) {
      if (key.contains(e.key.toLowerCase()) || e.key.toLowerCase().contains(key)) {
        final v = e.value;
        if (v is num) return v.toInt();
        if (v is Map && v['vnd'] is num) return (v['vnd'] as num).toInt();
      }
    }
    final brands = (_table?['brands'] as Map?)?.cast<String, dynamic>() ?? {};
    for (final e in brands.entries) {
      if (brand.contains(e.key.toLowerCase())) {
        final v = e.value;
        if (v is num) return v.toInt();
      }
    }
    // Fallback thô theo SDK (không phải giá thị trường)
    final sdk = int.tryParse(s.sdkInt) ?? 30;
    return (2000000 + (sdk - 28) * 400000).clamp(500000, 15000000);
  }

  ValuationResult estimate(ValuationInput input) {
    var base = _basePrice(input.specs).toDouble();
    base *= input.appearance.factor;

    if (input.batteryHealthPercent >= 0) {
      if (input.batteryHealthPercent < 80) {
        base *= 0.92;
      } else if (input.batteryHealthPercent < 90) {
        base *= 0.96;
      }
    }
    if (!input.screenOk) base *= 0.85;
    if (!input.speakerOk) base *= 0.95;
    if (!input.micOk) base *= 0.95;
    if (!input.cameraOk) base *= 0.90;
    if (input.suspectedFrpOrMdm) base *= 0.25;
    if (input.hasWarranty) base *= 1.06;
    if (input.fullBox) base *= 1.04;

    final mid = base.round();
    final low = (mid * 0.88).round();
    final high = (mid * 1.12).round();
    final asOf = _asOf ?? DateTime.now();
    final notes = StringBuffer()
      ..writeln('Chỉ mang tính tham khảo, không phải giá thu mua cam kết.')
      ..writeln('Không thu IMEI/serial. Ngoại hình & khóa bảo mật do bạn tự khai.')
      ..writeln('Model quét: ${input.specs.label} · Android ${input.specs.androidVersion}');
    if (input.suspectedFrpOrMdm) {
      notes.writeln('Đã trừ mạnh do nghi khóa FRP/MDM/Google account.');
    }

    return ValuationResult(
      estimateVnd: mid,
      lowVnd: low,
      highVnd: high,
      method: _table == null
          ? 'Ước lượng thô (chưa có bảng giá)'
          : 'Snapshot local/remote + hệ số tình trạng',
      notes: notes.toString().trim(),
      priceAsOf: asOf,
      offlineSnapshot: true,
    );
  }
}

final valuationEngine = ValuationEngine();
