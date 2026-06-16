import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();

  TtsService() {
    _initTts();
  }

  // Seting awal suara
  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US"); // Default EN
    await _flutterTts.setPitch(1.0);        // Nada normal
    await _flutterTts.setSpeechRate(0.5);   // Kelajuan (0.5 sedap didengar)
  }

  // Fungsi untuk bercakap
  Future<void> speak(String text, {String lang = "en-US"}) async {
    if (text.isEmpty) return;
    await _flutterTts.setLanguage(lang);
    await _flutterTts.speak(text);
  }

  // Fungsi stop (kot-kot pesakit salah tekan)
  Future<void> stop() async {
    await _flutterTts.stop();
  }

  // 🚀 J.A.R.V.I.S: TAMBAH DUA FUNGSI NI MAT!
  Future<void> setSpeed(double speed) async {
    await _flutterTts.setSpeechRate(speed);
  }

  Future<void> setPitch(double pitch) async {
    await _flutterTts.setPitch(pitch);
  }
}
