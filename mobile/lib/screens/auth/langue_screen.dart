import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../utils/app_theme.dart';
import '../../services/storage_service.dart';
import '../../main.dart';

class LangueScreen extends ConsumerStatefulWidget {
  const LangueScreen({super.key});

  @override
  ConsumerState<LangueScreen> createState() => _LangueScreenState();
}

class _LangueScreenState extends ConsumerState<LangueScreen> {
  String _langueChoisie = 'fr';
  final FlutterTts _tts = FlutterTts();

  final List<Map<String, dynamic>> _langues = [
    {
      'code': 'moore',
      'nom': 'Mooré',
      'description': 'Mam yɩɩ Mooré',
      'emoji': '🇧🇫',
      'audio': 'Tontine BF pʋgẽ aw laafi ! Paam n bʋʋd.',
    },
    {
      'code': 'dioula',
      'nom': 'Dioula',
      'description': 'N bɛ Dioula kuma',
      'emoji': '🇧🇫',
      'audio': 'I bisimila Tontine BF ! Kan dɔ sugandi.',
    },
    {
      'code': 'fr',
      'nom': 'Français',
      'description': 'Je parle français',
      'emoji': '🇫🇷',
      'audio': 'Bienvenue sur Tontine BF ! Choisissez votre langue.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _parlerMessage('Tontine BF. Choisissez votre langue. Mooré, Dioula, ou Français.');
  }

  Future<void> _parlerMessage(String message) async {
    await _tts.setLanguage('fr-FR');
    await _tts.setSpeechRate(0.85);
    await _tts.speak(message);
  }

  Future<void> _continuer() async {
    await StorageService.saveLangue(_langueChoisie);
    ref.read(langueProvider.notifier).state = _langueChoisie;
    if (mounted) context.go('/inscription');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.vert,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text(
                '🇧🇫',
                style: TextStyle(fontSize: 56),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tontine BF',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choisissez votre langue\nPaam n\' bʋʋd  •  Kan dɔ sugandi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              Expanded(
                child: Column(
                  children: _langues.map((langue) {
                    final selected = _langueChoisie == langue['code'];
                    return GestureDetector(
                      onTap: () {
                        setState(() => _langueChoisie = langue['code']);
                        _parlerMessage(langue['audio']);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: selected ? Colors.white : Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected ? Colors.white : Colors.white38,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(langue['emoji'], style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    langue['nom'],
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: selected ? AppTheme.vert : Colors.white,
                                    ),
                                  ),
                                  Text(
                                    langue['description'],
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 13,
                                      color: selected ? AppTheme.grisTexte : Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (selected)
                              Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: AppTheme.vert,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, color: Colors.white, size: 18),
                              ),
                            IconButton(
                              icon: Icon(
                                Icons.volume_up_rounded,
                                color: selected ? AppTheme.vert : Colors.white70,
                              ),
                              onPressed: () => _parlerMessage(langue['audio']),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              ElevatedButton(
                onPressed: _continuer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.vert,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Continuer →'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}
