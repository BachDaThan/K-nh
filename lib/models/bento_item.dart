import 'package:flutter/material.dart';

/// Kích thước một ô trong lưới Bento Grid, tính theo số cột/hàng chiếm dụng.
enum BentoSize {
  small, // 1x1
  wide, // 2x1
  tall, // 1x2
  large, // 2x2
}

/// Đại diện cho một ô (widget hoặc lối tắt app) trên Dashboard.
/// Đây là model tối giản cho Bước 1 — sau này sẽ mở rộng thêm
/// loại "appShortcut" (mở app hệ thống qua Intent) ở bước App Launcher.
class BentoItem {
  final String id;
  final String title;
  final IconData icon;
  final BentoSize size;
  final Color? accentColor;

  const BentoItem({
    required this.id,
    required this.title,
    required this.icon,
    this.size = BentoSize.small,
    this.accentColor,
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
