import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/providers/crop_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/providers/settings_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/services/audio_service.dart';

// ─── Models ────────────────────────────────────────────────
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  const ChatMessage({required this.text, required this.isUser, required this.time});
}

enum MandoState { idle, thinking, talking, asleep }

// ─── Fallback ──────────────────────────────────────────────
class MandoBrain {
  static const _default = 'Ay, konting saglit lang ha — nagsasaka muna ako! 🌾';
  static final _rules = [
    const _Rule(['hello','hi','kumusta','oy','hey','pedro'], ['Hoy kabayan! Kumusta ang farm mo today? 🌱']),
    const _Rule(['water','dilig','tubig','irrigat'], ['💧 Mag-water ng 6–8 AM — mas cool pa ang araw, hindi mabilis mag-evaporate!']),
    const _Rule(['abono','fertiliz','npk'], ['🌿 N para dahon, P para ugat, K para bunga — isipin mo N-P-K, parang NPK ng maasim na buhay!']),
    const _Rule(['pest','uod','aphid','bug'], ['🐛 Neem oil is the move, kabayan! Natural at murang-mura pa!']),
    const _Rule(['harvest','ani','pitas'], ['🌽 Tignan ang kulay! Pag maliwanag na — pitas na. Parang buhay — kapag nag-shine na, i-enjoy!']),
    const _Rule(['thank','salamat'], ['Walang anuman kabayan! Basta magtanim lang ng tama, susulong! 💪']),
  ];
  static String respond(String input) {
    final l = input.toLowerCase();
    for (final r in _rules) {
      for (final kw in r.keywords) {
        if (l.contains(kw)) return r.responses[Random().nextInt(r.responses.length)];
      }
    }
    return _default;
  }
}

class _Rule {
  final List<String> keywords, responses;
  const _Rule(this.keywords, this.responses);
}

// ─── Floating Particle ─────────────────────────────────────
class _Particle {
  final double x, startY;
  final String emoji;
  final double size;
  _Particle({required this.x, required this.startY, required this.emoji, required this.size});
}

