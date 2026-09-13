import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'reader_settings.dart';

/// TTS dùng giọng **máy** (offline, free, không API key).
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  bool speaking = false;
  void Function()? onComplete;
  double volume = 1.0;
  String? voiceName;

  Future<void> init() async {
    if (_ready) return;
    try {
      await _tts.setLanguage('vi-VN');
    } catch (_) {
      await _tts.setLanguage('en-US');
    }
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(volume);
    await _tts.setPitch(1.0);
    // Giúp TTS ít bị cắt khi khóa màn hình (Android/iOS hỗ trợ tùy máy)
    try {
      await _tts.setSharedInstance(true);
    } catch (_) {}
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
            IosTextToSpeechAudioCategoryOptions.duckOthers,
          ],
          IosTextToSpeechAudioMode.voicePrompt,
        );
      } catch (_) {}
    }
    _tts.setCompletionHandler(() {
      speaking = false;
      onComplete?.call();
    });
    _tts.setCancelHandler(() {
      speaking = false;
    });
    _tts.setErrorHandler((msg) {
      speaking = false;
    });
    _ready = true;
  }

  Future<List<Map<String, String>>> listVoices() async {
    await init();
    try {
      final raw = await _tts.getVoices;
      if (raw is! List) return [];
      final out = <Map<String, String>>[];
      for (final v in raw) {
        if (v is Map) {
          final name = '${v['name'] ?? ''}';
          final locale = '${v['locale'] ?? ''}';
          if (name.isEmpty) continue;
          out.add({'name': name, 'locale': locale});
        }
      }
      out.sort((a, b) {
        final av = a['locale']!.toLowerCase().contains('vi') ? 0 : 1;
        final bv = b['locale']!.toLowerCase().contains('vi') ? 0 : 1;
        if (av != bv) return av - bv;
        return a['name']!.compareTo(b['name']!);
      });
      return out;
    } catch (_) {
      return [];
    }
  }

  Future<void> setVoiceByName(String? name, {String? locale}) async {
    voiceName = name;
    await init();
    if (name == null) return;
    try {
      await _tts.setVoice({'name': name, if (locale != null) 'locale': locale});
    } catch (_) {}
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    await init();
    await _tts.setVolume(volume);
  }

  Future<void> setRate(double r) async {
    await init();
    await _tts.setSpeechRate(r.clamp(0.1, 1.0));
  }

  /// Đọc dài: chia câu để TTS không bị cắt giữa chừng khi khóa màn hình.
  Future<void> speakLong(String text) async {
    await init();
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.isEmpty) return;
    await _tts.stop();
    speaking = true;
    try {
      await WakelockPlus.enable();
    } catch (_) {}

    final chunks = _chunk(clean, 800);
    for (var i = 0; i < chunks.length; i++) {
      if (!speaking) break;
      await _tts.speak(chunks[i]);
      // Đợi hoàn thành chunk (Android/iOS)
      try {
        await _tts.awaitSpeakCompletion(true);
      } catch (_) {
        await Future<void>.delayed(
          Duration(milliseconds: 400 + chunks[i].length * 40),
        );
      }
    }
    speaking = false;
    try {
      await WakelockPlus.disable();
    } catch (_) {}
    onComplete?.call();
  }

  Future<void> speak(String text) async {
    if (!readerSettings.ttsEnabled && text.length < 5) return;
    await speakLong(text);
  }

  Future<void> stop() async {
    speaking = false;
    await _tts.stop();
    try {
      await WakelockPlus.disable();
    } catch (_) {}
  }

  List<String> _chunk(String text, int maxLen) {
    final parts = <String>[];
    var rest = text;
    while (rest.length > maxLen) {
      var cut = rest.lastIndexOf(RegExp(r'[.!?\n。]'), maxLen);
      if (cut < maxLen ~/ 3) cut = maxLen;
      parts.add(rest.substring(0, cut + 1).trim());
      rest = rest.substring(cut + 1).trim();
    }
    if (rest.isNotEmpty) parts.add(rest);
    return parts;
  }
}

final ttsService = TtsService();
