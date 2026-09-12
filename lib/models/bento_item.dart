import 'dart:typed_data';
import 'package:flutter/material.dart';

enum BentoSize { small, wide, tall, large }

class BentoItem {
  final String id;
  final String title;
  final String? subtitle; // live text trên thẻ
  final IconData? icon;
  final Uint8List? iconBytes;
  final BentoSize size;
  final Color? accentColor;
  final String? packageName;

  const BentoItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconBytes,
    this.size = BentoSize.small,
    this.accentColor,
    this.packageName,
  });

  BentoItem copyWith({
    String? title,
    String? subtitle,
    IconData? icon,
    Uint8List? iconBytes,
    BentoSize? size,
    Color? accentColor,
    String? packageName,
  }) {
    return BentoItem(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      iconBytes: iconBytes ?? this.iconBytes,
      size: size ?? this.size,
      accentColor: accentColor ?? this.accentColor,
      packageName: packageName ?? this.packageName,
    );
  }

  int get crossAxisCellCount {
    switch (size) {
      case BentoSize.small:
      case BentoSize.tall:
        return 1;
      case BentoSize.wide:
      case BentoSize.large:
        return 2;
    }
  }

  int get mainAxisCellCount {
    switch (size) {
      case BentoSize.small:
      case BentoSize.wide:
        return 1;
      case BentoSize.tall:
      case BentoSize.large:
        return 2;
    }
  }
}
