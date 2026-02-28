import 'dart:developer' as dev;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final voiceServiceProvider = Provider<VoiceService>((ref) {
  return VoiceService();
});

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _isSttInitialized = false;

  VoiceService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("fil-PH");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<bool> initSpeech() async {
    if (!_isSttInitialized) {
      try {
        _isSttInitialized = await _speech.initialize(
          onStatus: (status) => dev.log('[VoiceService] Status: $status'),
          onError: (error) => dev.log('[VoiceService] Error: $error'),
        );
      } catch (e) {
        dev.log('[VoiceService] Exception initializing speech: $e');
        _isSttInitialized = false;
      }
    }
    return _isSttInitialized;
  }

  Future<void> startListening(Function(String) onResult) async {
    if (!_isSttInitialized) {
      await initSpeech();
    }
    if (_isSttInitialized && !_speech.isListening) {
      // Use en-US or fil-PH? STT for Tagalog is usually supported as fil-PH or tl-PH.
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          }
        },
        localeId: 'fil-PH', // try filipino
        cancelOnError: true,
        partialResults: false,
      );
    }
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  bool get isListening => _speech.isListening;
}
