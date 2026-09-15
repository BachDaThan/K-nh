class DeviceSpecs {
  final String brand;
  final String model;
  final String device;
  final String androidVersion;
  final String sdkInt;
  final int? ramMb;
  final bool isPhysical;

  const DeviceSpecs({
    required this.brand,
    required this.model,
    required this.device,
    required this.androidVersion,
    required this.sdkInt,
    this.ramMb,
    this.isPhysical = true,
  });

  String get label => '$brand $model'.trim();

  Map<String, dynamic> toJson() => {
        'brand': brand,
        'model': model,
        'device': device,
        'androidVersion': androidVersion,
        'sdkInt': sdkInt,
        'ramMb': ramMb,
        'isPhysical': isPhysical,
      };
}

enum AppearanceGrade { likeNew, p99, p95, p90, fair, poor }

extension AppearanceGradeX on AppearanceGrade {
  String get labelVi => switch (this) {
        AppearanceGrade.likeNew => 'Như mới (Like new)',
        AppearanceGrade.p99 => '99%',
        AppearanceGrade.p95 => '95%',
        AppearanceGrade.p90 => '90%',
        AppearanceGrade.fair => 'Trung bình',
        AppearanceGrade.poor => 'Kém / trầy nhiều',
      };

  double get factor => switch (this) {
        AppearanceGrade.likeNew => 1.0,
        AppearanceGrade.p99 => 0.97,
        AppearanceGrade.p95 => 0.93,
        AppearanceGrade.p90 => 0.88,
        AppearanceGrade.fair => 0.75,
        AppearanceGrade.poor => 0.55,
      };
}

class ValuationInput {
  final DeviceSpecs specs;
  final AppearanceGrade appearance;
  final int batteryHealthPercent; // 0–100, -1 = unknown
  final bool screenOk;
  final bool speakerOk;
  final bool micOk;
  final bool cameraOk;
  final bool suspectedFrpOrMdm;
  final bool hasWarranty;
  final bool fullBox;

  const ValuationInput({
    required this.specs,
    this.appearance = AppearanceGrade.p95,
    this.batteryHealthPercent = -1,
    this.screenOk = true,
    this.speakerOk = true,
    this.micOk = true,
    this.cameraOk = true,
    this.suspectedFrpOrMdm = false,
    this.hasWarranty = false,
    this.fullBox = false,
  });
}

class ValuationResult {
  final int estimateVnd;
  final int lowVnd;
  final int highVnd;
  final String method;
  final String notes;
  final DateTime priceAsOf;
  final bool offlineSnapshot;

  const ValuationResult({
    required this.estimateVnd,
    required this.lowVnd,
    required this.highVnd,
    required this.method,
    required this.notes,
    required this.priceAsOf,
    this.offlineSnapshot = true,
  });
}
