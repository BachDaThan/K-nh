import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'device_scan_service.dart';
import 'device_specs.dart';
import 'valuation_engine.dart';

class DeviceValueScreen extends StatefulWidget {
  const DeviceValueScreen({super.key});

  @override
  State<DeviceValueScreen> createState() => _DeviceValueScreenState();
}

class _DeviceValueScreenState extends State<DeviceValueScreen> {
  DeviceSpecs? _specs;
  AppearanceGrade _appearance = AppearanceGrade.p95;
  int _battery = -1;
  bool _screenOk = true;
  bool _speakerOk = true;
  bool _micOk = true;
  bool _cameraOk = true;
  bool _frp = false;
  bool _warranty = false;
  bool _fullBox = false;
  ValuationResult? _result;
  bool _loading = true;
  final _money = NumberFormat.decimalPattern('vi_VN');

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await valuationEngine.load();
    final s = await deviceScanService.scan();
    setState(() {
      _specs = s;
      _loading = false;
    });
  }

  void _estimate() {
    final specs = _specs;
    if (specs == null) return;
    final r = valuationEngine.estimate(ValuationInput(
      specs: specs,
      appearance: _appearance,
      batteryHealthPercent: _battery,
      screenOk: _screenOk,
      speakerOk: _speakerOk,
      micOk: _micOk,
      cameraOk: _cameraOk,
      suspectedFrpOrMdm: _frp,
      hasWarranty: _warranty,
      fullBox: _fullBox,
    ));
    setState(() => _result = r);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Định giá thiết bị')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Miễn phí · không root · không lấy IMEI/serial. '
                  'Giá chỉ tham khảo (snapshot), không phải cam kết thu mua.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    title: Text(_specs?.label ?? '—'),
                    subtitle: Text(
                      'Android ${_specs?.androidVersion ?? "—"} · '
                      'SDK ${_specs?.sdkInt ?? "—"} · ${_specs?.device ?? ""}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () async {
                        setState(() => _loading = true);
                        await _init();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Ngoại hình (tự chọn)', style: Theme.of(context).textTheme.titleSmall),
                Wrap(
                  spacing: 6,
                  children: AppearanceGrade.values.map((g) {
                    return ChoiceChip(
                      label: Text(g.labelVi, style: const TextStyle(fontSize: 11)),
                      selected: _appearance == g,
                      onSelected: (_) => setState(() => _appearance = g),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Text('Bài test nhanh (tự xác nhận)', style: Theme.of(context).textTheme.titleSmall),
                SwitchListTile(
                  title: const Text('Màn hình ổn (không điểm chết nặng)'),
                  value: _screenOk,
                  onChanged: (v) => setState(() => _screenOk = v),
                ),
                SwitchListTile(
                  title: const Text('Loa nghe được'),
                  value: _speakerOk,
                  onChanged: (v) => setState(() => _speakerOk = v),
                ),
                SwitchListTile(
                  title: const Text('Micro ổn'),
                  value: _micOk,
                  onChanged: (v) => setState(() => _micOk = v),
                ),
                SwitchListTile(
                  title: const Text('Camera ổn'),
                  value: _cameraOk,
                  onChanged: (v) => setState(() => _cameraOk = v),
                ),
                SwitchListTile(
                  title: const Text('Nghi dính FRP / Google / MDM'),
                  subtitle: const Text('Trừ rất mạnh vào ước lượng'),
                  value: _frp,
                  onChanged: (v) => setState(() => _frp = v),
                ),
                SwitchListTile(
                  title: const Text('Còn bảo hành hãng'),
                  value: _warranty,
                  onChanged: (v) => setState(() => _warranty = v),
                ),
                SwitchListTile(
                  title: const Text('Fullbox phụ kiện'),
                  value: _fullBox,
                  onChanged: (v) => setState(() => _fullBox = v),
                ),
                ListTile(
                  title: const Text('Sức khỏe pin % (nếu biết)'),
                  subtitle: Text(_battery < 0 ? 'Không rõ' : '$_battery%'),
                  trailing: SizedBox(
                    width: 120,
                    child: Slider(
                      value: _battery < 0 ? 90 : _battery.toDouble(),
                      min: 50,
                      max: 100,
                      divisions: 50,
                      label: _battery < 0 ? '?' : '$_battery',
                      onChanged: (v) => setState(() => _battery = v.round()),
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _estimate,
                  icon: const Icon(Icons.calculate),
                  label: const Text('Ước lượng giá tham khảo'),
                ),
                if (_result != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_money.format(_result!.estimateVnd)} đ',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            'Khoảng ${_money.format(_result!.lowVnd)} – ${_money.format(_result!.highVnd)} đ',
                          ),
                          const SizedBox(height: 8),
                          Text(_result!.method, style: const TextStyle(fontSize: 12)),
                          Text(
                            'Bảng giá: ${_result!.priceAsOf.toIso8601String().substring(0, 10)}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          const SizedBox(height: 8),
                          Text(_result!.notes, style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
