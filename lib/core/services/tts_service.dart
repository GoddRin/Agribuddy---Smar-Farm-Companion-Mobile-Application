import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import 'audio_service.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  final Ref _ref;
  bool _isPlaying = false;
  bool _isInitialized = false;
  Function(bool)? _onStateChanged;
  final Completer<void> _initCompleter = Completer<void>();

  TtsService(this._ref) {
    _init();
  }

  bool get isPlaying => _isPlaying;

  set onStateChanged(Function(bool)? handler) => _onStateChanged = handler;

  Future<void> _ensureInitFinished() async {
    await _initCompleter.future;
  }

  Future<void> _init() async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          const [
            IosTextToSpeechAudioCategoryOptions.duckOthers,
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
          ],
          IosTextToSpeechAudioMode.spokenAudio,
        );
      }

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final engines = await _tts.getEngines;
        if (engines.contains('com.google.android.tts')) {
          await _tts.setEngine('com.google.android.tts');
        }
        try {
          await _tts.setAudioAttributesForNavigation();
        } catch (e) {
          debugPrint('TTS setAudioAttributesForNavigation: $e');
        }
      }

      try {
        await _tts.awaitSpeakCompletion(true);
      } catch (e) {
        debugPrint('TTS awaitSpeakCompletion: $e');
      }

      await _tts.setLanguage('en-US');
      await _tts.setPitch(0.72);
      await _tts.setSpeechRate(0.42);
      final vol = _ref.read(settingsProvider.notifier).voiceVolume;
      await _tts.setVolume(vol);

      try {
        final voices = await _tts.getVoices;
        if (voices.isNotEmpty) {
          dynamic bestVoice;
          int bestRank = -1;

          for (final v in voices) {
            final name = v['name'].toString().toLowerCase();
            int rank = 0;
            if (name.contains('male')) rank += 10;
            if (name.contains('man')) rank += 10;
            if (name.contains('guy')) rank += 8;
            if (name.contains('network')) rank += 2;

            if (rank > bestRank) {
              bestRank = rank;
              bestVoice = v;
            }
          }

          if (bestVoice != null && bestRank > 0) {
            await _tts.setVoice({'name': bestVoice['name'], 'locale': bestVoice['locale']});
            debugPrint('👨‍🌾 Mang Pedro selected friendly voice: ${bestVoice['name']}');
          } else {
            await _tts.setPitch(0.70);
          }
        }
      } catch (voiceError) {
        debugPrint('⚠️ Voice selection failed, using friendly fallback: $voiceError');
        await _tts.setPitch(0.70);
      }

      _tts.setStartHandler(() {
        _isPlaying = true;
        _onStateChanged?.call(true);
      });

      _tts.setCompletionHandler(() {
        _isPlaying = false;
        _onStateChanged?.call(false);
      });

      _tts.setErrorHandler((msg) {
        debugPrint('❌ TTS Error: $msg');
        _isPlaying = false;
        _onStateChanged?.call(false);
      });

      _isInitialized = true;
      debugPrint('✅ TTS Initialized with Deep Male settings.');
    } catch (e) {
      debugPrint('❌ TTS Init Error: $e');
    } finally {
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    }
  }

  Future<void> speak(String text) async {
    final settings = _ref.read(settingsProvider.notifier);
    if (!settings.isTtsEnabled) return;

    await _ensureInitFinished();
    if (!_isInitialized) return;

    try {
      if (text.isEmpty) return;

      await _ref.read(audioServiceProvider).enterVoiceOverlay();

      await _tts.stop();

      await _tts.setPitch(0.82);
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(settings.voiceVolume);

      final cleanedText = text
          .replaceAll('🌾', '!')
          .replaceAll('Marc!', 'Hey, Marc!')
          .replaceAll('Idak', 'Eedak')
          .replaceAll('—', '...');

      debugPrint('🗣️ Mang Pedro speaking (Jolly Mode): $cleanedText');

      final useTagalog = cleanedText.contains('ako') ||
          cleanedText.contains('kabayan') ||
          cleanedText.contains('magandang') ||
          cleanedText.contains('Pilipinas');

      if (useTagalog) {
        final isTagalogAvailable = await _tts.isLanguageAvailable('fil-PH');
        if (isTagalogAvailable) {
          await _tts.setLanguage('fil-PH');
        } else {
          await _tts.setLanguage('en-US');
        }
      } else {
        await _tts.setLanguage('en-US');
      }

      await _tts.speak(
        cleanedText,
        focus: !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
      );
    } catch (e) {
      debugPrint('❌ TTS Speak Exception: $e');
    } finally {
      await _ref.read(audioServiceProvider).leaveVoiceOverlay();
    }
  }

  Future<void> stop() async {
    await _tts.stop();
    _isPlaying = false;
    _onStateChanged?.call(false);
  }

  /// Hard-stop TTS and wait for speaker tail to fade before opening the mic.
  Future<void> stopAndFlushForMic() async {
    await stop();
    await Future<void>.delayed(const Duration(milliseconds: 520));
  }
}

final ttsServiceProvider = Provider<TtsService>((ref) => TtsService(ref));
