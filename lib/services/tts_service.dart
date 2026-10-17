import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      await _tts.setLanguage('ar');
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      // انتظار انتهاء الإعداد
      await _tts.awaitSpeakCompletion(true);
      _initialized = true;
    } catch (e) {
      print('خطأ في تهيئة الصوت: $e');
    }
  }

  Future<void> speak(String text) async {
    try {
      await init();
      await _tts.stop();
      await Future.delayed(const Duration(milliseconds: 300));
      await _tts.speak(text);
    } catch (e) {
      print('خطأ في النطق: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  void dispose() {
    _tts.stop();
  }
}