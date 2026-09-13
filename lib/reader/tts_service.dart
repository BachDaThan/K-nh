import 'package:flutter_tts/flutter_tts.dart';
import 'reader_settings.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  void Function()? onComplete;

  Future<void> init() async {
    if (_ready) return;
    await _tts.setLanguage('vi-VN');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    _tts.setCompletionHandler(() {
      onComplete?.call();
    });
    _ready = true;
  }

  Future<void> speak(String text) async {
    if (!readerSettings.ttsEnabled) return;
    await init();
    final chunk = text.length > 3500 ? text.substring(0, 3500) : text;
    await _tts.stop();
    await _tts.speak(chunk);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}

final ttsService = TtsService();
