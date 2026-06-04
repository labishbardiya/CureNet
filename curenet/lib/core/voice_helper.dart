import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/bhashini_tts_service.dart';
import 'app_config.dart';
import 'app_language.dart';
import '../services/bhashini_translate_service.dart';

/// Voice readout for ABHAy – Bhashini TTS (22 Indian languages) with flutter_tts fallback.
class VoiceHelper {
  static final FlutterTts _tts = FlutterTts();
  static bool _initialized = false;
  static String? lastError;

  /// Reactive speaking state — listeners can rebuild when this changes.
  static final ValueNotifier<bool> isSpeaking = ValueNotifier<bool>(false);

  static Future<void> init() async {
    if (_initialized) return;
    await _tts.awaitSpeakCompletion(true);
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    await _tts.setLanguage("en-IN");
    _tts.setCompletionHandler(() {
      isSpeaking.value = false;
    });
    _tts.setCancelHandler(() {
      isSpeaking.value = false;
    });
    _initialized = true;
  }

  /// Speak [text] in [language] (e.g. "English", "Hindi"). Uses Bhashini if API key is set, else flutter_tts.
  /// Automatically translates [text] to the target language before speaking.
  static Future<bool> speak(String text, {String? language, bool isAlreadyTranslated = false}) async {
    if (text.trim().isEmpty) return false;
    await init();
    lastError = null;

    // Stop any ongoing speech first
    await stop();

    final lang = language ?? AppLanguage.selectedLanguage.value;
    String spokenText = text;
    
    // Translate text before sending to TTS (unless already translated)
    if (!isAlreadyTranslated && lang != 'English') {
      try {
        spokenText = await BhashiniTranslateService.translateUiText(text, targetLanguage: lang);
      } catch (_) {}
    }

    isSpeaking.value = true;

    if (AppConfig.hasBhashiniKey) {
      final ok = await BhashiniTtsService.synthesizeAndPlay(
        text: spokenText,
        language: lang,
        gender: 'female',
      );
      if (ok) {
        isSpeaking.value = false;
        return true;
      }
      lastError = 'Voice failed. Check internet or Bhashini API key.';
    }
    if (lang != 'English') {
      await _tts.setLanguage(_flutterTtsLangCode(lang));
    } else {
      await _tts.setLanguage("en-IN");
    }
    final result = await _tts.speak(spokenText);
    if (result == 1 || result == "1" || result == "success") return true;
    isSpeaking.value = false;
    lastError ??= 'Device text-to-speech not available on this device.';
    return false;
  }

  static String _flutterTtsLangCode(String lang) {
    final l = lang.toLowerCase();
    if (l == 'hindi') return 'hi-IN';
    if (l == 'bengali') return 'bn-IN';
    if (l == 'marathi') return 'mr-IN';
    if (l == 'telugu') return 'te-IN';
    if (l == 'tamil') return 'ta-IN';
    if (l == 'gujarati') return 'gu-IN';
    if (l == 'kannada') return 'kn-IN';
    if (l == 'malayalam') return 'ml-IN';
    if (l == 'punjabi') return 'pa-IN';
    return 'en-IN';
  }

  /// Stop all ongoing speech (both Bhashini and flutter_tts).
  static Future<void> stop() async {
    isSpeaking.value = false;
    await BhashiniTtsService.stop();
    await _tts.stop();
  }
}
