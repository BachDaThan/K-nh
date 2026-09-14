import 'package:shared_preferences/shared_preferences.dart';

import '../mesh/local_mesh_service.dart';
import '../premium/kinh_mesh_channel.dart';

class SosService {
  static const _msgKey = 'kinh_sos_message';
  static const defaultMsg =
      'SOS từ Kính — tôi cần hỗ trợ / đang kiểm tra liên lạc. (Tin broadcast gần)';

  String message = defaultMsg;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    message = p.getString(_msgKey) ?? defaultMsg;
  }

  Future<void> setMessage(String m) async {
    message = m.trim().isEmpty ? defaultMsg : m.trim();
    final p = await SharedPreferences.getInstance();
    await p.setString(_msgKey, message);
  }

  /// Gửi qua LAN mesh (nếu đang chạy) + native mesh (nếu có).
  Future<String> broadcast({String? extra}) async {
    await load();
    final text = extra == null || extra.isEmpty ? message : '$message\n$extra';
    final bits = <String>[];
    if (!localMeshService.running) {
      await localMeshService.start();
      bits.add('LAN mesh bật');
    }
    localMeshService.sendChat('🆘 $text');
    bits.add('LAN broadcast');
    if (kinhMeshChannel.running) {
      await kinhMeshChannel.broadcastText('🆘 $text');
      bits.add('Native mesh broadcast');
    } else {
      bits.add('Native mesh chưa chạy (chỉ LAN nếu có)');
    }
    return bits.join(' · ');
  }
}

final sosService = SosService();
