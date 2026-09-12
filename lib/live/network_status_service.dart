import 'package:connectivity_plus/connectivity_plus.dart';

/// Trạng thái mạng live (Wi‑Fi / 4G / offline) — không cần quyền đặc biệt.
class NetworkStatus {
  final String title; // Wi‑Fi / Mobile / Offline
  final String detail; // Đã kết nối / Không có mạng
  final bool online;

  NetworkStatus({
    required this.title,
    required this.detail,
    required this.online,
  });

  String get headline => '$title · $detail';
}

class NetworkStatusService {
  NetworkStatus? last;

  Future<NetworkStatus> fetch() async {
    try {
      final result = await Connectivity().checkConnectivity();
      // connectivity_plus 6.x: List<ConnectivityResult>
      final list = result is List
          ? (result as List).cast<ConnectivityResult>()
          : <ConnectivityResult>[result as ConnectivityResult];

      NetworkStatus status;
      if (list.contains(ConnectivityResult.none) || list.isEmpty) {
        status = NetworkStatus(
          title: 'Offline',
          detail: 'Không mạng',
          online: false,
        );
      } else if (list.contains(ConnectivityResult.wifi)) {
        status = NetworkStatus(
          title: 'Wi‑Fi',
          detail: 'Đã kết nối',
          online: true,
        );
      } else if (list.contains(ConnectivityResult.mobile)) {
        status = NetworkStatus(
          title: 'Di động',
          detail: '4G/5G',
          online: true,
        );
      } else if (list.contains(ConnectivityResult.ethernet)) {
        status = NetworkStatus(
          title: 'Ethernet',
          detail: 'Có dây',
          online: true,
        );
      } else {
        status = NetworkStatus(
          title: 'Mạng',
          detail: 'Đã kết nối',
          online: true,
        );
      }
      last = status;
      return status;
    } catch (_) {
      return last ??
          NetworkStatus(title: 'Mạng', detail: '—', online: false);
    }
  }

  Stream<List<ConnectivityResult>> get onChange =>
      Connectivity().onConnectivityChanged;
}
