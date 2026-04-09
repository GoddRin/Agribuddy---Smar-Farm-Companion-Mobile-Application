import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart'
    show debugPrint, defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../providers/settings_provider.dart';

enum SfxType { tap, success, micStart, micStop }

class AudioService {
  late final AudioPlayer _bgmPlayer;
  /// Preloaded tap — instant playback for nav / UI taps.
  late final AudioPlayer _sfxTapPlayer;
  /// Success and other one-shots (loads on demand).
  late final AudioPlayer _sfxOtherPlayer;
  bool _tapSfxReady = false;
  final Ref _ref;
  int _voiceOverlayDepth = 0;
  bool _bgmWasPlayingBeforeVoice = false;

  /// True from [beginSpeechRecognition] until [endSpeechRecognition] (pairs with BGM pause).
  bool _speechRecognitionCycleActive = false;
  bool _bgmPausedForSpeechRecognition = false;
  bool _webAudioExplicitlyUnlocked = false;

  AudioService(this._ref) {
    _bgmPlayer = AudioPlayer();
    _sfxTapPlayer = AudioPlayer();
    _sfxOtherPlayer = AudioPlayer();
    _init();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    unawaited(_preloadTapSfx());

    // 1. Start the music (on web this will fail until the first user click)
    unawaited(startBgm());

    // 2. Listen to setting changes to stop or START music
    _ref.listen<Map<String, String>>(settingsProvider, (prev, next) {
      final musicEnabled = next['isMusicEnabled'] != 'false';
      if (!musicEnabled) {
        _bgmPlayer.stop();
      } else {
        startBgm();
      }
      
      // Live volume update
      final vol = double.tryParse(next['musicVolume'] ?? '0.55') ?? 0.55;
      if (_bgmPlayer.playing) {
        _bgmPlayer.setVolume(vol);
      }
    });
  }

  Future<void> _preloadTapSfx() async {
    try {
      await _sfxTapPlayer.setAsset('assets/audio/sfx/tap.mp3');
      final vol = _ref.read(settingsProvider.notifier).sfxVolume;
      await _sfxTapPlayer.setVolume(vol);
      _tapSfxReady = true;
    } catch (e) {
      debugPrint('Preload tap SFX: $e');
    }
  }

  Future<void> playSfx(SfxType type) async {
    final settings = _ref.read(settingsProvider.notifier);
    if (!settings.isSoundEnabled) return;

    final useTapPlayer = type == SfxType.tap ||
        type == SfxType.micStart ||
        type == SfxType.micStop;

    try {
      if (useTapPlayer) {
        if (!_tapSfxReady) await _preloadTapSfx();
        if (!_tapSfxReady) return;
        await _sfxTapPlayer.seek(Duration.zero);
        await _sfxTapPlayer.play();
        return;
      }

      final path = type == SfxType.success
          ? 'assets/audio/sfx/success.mp3'
          : 'assets/audio/sfx/tap.mp3';
      await _sfxOtherPlayer.setAsset(path);
      await _sfxOtherPlayer.setVolume(settings.sfxVolume);
      await _sfxOtherPlayer.play();
    } catch (e) {
      debugPrint('Error playing SFX: $e');
    }
  }

  Future<void> startBgm() async {
    final settings = _ref.read(settingsProvider.notifier);
    if (!settings.isMusicEnabled) return;
    if (_bgmPlayer.playing) return;

    try {
      if (kIsWeb) {
        // Just-audio on web can be fussy about loading state during autoplay block
        await _bgmPlayer.setAsset('assets/audio/music/bgm_farm.mp3', preload: true);
      } else {
        await _bgmPlayer.setAsset('assets/audio/music/bgm_farm.mp3');
      }
      
      await _bgmPlayer.setLoopMode(LoopMode.one);
      await _bgmPlayer.setVolume(settings.musicVolume);
      
      final playFuture = _bgmPlayer.play();
      if (kIsWeb) {
        // Catch the 'NotAllowedError' silently on web. 
        // We will retry once the user clicks.
        unawaited(playFuture.catchError((e) {
          debugPrint("BGM Autoplay Blocked (Wait for click): $e");
          return null;
        }));
      } else {
        await playFuture;
      }
    } catch (e) {
      debugPrint("Error playing BGM: $e");
    }
  }

