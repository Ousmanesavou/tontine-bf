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
  int _etape = 1;
  String _paysSelectionne = 'BF';
  String _langueSelectionnee = 'fr';
  final FlutterTts _tts = FlutterTts();

  List<String> get _languesDuPays => PaysData.getLanguesPays(_paysSelectionne);

  @override
  void initState() {
    super.initState();
    _parler('Bienvenue sur Tontine Africa. Choisissez votre pays.');
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
        await _sauvegarder();
      } else {
        setState(() => _etape = 2);
        _parler('Choisissez votre langue.');
      }
    } else {
      await _sauvegarder();
    }
  }

  Future<void> _sauvegarder() async {
    await StorageService.saveLangue(_langueSelectionnee);
    await StorageService.savePays(_paysSelectionne);
    ref.read(langueProvider.notifier).state = _langueSelectionnee;
    if (mounted) context.go('/inscription');
  }

  void _ouvrirSelecteurPays() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SelecteurPays(
        paysSelectionne: _paysSelectionne,
        onPaysSelectionne: (code) {
          setState(() {
            _paysSelectionne = code;
            final langues = PaysData.getLanguesPays(code);
            _langueSelectionnee = langues.first;
          });
          _parler(PaysData.getPays(code)?['nom'] ?? '');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.vert,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              Expanded(
                child: _etape == 1
                    ? _buildSelectPays()
                    : _buildSelectLangue(),
              ),
              const SizedBox(height: 16),
              _buildBoutonContinuer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final pays = PaysData.getPays(_paysSelectionne);
    return Column(
      children: [
        Text(
          _etape == 1 ? '🌍' : (pays?['drapeau'] ?? '🌍'),
          style: const TextStyle(fontSize: 52),
        ),
        const SizedBox(height: 10),
        const Text(
          'Tontine Africa',
          style: TextStyle(
            fontFamily: 'Nunito', fontSize: 26,
            fontWeight: FontWeight.w800, color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _etape == 1
              ? 'Sélectionnez votre pays'
              : 'Choisissez votre langue',
          style: const TextStyle(
            fontFamily: 'Nunito', fontSize: 14,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildEtapeIndicateur(1, '🌍 Pays'),
            const SizedBox(width: 8),
            Container(width: 30, height: 2, color: Colors.white30),
            const SizedBox(width: 8),
            _buildEtapeIndicateur(2, '🗣️ Langue'),
          ],
        ),
      ],
    );
  }

  Widget _buildEtapeIndicateur(int num, String label) {
    final active = _etape >= num;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white24,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Nunito', fontSize: 11,
          fontWeight: FontWeight.w700,
          color: active ? AppTheme.vert : Colors.white60,
        ),
      ),
    );
  }

  Widget _buildSelectPays() {
    final pays = PaysData.getPays(_paysSelectionne);
    return Column(
      children: [
        // Bouton sélection pays
        GestureDetector(
          onTap: _ouvrirSelecteurPays,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Text(pays?['drapeau'] ?? '🌍',
                    style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pays?['nom'] ?? 'Choisir un pays',
                        style: const TextStyle(
                          fontFamily: 'Nunito', fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.vert,
                        ),
                      ),
                      Text(
                        '${pays?['indicatif']} • ${pays?['devise']}',
                        style: const TextStyle(
                          fontFamily: 'Nunito', fontSize: 13,
                          color: AppTheme.grisTexte,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.vert, size: 28),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Mobile Money
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '💳 Mobile Money disponible',
                style: TextStyle(
                  fontFamily: 'Nunito', fontSize: 12,
                  fontWeight: FontWeight.w700, color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: List<String>.from(
                    pays?['mobile_money'] ?? ['Orange Money'])
                    .map((mm) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            mm,
                            style: const TextStyle(
                              fontFamily: 'Nunito', fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Devise
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Text('💰', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Devise utilisée',
                    style: TextStyle(
                      fontFamily: 'Nunito', fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    pays?['devise'] ?? 'XOF',
                    style: const TextStyle(
                      fontFamily: 'Nunito', fontSize: 16,
                      fontWeight: FontWeight.w700, color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectLangue() {
    final langues = _languesDuPays;
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _etape = 1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back,
                    color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${PaysData.getPays(_paysSelectionne)?['drapeau']} '
                  '${PaysData.getPays(_paysSelectionne)?['nom']}',
                  style: const TextStyle(
                    fontFamily: 'Nunito', fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: langues.map((code) {
              final selected = _langueSelectionnee == code;
              final nom = LanguesData.getNom(code);
              final natif = LanguesData.getNatif(code);
              final drapeau = LanguesData.getDrapeau(code);
              return GestureDetector(
                onTap: () {
                  setState(() => _langueSelectionnee = code);
                  _parler(natif);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white
                        : Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? Colors.white : Colors.white38,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(drapeau,
                          style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(nom,
                              style: TextStyle(
                                fontFamily: 'Nunito', fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? AppTheme.vert
                                    : Colors.white,
                              )),
                            Text(natif,
                              style: TextStyle(
                                fontFamily: 'Nunito', fontSize: 13,
                                color: selected
                                    ? AppTheme.grisTexte
                                    : Colors.white70,
                              )),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.volume_up_rounded,
                          color: selected
                              ? AppTheme.vert
                              : Colors.white70),
                        onPressed: () => _parler(natif),
                      ),
                      if (selected)
                        Container(
                          width: 28, height: 28,
                          decoration: const BoxDecoration(
                            color: AppTheme.vert,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check,
                              color: Colors.white, size: 18),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBoutonContinuer() {
    final pays = PaysData.getPays(_paysSelectionne);
    return ElevatedButton(
      onPressed: _continuer,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.vert,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        _etape == 1
            ? 'Continuer avec ${pays?['drapeau']} ${pays?['nom']} →'
            : 'Commencer →',
        style: const TextStyle(
          fontFamily: 'Nunito', fontSize: 16,
          fontWeight: FontWeight.w700,
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

// ── SELECTEUR PAYS ────────────────────────────────────
class _SelecteurPays extends StatefulWidget {
  final String paysSelectionne;
  final Function(String) onPaysSelectionne;

  const _SelecteurPays({
    required this.paysSelectionne,
    required this.onPaysSelectionne,
  });

  @override
  State<_SelecteurPays> createState() => _SelecteurPaysState();
}

class _SelecteurPaysState extends State<_SelecteurPays> {
  final TextEditingController _ctrl = TextEditingController();
  List<Map<String, dynamic>> _paysFiltres = [];

  @override
  void initState() {
    super.initState();
    _paysFiltres = PaysData.pays;
  }

  void _filtrer(String v) {
    setState(() {
      if (v.isEmpty) {
        _paysFiltres = PaysData.pays;
      } else {
        _paysFiltres = PaysData.pays.where((p) =>
          p['nom'].toString().toLowerCase().contains(v.toLowerCase()) ||
          p['indicatif'].toString().contains(v)
        ).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE8E8E5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Choisir un pays',
              style: TextStyle(
                fontFamily: 'Nunito', fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _ctrl,
              autofocus: false,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                hintText: 'Rechercher un pays...',
                prefixIcon: const Icon(Icons.search,
                    color: AppTheme.grisTexte),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppTheme.grisTexte),
                        onPressed: () {
                          _ctrl.clear();
                          _filtrer('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFFE8E8E5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppTheme.vert, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
              onChanged: _filtrer,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_paysFiltres.length} pays disponibles',
                  style: const TextStyle(
                    fontFamily: 'Nunito', fontSize: 12,
                    color: AppTheme.grisTexte,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _paysFiltres.length,
              itemBuilder: (ctx, i) {
                final p = _paysFiltres[i];
                final selected = widget.paysSelectionne == p['code'];
                return ListTile(
                  onTap: () {
                    widget.onPaysSelectionne(p['code']);
                    Navigator.pop(ctx);
                  },
                  leading: Text(p['drapeau'],
                      style: const TextStyle(fontSize: 26)),
                  title: Text(
                    p['nom'],
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppTheme.vert
                          : AppTheme.texte,
                    ),
                  ),
                  subtitle: Text(
                    '${p['indicatif']} • ${p['devise']}',
                    style: const TextStyle(
                      fontFamily: 'Nunito', fontSize: 12,
                      color: AppTheme.grisTexte,
                    ),
                  ),
                  trailing: selected
                      ? const Icon(Icons.check_circle,
                          color: AppTheme.vert)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  tileColor: selected
                      ? AppTheme.vertClair
                      : Colors.transparent,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}