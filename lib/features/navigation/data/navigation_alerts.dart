import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';

/// Vibration und Sprachansage (SPEC 5.7).
abstract interface class NavigationAlerts {
  Future<void> vibrate();
  Future<void> speak(String text);
  Future<void> stop();
}

class DeviceNavigationAlerts implements NavigationAlerts {
  DeviceNavigationAlerts();

  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  Future<void> _init() async {
    if (_ready) return;
    _ready = true;
    await _tts.setLanguage('de-DE');
    // Etwas langsamer als Standard – besser verständlich.
    await _tts.setSpeechRate(0.45);
    await _tts.awaitSpeakCompletion(true);
  }

  @override
  Future<void> vibrate() async {
    try {
      if (await Vibration.hasVibrator()) {
        // Zweimal lang – deutlich spürbar, auch in der Jackentasche.
        await Vibration.vibrate(pattern: [0, 600, 300, 600]);
      }
    } on Object {
      // Ohne Vibrationsmotor einfach weiter.
    }
  }

  @override
  Future<void> speak(String text) async {
    try {
      await _init();
      await _tts.speak(text);
    } on Object {
      // Ohne Sprachausgabe bleiben Banner und Vibration.
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } on Object {
      // ignorieren
    }
  }
}
