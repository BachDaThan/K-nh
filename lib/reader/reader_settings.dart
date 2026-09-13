import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

enum ReaderBg { dark, sepia, light }

class ReaderSettings {
  static const _kBg = 'kinh_reader_bg';
  static const _kFont = 'kinh_reader_font';
  static const _kHeight = 'kinh_reader_height';
  static const _kTts = 'kinh_reader_tts';
  static const _kAutoNext = 'kinh_reader_tts_autonext';

  ReaderBg bg = ReaderBg.dark;
  double fontSize = 18;
  double lineHeight = 1.65;
  bool ttsEnabled = false;
  bool ttsAutoNext = false;

  Color get backgroundColor {
    switch (bg) {
      case ReaderBg.dark:
        return const Color(0xFF121212);
      case ReaderBg.sepia:
        return const Color(0xFFF4ECD8);
      case ReaderBg.light:
        return const Color(0xFFFAFAFA);
    }
  }

  Color get textColor {
    switch (bg) {
      case ReaderBg.dark:
        return const Color(0xFFE8E8E8);
      case ReaderBg.sepia:
        return const Color(0xFF3E2723);
      case ReaderBg.light:
        return const Color(0xFF212121);
    }
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    bg = ReaderBg.values[p.getInt(_kBg) ?? 0];
    fontSize = p.getDouble(_kFont) ?? 18;
    lineHeight = p.getDouble(_kHeight) ?? 1.65;
    ttsEnabled = p.getBool(_kTts) ?? false;
    ttsAutoNext = p.getBool(_kAutoNext) ?? false;
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kBg, bg.index);
    await p.setDouble(_kFont, fontSize);
    await p.setDouble(_kHeight, lineHeight);
    await p.setBool(_kTts, ttsEnabled);
    await p.setBool(_kAutoNext, ttsAutoNext);
  }
}

final readerSettings = ReaderSettings();
