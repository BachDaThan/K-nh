import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/bento_item.dart';
import '../theme/theme_service.dart';

class BentoCard extends StatelessWidget {
  final BentoItem item;
  final VoidCallback? onTap;

  const BentoCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = item.accentColor ?? Theme.of(context).colorScheme.primary;
    final blur = themeController.service.blurSigma;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Material(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
          child: InkWell(
            onTap: onTap,
            splashColor: accent.withOpacity(0.25),
            highlightColor: accent.withOpacity(0.12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.10) : Colors.black12,
                ),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  item.iconBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.memory(item.iconBytes!, width: 26, height: 26),
                        )
                      : Icon(item.icon ?? Icons.apps_rounded, color: accent, size: 26),
                  Text(
                    item.title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