  /// WEB ONLY: Call this on the very first user interaction to 'prime' the audio context.
  Future<void> unlockWebAudio() async {
    if (!kIsWeb || _webAudioExplicitlyUnlocked) return;
    _webAudioExplicitlyUnlocked = true;
    
    debugPrint("🔊 Unlocking Web Audio Context...");
    try {
      // 1. Prime the SFX player with a silent load/play
      await _sfxTapPlayer.setVolume(0.0);
      await _sfxTapPlayer.play();
      await _sfxTapPlayer.stop();
      await _sfxTapPlayer.setVolume(_ref.read(settingsProvider.notifier).sfxVolume);
      
      // 2. Force-start the BGM now that we have an interaction token
      await startBgm();
    } catch (e) {
      debugPrint("Web Audio Unlock Failed: $e");
    }
  }

  Future<void> stopBgm() async {
    await _bgmPlayer.stop();
  }

  /// Stops UI sound effects so the mic does not pick them up as speech.
  Future<void> stopSfxPlayback() async {
    try {
      await _sfxTapPlayer.stop();
      await _sfxOtherPlayer.stop();
    } catch (e) {
      debugPrint('stopSfxPlayback: $e');
    }
  }

  /// Pause background music while TTS or speech recognition needs the audio path (focus).
  Future<void> enterVoiceOverlay() async {
    _voiceOverlayDepth++;
    if (_voiceOverlayDepth > 1) return;
    final settings = _ref.read(settingsProvider.notifier);
    _bgmWasPlayingBeforeVoice = settings.isMusicEnabled && _bgmPlayer.playing;
    if (_bgmWasPlayingBeforeVoice) {
      await _bgmPlayer.pause();
    }
  }

  /// Resume BGM after a matching [enterVoiceOverlay] (nested sessions supported).
  Future<void> leaveVoiceOverlay() async {
    if (_voiceOverlayDepth <= 0) return;
    _voiceOverlayDepth--;
    if (_voiceOverlayDepth > 0) return;
    final settings = _ref.read(settingsProvider.notifier);
    if (_bgmWasPlayingBeforeVoice && settings.isMusicEnabled) {
      try {
        await _bgmPlayer.play();
      } catch (e) {
        debugPrint('BGM resume after voice: $e');
      }
    }
    _bgmWasPlayingBeforeVoice = false;
  }

  /// Call before [SpeechToText.listen]. Pauses BGM; on **iOS** also reconfigures the audio session.
  /// On **Android**, we avoid reconfiguring [AudioSession] here — it can fight [SpeechRecognizer]'s mic pipeline.
  Future<void> beginSpeechRecognition() async {
    if (_speechRecognitionCycleActive) return;
    _speechRecognitionCycleActive = true;

    final settings = _ref.read(settingsProvider.notifier);
    _bgmPausedForSpeechRecognition = settings.isMusicEnabled && _bgmPlayer.playing;
    if (_bgmPausedForSpeechRecognition) {
      await _bgmPlayer.pause();
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final session = await AudioSession.instance;
        await session.configure(const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
          avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.defaultToSpeaker,
          avAudioSessionMode: AVAudioSessionMode.spokenAudio,
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.speech,
            usage: AndroidAudioUsage.assistant,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
        ));
        await session.setActive(true);
      } catch (e) {
        debugPrint('beginSpeechRecognition session: $e');
      }
    }
  }

  /// Call after speech recognition ends (or on error). Safe to call multiple times.
  Future<void> endSpeechRecognition() async {
    if (!_speechRecognitionCycleActive) return;
    _speechRecognitionCycleActive = false;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final session = await AudioSession.instance;
        await session.setActive(true);
      } catch (e) {
        debugPrint('endSpeechRecognition session: $e');
      }
    } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // Android: Inform session focus is done to avoid "stuck" mic
      try {
        final session = await AudioSession.instance;
        await session.setActive(false);
      } catch (_) {}
    }

    final settings = _ref.read(settingsProvider.notifier);
    if (_bgmPausedForSpeechRecognition && settings.isMusicEnabled) {
      try {
        if (!_bgmPlayer.playing) await _bgmPlayer.play();
      } catch (e) {
        debugPrint('BGM resume after STT: $e');
      }
    }
    _bgmPausedForSpeechRecognition = false;
  }

  void dispose() {
    _bgmPlayer.dispose();
    _sfxTapPlayer.dispose();
    _sfxOtherPlayer.dispose();
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService(ref);
  ref.onDispose(service.dispose);
  return service;
});
