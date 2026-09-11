import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/bento_item.dart';

/// Một ô Bento Grid, phong cách Glassmorphism trên nền tối.
class BentoCard extends StatelessWidget {
  final BentoItem item;
  final VoidCallback? onTap;

  const BentoCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = item.accentColor ?? Theme.of(context).colorScheme.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Material(
          color: Colors.white.withOpacity(0.06),
          child: InkWell(
            onTap: onTap,
            splashColor: accent.withOpacity(0.25),
            highlightColor: accent.withOpacity(0.12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.10),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(item.icon, color: accent, size: 26),
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
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
