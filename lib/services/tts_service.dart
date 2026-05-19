import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  final RxBool isSpeaking = false.obs;

  Future<void> init() async {
    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(() => isSpeaking.value = false);
    _tts.setCancelHandler(() => isSpeaking.value = false);
  }

  Future<void> speak(String text, {String language = 'en-US'}) async {
    await _tts.setLanguage(language);
    isSpeaking.value = true;
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    isSpeaking.value = false;
  }

  Future<void> toggle(String text, {String language = 'en-US'}) async {
    isSpeaking.value ? await stop() : await speak(text, language: language);
  }
}