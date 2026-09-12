import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Kích thước một ô trong lưới Bento Grid, tính theo số cột/hàng chiếm dụng.
enum BentoSize {
  small, // 1x1
  wide, // 2x1
  tall, // 1x2
  large, // 2x2
}

/// Đại diện cho một ô (widget hoặc lối tắt app) trên Dashboard.
class BentoItem {
  final String id;
  final String title;
  final IconData? icon;
  final Uint8List? iconBytes; // icon app thật (ưu tiên hơn `icon` nếu có)
  final BentoSize size;
  final Color? accentColor;
  final String? packageName; // khác null nếu đây là lối tắt app đã ghim

  const BentoItem({
    required this.id,
    required this.title,
    this.icon,
    this.iconBytes,
    this.size = BentoSize.small,
    this.accentColor,
    this.packageName,
  });

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