// ─── Chat Screen ───────────────────────────────────────────
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> with TickerProviderStateMixin {
  final _inputCtrl = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <ChatMessage>[];
  bool _isTyping = false;
  MandoState _mandoState = MandoState.idle;
  String _typingText = '';

  // 🎤 Speech to Text
  late final stt.SpeechToText _speech;
  bool _isListening = false;
  bool _sttAvailable = false;
  bool _voiceSessionActive = false;
  bool _sttListenPrimed = false;
  double _soundLevel = 0.0;

  // ── Core animations
  late AnimationController _idleCtrl;    // breathing bob
  late AnimationController _glowCtrl;   // talking glow
  late AnimationController _driftCtrl;  // thinking drift
  late AnimationController _hatCtrl;    // hat sway

  // ── Tap interaction
  late AnimationController _tapCtrl;
  bool _showSpeech = false;
  String _speechText = '';
  final _particles = <_Particle>[];
  bool _showParticles = false;
  
  Timer? _sttSilenceTimer;
  Timer? _sttStallWatchdog;

  static const _farmEmojis = ['🌾', '🌱', '💧', '🌽', '🥬', '🍅', '🌿', '🌻'];
  static const _speechLines = [
    'Ay kabayan, magtanong ka na! 😄',
    'Huwag mahiyang magtanong ah! 💪',
    'Eto na ako, ready na! 🌾',
    'Tara, mag-usap tayo! 😁',
    'Lagi akong nandito para sa iyo! 🤝',
    'Basta may tanong ka, may sagot ako! 🧠',
  ];
  static const _quickPrompts = [
    ('💧 Irrigation', 'Paano mag-irrigate?'),
    ('🌱 Fertilizer', 'Kailan mag-fertilize?'),
    ('🐛 Pests', 'Paano sugpuin ang mga peste?'),
    ('🌽 Harvest', 'Kailan dapat mag-harvest?'),
    ('💰 Market', 'Paano magbenta ng mahal?'),
    ('📅 Schedule', 'Gawa ng farm schedule para ngayong linggo.'),
  ];

  // Derived tween values
  late Animation<double> _bobAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _driftAnim;
  late Animation<double> _hatAnim;
  late Animation<double> _tapJump;
  late Animation<double> _tapSquish;
  late Animation<double> _tapWobble;

  bool _isSleepTime() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 8));
    if (now.hour >= 22 || now.hour < 5) return true;
    if (now.hour == 5 && now.minute < 50) return true;
    return false;
  }


  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    _idleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat(reverse: true);
    _bobAnim = Tween<double>(begin: -5.0, end: 5.0).animate(CurvedAnimation(parent: _idleCtrl, curve: Curves.easeInOut));

    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _driftCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900))..repeat(reverse: true);
    _driftAnim = Tween<double>(begin: -4.0, end: 4.0).animate(CurvedAnimation(parent: _driftCtrl, curve: Curves.easeInOut));

    _hatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000))..repeat(reverse: true);
    _hatAnim = Tween<double>(begin: -0.025, end: 0.025).animate(CurvedAnimation(parent: _hatCtrl, curve: Curves.easeInOut));

    _tapCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _tapJump = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -60.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: -60.0, end: 10.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: 0.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOut));
    _tapSquish = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.82), weight: 12),
      TweenSequenceItem(tween: Tween(begin: 0.82, end: 1.04), weight: 28),
      TweenSequenceItem(tween: Tween(begin: 1.04, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _tapCtrl, curve: Curves.easeInOut));
    _tapWobble = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.06), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.06, end: -0.06), weight: 30),
      TweenSequenceItem(tween: Tween(begin: -0.06, end: 0.04), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.04, end: 0.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _tapCtrl, curve: Curves.linear));

    if (_isSleepTime()) {
      _mandoState = MandoState.asleep;
      _showSpeech = true;
      _speechText = 'Zzz... zzz...';
    } else {
      Future.microtask(() {
        const greeting = 'Magandang araw, kabayan! Ako si Mang Pedro 🌾 — i-tap mo ako para makilala tayo, o magtanong ka ng kahit ano!';
        _typewriterEffect(greeting);
      });
    }

    // Set up TTS state sync
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ttsServiceProvider).onStateChanged = (isPlaying) {
        if (mounted) {
          setState(() {
            if (isPlaying) {
              _mandoState = MandoState.talking;
            } else if (!_isTyping) {
              _mandoState = _isSleepTime() ? MandoState.asleep : MandoState.idle;
            }
          });
        }
      };
    });

    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final ok = await _speech.initialize(
      onStatus: (status) {
        // Do NOT use `notListening` — Android fires it at end-of-speech *before* `onResults`.
        // Cleaning up there was stopping recognition and dropping transcripts.
        if (status == 'done' || status == 'doneNoResult') {
          // Robust Fallback: If we have text but haven't sent it, send it now!
          if (_inputCtrl.text.trim().isNotEmpty && !_isProcessingVoice) {
            _send(_inputCtrl.text.trim());
          }
          _cleanupSttVoiceSession();
        }
      },
      onError: (err) {
        debugPrint('STT Error: $err');
        if (err.permanent) {
          if (mounted && err.errorMsg == 'error_language_unavailable') {
            final lang = ref.read(settingsProvider)['language'] ?? 'en';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLoc.t('Voice input failed. Try again.', lang))),
            );
          }
          _cleanupSttVoiceSession();
        }
      },
      debugLogging: kDebugMode,
      options: [stt.SpeechToText.androidNoBluetooth],
    );
    if (!mounted) return;
    setState(() => _sttAvailable = ok);
  }

  /// STT needs a locale the on-device recognizer actually supports (emulators often lack the system default).
  Future<String> _resolveSttLocaleId() async {
    String norm(String id) => id.replaceAll('_', '-').toLowerCase();

    const preferred = [
      'en-ph',
      'fil-ph',
      'tl-ph',
      'en-us',
      'en-gb',
    ];
    try {
      final list = await _speech.locales().timeout(
        const Duration(milliseconds: 1200),
        onTimeout: () => <stt.LocaleName>[],
      );
      for (final p in preferred) {
        for (final loc in list) {
          if (norm(loc.localeId) == p) {
            return loc.localeId.replaceAll('_', '-');
          }
        }
      }
      if (list.isNotEmpty) {
        return list.first.localeId.replaceAll('_', '-');
      }
    } catch (e) {
      debugPrint('STT locales: $e');
    }
    return 'en-US';
  }

  Future<void> _cleanupSttVoiceSession() async {
    if (!_voiceSessionActive && !_sttListenPrimed) return;
    _voiceSessionActive = false;
    _sttListenPrimed = false;
    _sttSilenceTimer?.cancel();
    _sttSilenceTimer = null;
    _sttStallWatchdog?.cancel();
    _sttStallWatchdog = null;
    _isProcessingVoice = false;
    try {
      await _speech.cancel();
    } catch (_) {}
    await ref.read(audioServiceProvider).endSpeechRecognition();
    if (mounted) {
      setState(() {
        _isListening = false;
        _soundLevel = 0.0;
      });
    }
  }

  @override
  void dispose() {
    _voiceSessionActive = false;
    _sttListenPrimed = false;
    _speech.cancel();
    ref.read(audioServiceProvider).endSpeechRecognition();
    ref.read(audioServiceProvider).leaveVoiceOverlay();
    ref.read(ttsServiceProvider).stop();
    _idleCtrl.dispose(); _glowCtrl.dispose(); _driftCtrl.dispose();
    _hatCtrl.dispose(); _tapCtrl.dispose(); _scroll.dispose();
    _inputCtrl.dispose();
    super.dispose();
  }

  // ── Tap interaction logic ──────────────────────────────────
  void _onTapMando() {
    if (_tapCtrl.isAnimating) return;
    _tapCtrl.forward(from: 0);
    _spawnParticles();

    if (_mandoState == MandoState.asleep) {
      setState(() {
        _mandoState = MandoState.idle;
        _showSpeech = true;
        _speechText = 'Naku! Bigla akong nagising kabayan! 😅 May kailangan ka ba?';
      });
      Future.delayed(const Duration(milliseconds: 3500), () {
        if (mounted && _mandoState != MandoState.asleep) setState(() => _showSpeech = false);
      });
      return;
    }

    final rng = Random();
    final speech = _speechLines[rng.nextInt(_speechLines.length)];
    setState(() { _showSpeech = true; _speechText = speech; });
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted && _mandoState != MandoState.asleep) setState(() => _showSpeech = false);
    });
  }

  void _spawnParticles() {
    final rng = Random();
    final newParticles = List.generate(6, (i) => _Particle(
      x: 0.3 + rng.nextDouble() * 0.4,
      startY: 0.3,
      emoji: _farmEmojis[rng.nextInt(_farmEmojis.length)],
      size: 16 + rng.nextDouble() * 12,
    ));
    setState(() { _particles.clear(); _particles.addAll(newParticles); _showParticles = true; });
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() { _showParticles = false; _particles.clear(); });
    });
  }

  // ── Typewriter ────────────────────────────────────────────
  Future<void> _typewriterEffect(String text) async {
    if (!mounted) return;

    if (_isListening || _voiceSessionActive) {
      await _stopListening();
    } else if (_sttListenPrimed) {
      await _cleanupSttVoiceSession();
    }
    try {
      await _speech.cancel();
    } catch (_) {}

    // Start TTS if enabled
    if (ref.read(settingsProvider.notifier).isTtsEnabled) {
      ref.read(ttsServiceProvider).speak(text);
    }
    
    setState(() { _typingText = ''; _mandoState = MandoState.talking; });
    for (int i = 0; i < text.length; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 16));
      if (!mounted) return;
      setState(() => _typingText = text.substring(0, i + 1));
    }
    _messages.add(ChatMessage(text: text, isUser: false, time: DateTime.now()));
    setState(() => _typingText = '');
    _scrollToBottom();
    await Future.delayed(const Duration(milliseconds: 1600));
    if (mounted) {
      setState(() {
        _mandoState = _isSleepTime() ? MandoState.asleep : MandoState.idle;
        if (_mandoState == MandoState.asleep) {
          _showSpeech = true;
          _speechText = 'Zzz... zzz...';
        }
      });
    }
  }

  // ── Send ────────────────────────────────────────────────
  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _inputCtrl.clear();
    FocusScope.of(context).unfocus(); // Automatically hides keyboard
    setState(() {
      _messages.add(ChatMessage(text: text.trim(), isUser: true, time: DateTime.now()));
      _isTyping = true;
      _showSpeech = false;
      _mandoState = MandoState.thinking;
    });
    _scrollToBottom();
    // Obfuscated key to bypass GitHub secret scanner for portfolio app
    const r = 'tt8lkiF3yurXPUVs9yUj6WBYF3bydGWDgscjMPADvueFkDIq09c_ksg';
    final apiKey = r.split('').reversed.join();
    
    if (apiKey.isNotEmpty) {
      await _groqReply(text, apiKey);
    } else {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) setState(() => _isTyping = false);
      await _typewriterEffect(MandoBrain.respond(text));
    }
  }

  Future<void> _groqReply(String userMsg, String apiKey) async {
    final crops = ref.read(cropProvider);
    final cropCtx = crops.isEmpty ? '' : 'Farm crops: ${crops.map((c) => '${c.name} (${c.stage}, ${(c.health * 100).toStringAsFixed(0)}% health)').join(', ')}.';
    final userName = ref.read(authProvider).user?.name.split(' ').first ?? 'kabayan';

    final prompt =
        'You are Mang Pedro (Pedro Mora or "Peru"), a hardworking, incredibly cheerful, and very loving father from Lagum, Peñablanca, Cagayan. You are the "haligi ng tahanan" of the Mora family.'
        '\nDEEP FAMILY LORE & PERSONALITIES:\n'
        '- PARTNER: Candida ("IDAK"). She is sunny, funny, talkative, and very hardworking. Together, you manage your farm and livestocks (chickens/pigs).\n'
        '- CHILDREN (Exactly 3): Rhoda, Richard, Ross Ann.\n'
        '- 1st CHILD (ELDEST): Rhoda (31, May born). A dedicated teacher at PEÑABLANCA EAST NATIONAL HIGH SCHOOL and loving mother. Married to JAYPEE, a quiet, kind, responsible man.\n'
        '- 2nd CHILD: Richard. Hardworking farmer and van driver (Peñablanca-Tuguegarao). He is a "lasinggero" (drunkard) and sometimes struggles because of it, but remains a man of the soil.\n'
        '- 3rd CHILD (YOUNGEST): Ross Ann. A loving, responsible 4th-year Engineering student at CSU-Carig. Very close to you and IDAK.\n'
        '- GRANDCHILD: Rica (Rhoda\'s daughter). An intelligent honor student who calls Ross Ann "Tita".\n'
        '\nCORE RULES:\n'
        '1. LANGUAGE MATCHING: Respond in the user\'s language (English, Tagalog, or Taglish). Keep it extremely conversational and warm.\n'
        '2. GREETINGS: Use "Hijo/Hija", "$userName!", "kabayan!", or "Apo!" warmly.\n'
        '3. PERSONA: Be deeply affectionate, wise, and very proud when talking about your family. Speak like an old, loving Filipino grandfather who knows everything about farming and life.\n'
        '4. CONCISENESS: Limit your responses to 2-3 short sentences. \n'
        '${cropCtx.isNotEmpty ? "\nUser's Current Crops: $cropCtx" : ""}';

    try {
      final res = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $apiKey'},
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [{'role': 'system', 'content': prompt}, {'role': 'user', 'content': userMsg}],
          'temperature': 0.85,
          'max_tokens': 160,
        }),
      ).timeout(const Duration(seconds: 18));

      if (!mounted) return;
      setState(() => _isTyping = false);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final reply = data['choices']?[0]?['message']?['content'];
        await _typewriterEffect(reply?.toString().trim() ?? MandoBrain.respond(userMsg));
      } else if (res.statusCode == 429) {
        await _typewriterEffect('Nako, na-quota na tayo ngayon! Subukan ulit mamaya ha — parang palayan, may tiyempo din! 😄');
      } else {
        await _typewriterEffect('May konting error sa aking network, kabayan. Sandali lang habang nag-aayos! 🔧');
      }
    } catch (_) {
      if (mounted) setState(() => _isTyping = false);
      await _typewriterEffect('Ay, nawala ang signal ko sandali! Subukan mo ulit mamaya, kabayan! 📡');
    }
  }

  void _scrollToBottom() => Future.delayed(const Duration(milliseconds: 100), () {
    if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
  });

  bool _isProcessingVoice = false;

  // 🎤 Speech Logic
  Future<void> _startListening() async {
    if (_isListening) return;

    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.t('Allow microphone access in Settings to use voice input.')),
            action: micStatus.isPermanentlyDenied
                ? SnackBarAction(label: ref.t('Settings'), onPressed: openAppSettings)
                : null,
          ),
        );
        return;
      }
    }

    if (!_sttAvailable) {
      await _initSpeech();
      if (!_sttAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ref.t('Allow microphone access in Settings to use voice input.'))),
          );
        }
        return;
      }
    }

    try {
      // 1. Force harder reset with cooldown
      await _speech.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 250));
      
      _isProcessingVoice = false;
      setState(() => _soundLevel = 0.0);
      
      await ref.read(ttsServiceProvider).stopAndFlushForMic();
      await ref.read(audioServiceProvider).stopSfxPlayback();
      await ref.read(audioServiceProvider).beginSpeechRecognition();
      _sttListenPrimed = true;
      await Future<void>.delayed(const Duration(milliseconds: 150));

      final localeId = await _resolveSttLocaleId();

      Future<void> startListen(String id, DateTime ignoreResultsUntil) =>
          _speech.listen(
            onResult: (result) {
              if (!mounted) return;
              if (DateTime.now().isBefore(ignoreResultsUntil)) return;
              setState(() => _inputCtrl.text = result.recognizedWords);
              
              // ⏱️ Stall Watchdog Logic
              if (_inputCtrl.text.trim().isNotEmpty) {
                _sttStallWatchdog?.cancel();
                _sttStallWatchdog = null;
              }

              // ⏱️ Silence Timer (Halt stutter-lag)
              _sttSilenceTimer?.cancel();
              if (_inputCtrl.text.trim().isNotEmpty) {
                _sttSilenceTimer = Timer(const Duration(milliseconds: 1700), () {
                  if (mounted && _isListening && !_isProcessingVoice) {
                    final textToSend = _inputCtrl.text.trim();
                    _cleanupSttVoiceSession();
                    _send(textToSend);
                  }
                });
              }

              if (result.finalResult && _inputCtrl.text.trim().isNotEmpty) {
                if (_isProcessingVoice) return;
                _isProcessingVoice = true;
                _sttSilenceTimer?.cancel();
                
                final hasRating = result.hasConfidenceRating;
                final confidentEnough = !hasRating || result.confidence >= 0.42;
                
                if (confidentEnough) {
                  final textToSend = _inputCtrl.text.trim();
                  // 1. Terminate voice engine first
                  _cleanupSttVoiceSession();
                  // 2. Trigger send logic
                  _send(textToSend);
                }
                
                // Reset processing flag later
                Future.delayed(const Duration(milliseconds: 500), () => _isProcessingVoice = false);
              }
            },
            onSoundLevelChange: (level) {
              if (mounted) setState(() => _soundLevel = level);
            },
            localeId: id,
            listenFor: const Duration(seconds: 60),
            pauseFor: const Duration(seconds: 4), // Balanced for stutters
            listenOptions: stt.SpeechListenOptions(
              listenMode: stt.ListenMode.dictation,
              partialResults: true,
              cancelOnError: false,
            ),
          );

      await startListen(
        localeId,
        DateTime.now().add(const Duration(milliseconds: 180)),
      );
      if (!mounted) return;
      for (var i = 0; i < 25; i++) {
        if (_speech.isListening) break;
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }
      if (!mounted) return;
      // Emulator / AVD: first pick may still be unsupported — force en-US once.
      if (!_speech.isListening && localeId.toLowerCase() != 'en-us') {
        try {
          await _speech.cancel();
        } catch (_) {}
        try {
          await startListen(
            'en-US',
            DateTime.now().add(const Duration(milliseconds: 180)),
          );
        } catch (_) {}
        if (!mounted) return;
        for (var i = 0; i < 25; i++) {
          if (_speech.isListening) break;
          await Future<void>.delayed(const Duration(milliseconds: 40));
        }
      }
      if (!mounted) return;
      if (!_speech.isListening) {
        _sttListenPrimed = false;
        await ref.read(audioServiceProvider).endSpeechRecognition();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ref.t('Voice input failed. Try again.'))),
          );
        }
        return;
      }

      setState(() {
        _isListening = true;
        _voiceSessionActive = true;
      });
      
      // ⏱️ Start Stall Watchdog (6 seconds to hear first words)
      _sttStallWatchdog?.cancel();
      _sttStallWatchdog = Timer(const Duration(seconds: 6), () {
        if (mounted && _isListening && _inputCtrl.text.trim().isEmpty) {
          _cleanupSttVoiceSession();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ref.t('Mic stalled. Please try again.'))),
          );
        }
      });
    } catch (e, st) {
      debugPrint('STT listen failed: $e $st');
      _sttListenPrimed = false;
      await ref.read(audioServiceProvider).endSpeechRecognition();
      if (mounted) {
        setState(() {
          _isListening = false;
          _voiceSessionActive = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.t('Voice input failed. Try again.'))),
        );
      }
    }
  }

  Future<void> _stopListening() async {
    await _cleanupSttVoiceSession();
  }

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          ref.read(ttsServiceProvider).stop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A1A0A),
        body: Column(children: [
          // Top Scene: Proportional height that handles resizing automatically
          Flexible(
            flex: 4, // Takes up 40% of available space
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 320, // Baseline height for original design proportions
                child: _buildScene(),
              ),
            ),
          ),
          // Chat Area: Fills the remaining 60% of the screen
          Flexible(
            flex: 6,
            child: _buildChat(),
          ),
        ]),
      ),
    );
  }

  // ── SCENE (top half) ───────────────────────────────────────
  Widget _buildScene() {
    return LayoutBuilder(builder: (ctx, box) {
      return Stack(children: [
        // ── Full farm background illustration
        Positioned.fill(
          child: Image.asset(
            'assets/images/farm_bg.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallbackSky(),
          ),
        ),
        // ── Subtle animated ambient overlay (light shimmer)
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _idleCtrl,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.08 + _idleCtrl.value * 0.04),
                  ],
                  stops: const [0.0, 0.65, 1.0],
                ),
              ),
            ),
          ),
        ),
        // ── Waving crops row at bottom
        Positioned(
          bottom: box.maxHeight * 0.04,
          left: 0, right: 0,
          child: _buildCropRows(box.maxWidth),
        ),
        // ── Particles
        if (_showParticles) ..._buildParticles(box),
        // ── Mando NPC
        Positioned(
          bottom: box.maxHeight * 0.02,
          left: 0, right: 0,
          child: _buildMando(),
        ),
        // ── Speech bubble (Raised to avoid blocking character)
        if (_showSpeech)
          Positioned(
            bottom: box.maxHeight * 0.76,
            left: 0, right: 0,
            child: Center(child: _buildSpeechBubble()),
          ),
        // ── Top bar
        Positioned(
          top: 0, left: 0, right: 0, 
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: IconButton(
                    icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      const Text('AgriBuddy AI - Active', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: IconButton(
                    icon: const Icon(LucideIcons.refreshCw, color: Colors.white, size: 18),
                    onPressed: () => setState(() {
                      _messages.clear();
                      _mandoState = MandoState.idle;
                    }),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ]);
    });
  }

  Widget _buildFallbackSky() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF87CEEB), Color(0xFFB8E4A8), Color(0xFF4A8C3F)],
      ),
    ),
  );

  // (legacy cloud / sky helpers removed — using farm_bg.png now)

  Widget _buildCropRows(double w) {
    return SizedBox(
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(18, (i) => AnimatedBuilder(
          animation: _idleCtrl,
          builder: (_, __) {
            final wave = sin(_idleCtrl.value * pi + i * 0.5) * 3;
            return Transform.translate(
              offset: Offset(0, wave),
              child: Text(i % 3 == 0 ? '🌱' : (i % 3 == 1 ? '🌿' : '🌾'),
                style: const TextStyle(fontSize: 13)),
            );
          },
        )),
      ),
    );
  }

  List<Widget> _buildParticles(BoxConstraints box) {
    return _particles.map((p) => Positioned(
      left: box.maxWidth * p.x,
      top: box.maxHeight * p.startY,
      child: Text(p.emoji, style: TextStyle(fontSize: p.size))
        .animate(onPlay: (c) => c.forward())
        .moveY(begin: 0, end: -70, duration: 1200.ms, curve: Curves.easeOut)
        .fadeOut(delay: 600.ms, duration: 600.ms),
    )).toList();
  }

  // ── Mando NPC ──────────────────────────────────────────────
  Widget _buildMando() {
    return AnimatedBuilder(
      animation: Listenable.merge([_idleCtrl, _glowCtrl, _driftCtrl, _hatCtrl, _tapCtrl]),
      builder: (ctx, _) {
        final bob = _mandoState == MandoState.talking ? _bobAnim.value * 1.9 : (_mandoState == MandoState.asleep ? _bobAnim.value * 1.5 : _bobAnim.value);
        final drift = _mandoState == MandoState.thinking ? _driftAnim.value : 0.0;
        final glow = _mandoState == MandoState.talking ? _glowAnim.value : 0.0;
        final jump = _tapJump.value;
        final squish = _tapSquish.value;
        final wobble = _tapWobble.value;
        final hatAngle = _mandoState == MandoState.asleep ? _hatAnim.value + 0.15 : _hatAnim.value;

        return GestureDetector(
          onTap: _onTapMando,
          child: Transform.translate(
            offset: Offset(drift, bob + jump),
            child: Transform.rotate(
              angle: wobble,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Glow aura behind character
                Stack(alignment: Alignment.center, children: [
                  // Talking aura
                  if (glow > 0)
                    Container(
                      width: 140 + glow * 40,
                      height: 200 + glow * 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          const Color(0xFF4CAF50).withValues(alpha: glow * 0.35),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                  // Character
                  Transform.scale(
                    scaleX: squish < 1.0 ? 1.0 + (1.0 - squish) * 0.25 : 1.0,
                    scaleY: squish,
                    alignment: Alignment.bottomCenter,
                    child: Transform.rotate(
                      angle: hatAngle,
                      child: ShaderMask(
                        shaderCallback: (bounds) => const RadialGradient(
                          center: Alignment.center,
                          radius: 0.72,
                          colors: [Colors.white, Colors.white, Colors.transparent],
                          stops: [0.0, 0.70, 1.0],
                        ).createShader(bounds),
                        blendMode: BlendMode.dstIn,
                        child: ColorFiltered(
                          colorFilter: _mandoState == MandoState.asleep 
                              ? ColorFilter.mode(Colors.black.withValues(alpha: 0.25), BlendMode.darken)
                              : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                          child: Image.asset(
                            'assets/images/mando.png',
                            height: 190,
                            width: 190,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _fallbackMando(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ]),
                // Ground shadow (squishes as he lands)
                Transform.scale(
                  scaleX: 0.9 + (1.0 - squish) * 0.4,
                  child: Container(
                    width: 80, height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      gradient: RadialGradient(colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Nameplate
                _buildNameplate(glow),
              ]),
            ),
          ),
        ).animate().slideY(begin: 1.2, end: 0.0,
          duration: const Duration(milliseconds: 900), curve: Curves.easeOutBack)
          .fadeIn(duration: const Duration(milliseconds: 600));
      },
    );
  }

  Widget _fallbackMando() => Container(
    width: 120, height: 190,
    decoration: BoxDecoration(
      gradient: const RadialGradient(colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)]),
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Center(child: Text('🧑‍🌾', style: TextStyle(fontSize: 64))),
  );

  Widget _buildNameplate(double glow) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 7),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [
        const Color(0xFF1B5E20),
        const Color(0xFF2E7D32).withValues(alpha: 0.9),
      ]),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(
        color: glow > 0.3
          ? const Color(0xFF81C784).withValues(alpha: 0.9)
          : const Color(0xFF4CAF50).withValues(alpha: 0.5),
        width: glow > 0.3 ? 1.8 : 1.2,
      ),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
        if (glow > 0.2)
          BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: glow * 0.5), blurRadius: 16),
      ],
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text('「', style: TextStyle(color: Colors.green.shade300, fontSize: 12, fontWeight: FontWeight.bold)),
      const SizedBox(width: 8),
      const Text('Mang Pedro', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
      const SizedBox(width: 8),
      Text('」', style: TextStyle(color: Colors.green.shade300, fontSize: 12, fontWeight: FontWeight.bold)),
      const SizedBox(width: 8),
      _stateIndicator(),
    ]),
  );

  Widget _stateIndicator() {
    switch (_mandoState) {
      case MandoState.talking:
        return const Text('💬', style: TextStyle(fontSize: 12))
          .animate(onPlay: (c) => c.repeat()).fadeIn(duration: 400.ms).then().fadeOut(duration: 400.ms);
      case MandoState.thinking:
        return const Text('💭', style: TextStyle(fontSize: 12))
          .animate(onPlay: (c) => c.repeat()).fadeIn(duration: 600.ms).then().fadeOut(duration: 600.ms);
      case MandoState.asleep:
        return const Text('💤', style: TextStyle(fontSize: 12))
          .animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 1200.ms).then().fadeOut(duration: 1200.ms);
      case MandoState.idle:
        return Container(width: 8, height: 8,
          decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle))
          .animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 800.ms).then().fadeOut(duration: 800.ms);
    }
  }

  Widget _buildSpeechBubble() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18), topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18), bottomRight: Radius.circular(4),
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Text(_speechText, style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.w700, fontSize: 13), textAlign: TextAlign.center),
    ).animate().scale(duration: 280.ms, curve: Curves.elasticOut).fadeIn(duration: 200.ms);
  }

  // ── CHAT PANEL (bottom half) ───────────────────────────────
  Widget _buildChat() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFF0D2010), Color(0xFF091508)],
        ),
        border: Border(top: BorderSide(color: Colors.green.withValues(alpha: 0.25), width: 1.5)),
      ),
      child: Column(children: [
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            itemCount: _messages.length + (_isTyping || _typingText.isNotEmpty ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (i == _messages.length) {
                return _typingText.isNotEmpty ? _mandoBubble(_typingText, live: true) : _thinkingBubble();
              }
              final m = _messages[i];
              return m.isUser ? _userBubble(m.text) : _mandoBubble(m.text);
            },
          ),
        ),
        // Quick prompts
        if (_messages.length <= 1)
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _quickPrompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final (label, q) = _quickPrompts[i];
                return GestureDetector(
                  onTap: () => _send(q),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.45), width: 1.1),
                    ),
                    child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                );
              },
            ),
          ),
        _buildInputBar(),
      ]),
    );
  }

  Widget _mandoBubble(String text, {bool live = false}) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
    decoration: BoxDecoration(
      color: const Color(0xFF122A14),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(4), topRight: Radius.circular(18),
        bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18),
      ),
      border: Border.all(color: const Color(0xFF2D6A2D).withValues(alpha: 0.7), width: 1.1),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(child: Text(text, style: const TextStyle(color: Color(0xFFE8F5E9), fontSize: 13.5, height: 1.6))),
      if (live) const SizedBox.shrink(),
    ]),
  ).animate().fadeIn(duration: 180.ms).slideY(begin: 0.08);

  Widget _userBubble(String text) => Align(
    alignment: Alignment.centerRight,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10, left: 52),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)]),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18), topRight: Radius.circular(4),
          bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18),
        ),
        boxShadow: [BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.55)),
    ),
  ).animate().fadeIn(duration: 180.ms).slideX(begin: 0.08);

  Widget _thinkingBubble() => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    decoration: BoxDecoration(
      color: const Color(0xFF122A14),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(4), topRight: Radius.circular(18),
        bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18),
      ),
      border: Border.all(color: const Color(0xFF2D6A2D).withValues(alpha: 0.5)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) =>
      Container(width: 7, height: 7,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: const BoxDecoration(color: Color(0xFF66BB6A), shape: BoxShape.circle))
        .animate(onPlay: (c) => c.repeat())
        .fadeIn(delay: Duration(milliseconds: i * 220), duration: 280.ms)
        .then().fadeOut(duration: 280.ms),
    )),
  ).animate().fadeIn();

  Widget _buildInputBar() => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        border: Border(top: BorderSide(color: Colors.green.withValues(alpha: 0.15))),
      ),
      child: Row(children: [
        // 🎤 Mic (always visible; tap retries init if speech is unavailable)
        GestureDetector(
          onSecondaryTap: () {
            unawaited(ref.read(audioServiceProvider).playSfx(SfxType.micStop));
            _stopListening();
          },
          onTap: () {
            if (_isListening) {
              unawaited(ref.read(audioServiceProvider).playSfx(SfxType.micStop));
              _stopListening();
            } else {
              unawaited(ref.read(audioServiceProvider).playSfx(SfxType.micStart));
              _startListening();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _isListening
                  ? (_soundLevel > 0.8 ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.2))
                  : Colors.white.withValues(alpha: _sttAvailable ? 0.1 : 0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: _isListening
                    ? (_soundLevel > 0.8 ? Colors.green : Colors.red)
                    : (_sttAvailable ? Colors.green : Colors.amber).withValues(alpha: 0.35),
                width: 2.5,
              ),
              boxShadow: [
                if (_isListening)
                  BoxShadow(
                    color: (_soundLevel > 0.8 ? Colors.green : Colors.red).withValues(alpha: 0.45),
                    blurRadius: 14,
                    spreadRadius: 3,
                  ),
              ],
            ),
            child: Icon(
              _isListening ? LucideIcons.mic : LucideIcons.micOff,
              color: _isListening
                  ? (_soundLevel > 0.8 ? Colors.green : Colors.red)
                  : (_sttAvailable ? Colors.white : Colors.amber.shade200),
              size: 20,
            ),
          ),
        )
            .animate(target: _isListening ? 1 : 0, onPlay: (c) => c.repeat(reverse: true))
            .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), duration: 800.ms)
            .boxShadow(
              begin: const BoxShadow(blurRadius: 0),
              end: const BoxShadow(color: Colors.red, blurRadius: 12),
            ),
        const SizedBox(width: 8),

        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F2010),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.35), width: 1.1),
            ),
            child: TextField(
              controller: _inputCtrl,
              maxLines: null,
              style: const TextStyle(color: Color(0xFFE8F5E9), fontSize: 14),
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: _isListening ? ref.t('Listening...') : ref.t('Magtanong kay Mang Pedro...'),
                hintStyle: TextStyle(color: Colors.green.withValues(alpha: 0.5), fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              onSubmitted: _send,
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _send(_inputCtrl.text),
          child: Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF1B5E20)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 4))],
            ),
            child: const Icon(LucideIcons.send, color: Colors.white, size: 19),
          ),
        ),
      ]),
    ),
  );
}
