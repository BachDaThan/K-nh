import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/bento_item.dart';
import '../theme/theme_service.dart';

/// Ô Bento glass + viền sáng + glow theo accent.
class BentoCard extends StatefulWidget {
  final BentoItem item;
  final VoidCallback? onTap;

  const BentoCard({super.key, required this.item, this.onTap});

  @override
  State<BentoCard> createState() => _BentoCardState();
}

class _BentoCardState extends State<BentoCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final accent = item.accentColor ?? Theme.of(context).colorScheme.primary;
    final blur = themeController.service.blurSigma;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final glow = 0.25 + _pulse.value * 0.35;
        return child!;
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              final g = 0.18 + _pulse.value * 0.22;
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(g),
                      blurRadius: 18 + _pulse.value * 10,
                      spreadRadius: -2,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withOpacity(0.35),
                      accent.withOpacity(0.05),
                      Colors.white.withOpacity(isDark ? 0.08 : 0.4),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(1.4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(21),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(21),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  Colors.white.withOpacity(0.12),
                                  Colors.white.withOpacity(0.04),
                                  accent.withOpacity(0.08),
                                ]
                              : [
                                  Colors.white.withOpacity(0.85),
                                  Colors.white.withOpacity(0.65),
                                  accent.withOpacity(0.12),
                                ],
                        ),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accent.withOpacity(0.18),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withOpacity(0.35),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: item.iconBytes != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.memory(
                                      item.iconBytes!,
                                      width: 22,
                                      height: 22,
                                    ),
                                  )
                                : Icon(
                                    item.icon ?? Icons.apps_rounded,
                                    color: accent,
                                    size: 22,
                                  ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                  shadows: isDark
                                      ? [
                                          Shadow(
                                            color: accent.withOpacity(0.4),
                                            blurRadius: 8,
                                          ),
                                        ]
                                      : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (item.subtitle != null &&
                                  item.subtitle!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  item.subtitle!,
                                  style: TextStyle(
                                    color: textColor.withOpacity(0.72),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
