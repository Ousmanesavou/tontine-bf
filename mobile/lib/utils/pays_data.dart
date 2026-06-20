import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../utils/app_theme.dart';
import '../../utils/pays_data.dart';
import '../../utils/langues_data.dart';
import '../../services/storage_service.dart';
import '../../main.dart';

class LangueScreen extends ConsumerStatefulWidget {
  const LangueScreen({super.key});

  @override
  ConsumerState<LangueScreen> createState() => _LangueScreenState();
}

class _LangueScreenState extends ConsumerState<LangueScreen> {
  String _paysSelectionne = 'BF';
  String _langueSelectionnee = 'fr';
  int _etape = 1;
  final FlutterTts _tts = FlutterTts();

  List<String> get _languesDuPays =>
      PaysData.getLanguesPays(_paysSelectionne);

  @override
  void initState() {
    super.initState();
    _parler('Bienvenue sur Tontine. Choisissez votre pays.');
  }

  Future<void> _parler(String msg) async {
    await _tts.setLanguage('fr-FR');
    await _tts.setSpeechRate(0.85);
    await _tts.speak(msg);
  }

  Future<void> _continuer() async {
    if (_etape == 1) {
      final langues = _languesDuPays;
      if (langues.length == 1) {
        _langueSelectionnee = langues.first;
        await _sauvegarderEtContinuer();
      } else {
        setState(() => _etape = 2);
        _parler('Choisissez votre langue.');
      }
    } else {
      await _sauvegarderEtContinuer();
    }
  }

  Future<void> _sauvegarderEtContinuer() async {
    await StorageService.saveLangue(_langueSelectionnee);
    await StorageService.savePays(_paysSelectionne);
    ref.read(langueProvider.notifier).state = _langueSelectionnee;
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
              const SizedBox(height: 32),
              const Text('🌍', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              const Text('Tontine BF',
                  style: TextStyle(fontFamily: 'Nunito', fontSize: 28,
                      fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 8),
              Text(
                _etape == 1 ? 'Choisissez votre pays' : 'Choisissez votre langue',
                style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: _etape == 1 ? _buildSelectPays() : _buildSelectLangue(),
              ),
              ElevatedButton(
                onPressed: _continuer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.vert,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(_etape == 1 ? 'Continuer →' : 'Commencer →',
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 17, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectPays() {
    return Column(
      children: [
        // Recherche
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Rechercher un pays...',
              hintStyle: TextStyle(color: Colors.white60),
              prefixIcon: Icon(Icons.search, color: Colors.white60),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(14),
            ),
            onChanged: (v) => setState(() {}),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: PaysData.pays.length,
            itemBuilder: (ctx, i) {
              final pays = PaysData.pays[i];
              final selected = _paysSelectionne == pays['code'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _paysSelectionne = pays['code'];
                    final langues = PaysData.getLanguesPays(pays['code']);
                    _langueSelectionnee = langues.first;
                  });
                  _parler('${pays['nom']}. ${pays['indicatif']}');
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? Colors.white : Colors.white24,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(pays['drapeau'], style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pays['nom'],
                                style: TextStyle(
                                  fontFamily: 'Nunito', fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: selected ? AppTheme.vert : Colors.white,
                                )),
                            Text(pays['indicatif'],
                                style: TextStyle(
                                  fontFamily: 'Nunito', fontSize: 12,
                                  color: selected ? AppTheme.grisTexte : Colors.white60,
                                )),
                          ],
                        ),
                      ),
                      Text(pays['devise'],
                          style: TextStyle(
                            fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w600,
                            color: selected ? AppTheme.vert : Colors.white60,
                          )),
                      if (selected)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.check_circle, color: AppTheme.vert, size: 20),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSelectLangue() {
    final langues = _languesDuPays;
    return Column(
      children: langues.map((code) {
        final selected = _langueSelectionnee == code;
        return GestureDetector(
          onTap: () {
            setState(() => _langueSelectionnee = code);
            _parler(LanguesData.getNatif(code));
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 12),
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
                Text(LanguesData.getDrapeau(code), style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(LanguesData.getNom(code),
                          style: TextStyle(
                            fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w700,
                            color: selected ? AppTheme.vert : Colors.white,
                          )),
                      Text(LanguesData.getNatif(code),
                          style: TextStyle(
                            fontFamily: 'Nunito', fontSize: 13,
                            color: selected ? AppTheme.grisTexte : Colors.white70,
                          )),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.volume_up_rounded,
                      color: selected ? AppTheme.vert : Colors.white70),
                  onPressed: () => _parler(LanguesData.getNatif(code)),
                ),
                if (selected)
                  Container(
                    width: 28, height: 28,
                    decoration: const BoxDecoration(color: AppTheme.vert, shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: Colors.white, size: 18),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}