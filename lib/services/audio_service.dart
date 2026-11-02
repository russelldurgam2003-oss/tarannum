import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioPlayer _bgmPlayer = AudioPlayer();
  static bool _isPlaying = false;

  static Future<void> playBGM() async {
    if (_isPlaying) return;
    try {
      await _bgmPlayer.stop(); // إيقاف أي صوت سابق
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setSource(AssetSource('audio/bgm.mp3'));
      await _bgmPlayer.resume();
      _isPlaying = true;
    } catch (e) {
      print('Error playing BGM: $e');
    }
  }

  static Future<void> pauseBGM() async {
    if (!_isPlaying) return;
    try {
      await _bgmPlayer.pause();
      _isPlaying = false;
    } catch (e) {
      print('Error pausing BGM: $e');
    }
  }
}