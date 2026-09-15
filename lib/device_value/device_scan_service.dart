import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

import 'device_specs.dart';

class DeviceScanService {
  final _info = DeviceInfoPlugin();

  Future<DeviceSpecs> scan() async {
    if (kIsWeb) {
      return const DeviceSpecs(
        brand: 'Web',
        model: 'Browser',
        device: 'web',
        androidVersion: '-',
        sdkInt: '-',
        isPhysical: false,
      );
    }
    if (Platform.isAndroid) {
      final a = await _info.androidInfo;
      return DeviceSpecs(
        brand: a.brand,
        model: a.model,
        device: a.device,
        androidVersion: a.version.release,
        sdkInt: '${a.version.sdkInt}',
        isPhysical: a.isPhysicalDevice,
      );
    }
    if (Platform.isWindows) {
      final w = await _info.windowsInfo;
      return DeviceSpecs(
        brand: 'Windows',
        model: w.productName,
        device: w.deviceId,
        androidVersion: w.displayVersion,
        sdkInt: '${w.buildNumber}',
        isPhysical: true,
      );
    }
    return const DeviceSpecs(
      brand: 'Unknown',
      model: 'Unknown',
      device: 'unknown',
      androidVersion: '-',
      sdkInt: '-',
    );
  }
}

final deviceScanService = DeviceScanService();
