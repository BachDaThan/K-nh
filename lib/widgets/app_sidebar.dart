import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Sidebar lối tắt — Browser, AI Builder, Theme, Update, app đã ghim.
class AppSidebar extends StatelessWidget {
  final int selectedIndex;
  final VoidCallback onHome;
  final VoidCallback onBrowser;
  final VoidCallback onAiBuilder;
  final VoidCallback onTheme;
  final VoidCallback? onCheckUpdate;
  final List<SidebarPin> pins;
  final void Function(SidebarPin pin)? onPinTap;

  const AppSidebar({
    super.key,
    this.selectedIndex = 0,
    required this.onHome,
    required this.onBrowser,
    required this.onAiBuilder,
    required this.onTheme,
    this.onCheckUpdate,
    this.pins = const [],
    this.onPinTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
      child: SafeArea(
        child: SizedBox(
          width: 72,
          child: Column(
            children: [
              const SizedBox(height: 8),
              _NavIcon(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: selectedIndex == 0,
                color: cs.primary,
                onTap: onHome,
              ),
              _NavIcon(
                icon: Icons.search_rounded,
                label: 'Web',
                selected: false,
                color: cs.primary,
                onTap: onBrowser,
              ),
              _NavIcon(
                icon: Icons.auto_awesome,
                label: 'AI',
                selected: false,
                color: cs.primary,
                onTap: onAiBuilder,
              ),
              _NavIcon(
                icon: Icons.palette_outlined,
                label: 'Theme',
                selected: false,
                color: cs.primary,
                onTap: onTheme,
              ),
              if (onCheckUpdate != null)
                _NavIcon(
                  icon: Icons.system_update_alt,
                  label: 'Update',
                  selected: false,
                  color: cs.primary,
                  onTap: onCheckUpdate!,
                ),
              if (pins.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: pins.length,
                    itemBuilder: (_, i) {
                      final pin = pins[i];
                      return _NavIcon(
                        icon: pin.icon ?? Icons.apps,
                        label: pin.label,
                        selected: false,
                        color: cs.primary,
                        imageBytes: pin.iconBytes,
                        onTap: () => onPinTap?.call(pin),
                      );
                    },
                  ),
                ),
              ] else
                const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Kính',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.35),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SidebarPin {
  final String id;
  final String label;
  final IconData? icon;
  final Uint8List? iconBytes;
  final String? packageName;

  const SidebarPin({
    required this.id,
    required this.label,
    this.icon,
    this.iconBytes,
    this.packageName,
  });
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final Uint8List? imageBytes;

  const _NavIcon({
    required this.icon,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
    this.imageBytes,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected
                      ? color.withOpacity(0.28)
                      : Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? color.withOpacity(0.65) : Colors.white10,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.45),
                            blurRadius: 14,
                            spreadRadius: 0,
                          ),
                        ]
                      : null,
                ),
                clipBehavior: Clip.antiAlias,
                child: imageBytes != null && imageBytes!.isNotEmpty
                    ? Image.memory(
                        imageBytes!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(icon, color: color, size: 22),
                      )
                    : Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white.withOpacity(0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
