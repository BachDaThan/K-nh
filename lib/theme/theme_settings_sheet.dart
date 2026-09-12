import 'package:flutter/material.dart';
import 'theme_service.dart';

class ThemeSettingsSheet extends StatelessWidget {
  final ThemeController controller;

  const ThemeSettingsSheet({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final s = controller.service;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (ctx, scroll) {
        return ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: ListView(
                controller: scroll,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text('Giao diện (Theme)',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  const Text('Chế độ', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Tối'),
                        selected: s.themeMode == ThemeMode.dark,
                        onSelected: (_) => controller.setMode(ThemeMode.dark),
                      ),
                      ChoiceChip(
                        label: const Text('Sáng'),
                        selected: s.themeMode == ThemeMode.light,
                        onSelected: (_) => controller.setMode(ThemeMode.light),
                      ),
                      ChoiceChip(
                        label: const Text('Hệ thống'),
                        selected: s.themeMode == ThemeMode.system,
                        onSelected: (_) =>
                            controller.setMode(ThemeMode.system),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Màu nhấn',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: ThemeService.accentPresets.entries.map((e) {
                      final selected = s.seedColor == e.value;
                      return GestureDetector(
                        onTap: () => controller.setSeed(e.value),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Color(e.value),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected ? Colors.white : Colors.white24,
                              width: selected ? 3 : 1,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text('Nền Dashboard',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ThemeService.presets.keys.map((id) {
                      final c = ThemeService.presets[id]!;
                      final selected = s.presetId == id;
                      return ChoiceChip(
                        label: Text(id),
                        selected: selected,
                        avatar: CircleAvatar(backgroundColor: c, radius: 8),
                        onSelected: (_) => controller.setPreset(id),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Độ mờ kính (blur): ${s.blurSigma.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Slider(
                    value: s.blurSigma,
                    min: 0,
                    max: 24,
                    divisions: 24,
                    label: s.blurSigma.toStringAsFixed(0),
                    onChanged: (v) => controller.setBlur(v),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Blur áp dụng cho hiệu ứng glass trên card Bento.\n'
                    'Không dùng custom CSS web — thuần Flutter.',
                    style: TextStyle(
                        fontSize: 12, color: Colors.white.withOpacity(0.45)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
