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
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
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
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text('Giao diện', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Hiện Sidebar'),
                    subtitle: const Text('Thanh lối tắt bên trái Dashboard'),
                    value: s.sidebarVisible,
                    onChanged: (v) => controller.setSidebarVisible(v),
                  ),
                  const Divider(),
                  const Text('Chế độ', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: [
                    ChoiceChip(label: const Text('Tối'), selected: s.themeMode == ThemeMode.dark, onSelected: (_) => controller.setMode(ThemeMode.dark)),
                    ChoiceChip(label: const Text('Sáng'), selected: s.themeMode == ThemeMode.light, onSelected: (_) => controller.setMode(ThemeMode.light)),
                    ChoiceChip(label: const Text('Hệ thống'), selected: s.themeMode == ThemeMode.system, onSelected: (_) => controller.setMode(ThemeMode.system)),
                  ]),
                  const SizedBox(height: 16),
                  const Text('Màu nhấn', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10, runSpacing: 10,
                    children: ThemeService.accentPresets.entries.map((e) {
                      final sel = s.seedColor == e.value;
                      return GestureDetector(
                        onTap: () => controller.setSeed(e.value),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: Color(e.value),
                            shape: BoxShape.circle,
                            border: Border.all(color: sel ? Colors.white : Colors.white24, width: sel ? 3 : 1),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Nền Dashboard', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: ThemeService.presets.keys.map((id) {
                      final c = ThemeService.presets[id]!;
                      return ChoiceChip(
                        label: Text(id),
                        selected: s.presetId == id,
                        avatar: CircleAvatar(backgroundColor: c, radius: 8),
                        onSelected: (_) => controller.setPreset(id),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text('Blur kính: ${s.blurSigma.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Slider(
                    value: s.blurSigma, min: 0, max: 24, divisions: 24,
                    onChanged: (v) => controller.setBlur(v),
                  ),
                  Text(
                    'Wallpaper ảnh tùy chọn: dùng preset nền ở trên (không cần quyền thư viện).\n'
                    'Browser chrome theo màu Theme của app.',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
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
