import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../utils/app_theme.dart';
import '../../utils/pays_data.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../main.dart';

// ── TRADUCTIONS ───────────────────────────────────────
const Map<String, Map<String, String>> _tr = {
  'fr': {
    'titre': 'Connexion',
    'desc': 'Entrez votre numéro et code PIN',
    'telephone': 'Numéro de téléphone',
    'tel_hint': '70 XX XX XX',
    'pin': 'Code PIN',
    'connecter': 'Se connecter',
    'pas_compte': 'Pas encore de compte ? S\'inscrire',
    'aide': 'Appuyez ici pour les instructions vocales',
    'vocal': 'Pour vous connecter, entrez votre numéro de téléphone, puis votre code PIN à 4 chiffres.',
    'erreur_pin': 'Code PIN incorrect. Réessayez.',
    'changer_pays': 'Changer de pays',
    'bienvenue': 'Bienvenue !',
    'slogan': 'Ensemble, on grandit',
  },
  'en': {
    'titre': 'Sign in',
    'desc': 'Enter your number and PIN code',
    'telephone': 'Phone number',
    'tel_hint': '70 XX XX XX',
    'pin': 'PIN code',
    'connecter': 'Sign in',
    'pas_compte': 'No account yet? Register',
    'aide': 'Tap here for voice instructions',
    'vocal': 'To sign in, enter your phone number, then your 4-digit PIN code.',
    'erreur_pin': 'Incorrect PIN. Try again.',
    'changer_pays': 'Change country',
    'bienvenue': 'Welcome!',
    'slogan': 'Together, we grow',
  },
  'mos': {
    'titre': 'Zãgs',
    'desc': 'Sɩbg f nimero la PIN code',
    'telephone': 'Tɛlɛfõ nimero',
    'tel_hint': '70 XX XX XX',
    'pin': 'PIN code',
    'connecter': 'Zãgs',
    'pas_compte': 'Kaont ka be tɩ ta? Toeeg',
    'aide': 'Paam kãn n kelg zãgsem',
    'vocal': 'Tɩ zãgs, sɩbg f tɛlɛfõ nimero, la f PIN woto 4.',
    'erreur_pin': 'PIN ka sɩd ye. Tɩ sok kãsem.',
    'changer_pays': 'Toeeg tẽng',
    'bienvenue': 'Aw laafi !',
    'slogan': 'Tõnd fãa, tõnd zagsame',
  },
  'bm': {
    'titre': 'Don',
    'desc': 'I ka nimɔrɔ ni PIN sɛbɛn',
    'telephone': 'Telefɔni nimɔrɔ',
    'tel_hint': '70 XX XX XX',
    'pin': 'PIN code',
    'connecter': 'Don',
    'pas_compte': 'Konto si be yen? Sɛbɛn',
    'aide': 'Dɔn yan ka kuma lamɛn',
    'vocal': 'Don kama, i ka telefɔni nimɔrɔ ni PIN tonbi 4 sɛbɛn.',
    'erreur_pin': 'PIN tɛ ɲɛ. A lajɛ.',
    'changer_pays': 'Jamana yɛlɛma',
    'bienvenue': 'Bisimila !',
    'slogan': 'An bɛɛ ye dɔn',
  },
  'wo': {
    'titre': 'Dugg',
    'desc': 'Bind sa nimero ak PIN bi',
    'telephone': 'Nimero bu telefon',
    'tel_hint': '70 XX XX XX',
    'pin': 'PIN code',
    'connecter': 'Dugg',
    'pas_compte': 'Kont amul? Bind',
    'aide': 'Dox fii ngir xam-xam bu kàddu',
    'vocal': 'Ngir dugg, bind sa nimero ak PIN bu ñent xët.',
    'erreur_pin': 'PIN bi dëgërul. Jëf ci kanam.',
    'changer_pays': 'Soppi dëkk',
    'bienvenue': 'Dalal ak jàmm !',
    'slogan': 'Ci dekk, danu dem yëgël',
  },
};

String _t(String langue, String key) {
  final lang = _tr[langue] ?? _tr['fr']!;
  return lang[key] ?? _tr['fr']![key] ?? key;
}

class ConnexionScreen extends ConsumerStatefulWidget {
  const ConnexionScreen({super.key});

  @override
  ConsumerState<ConnexionScreen> createState() =>
      _ConnexionScreenState();
}

class _ConnexionScreenState extends ConsumerState<ConnexionScreen> {
  final _telCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  bool _chargement = false;
  bool _erreurPin = false;
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    // Pré-remplir dernier téléphone
    final tel = StorageService.getDernierTelephone();
    if (tel != null) {
      final pays = StorageService.getPays() ?? 'BF';
      final paysInfo = PaysData.getPays(pays);
      final indicatif = paysInfo?['indicatif'] ?? '+226';
      _telCtrl.text = tel
          .replaceAll(indicatif, '')
          .replaceAll('+226', '')
          .replaceAll('+221', '')
          .replaceAll('+225', '');
    }
  }

  Future<void> _connecter(String langue, String pays) async {
    if (_telCtrl.text.isEmpty || _pinCtrl.text.length != 4) return;
    setState(() {
      _chargement = true;
      _erreurPin = false;
    });

    try {
      final paysInfo = PaysData.getPays(pays);
      final indicatif = paysInfo?['indicatif'] ?? '+226';

      final result = await ApiService.connexion(
        telephone: _telCtrl.text.trim(),
        codePin: _pinCtrl.text,
        indicatif: indicatif,
      );
      await StorageService.saveToken(result['token']);
      await StorageService.saveUser(result['user']);

      // Sync langue depuis le profil
      if (result['user']?['langue'] != null) {
        final langueUser = result['user']['langue'];
        await StorageService.saveLangue(langueUser);
        ref.read(langueProvider.notifier).state = langueUser;
      }

      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        setState(() => _erreurPin = true);
        _tts.speak(_t(langue, 'erreur_pin'));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.rouge,
          ),
        );
        _pinCtrl.clear();
      }
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final langue = ref.watch(langueProvider);
    final pays = ref.watch(paysProvider);
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final isSmall = sw < 360;
    final paysInfo = PaysData.getPays(pays);
    final indicatif = paysInfo?['indicatif'] ?? '+226';
    final drapeau = paysInfo?['drapeau'] ?? '🌍';
    final nomPays = paysInfo?['nom'] ?? pays;

    return Scaffold(
      backgroundColor: AppTheme.vert,
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                  isSmall ? 16 : 20,
                  isSmall ? 20 : 30,
                  isSmall ? 16 : 20,
                  isSmall ? 16 : 20),
              child: Column(
                children: [
                  const Text('💰',
                      style: TextStyle(fontSize: 52)),
                  const SizedBox(height: 10),
                  const Text(
                    'TontiLigdi',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _t(langue, 'slogan'),
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Sélecteur pays
                  GestureDetector(
                    onTap: () => context.go('/langue'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(drapeau,
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(
                            '$nomPays $indicatif',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white70,
                              size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── FORMULAIRE ────────────────────────────
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isSmall ? 20 : 24),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        _t(langue, 'titre'),
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: isSmall ? 20 : 24,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.texte,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _t(langue, 'desc'),
                        style: const TextStyle(
                            color: AppTheme.grisTexte,
                            fontFamily: 'Nunito'),
                      ),
                      const SizedBox(height: 24),

                      // Champ téléphone
                      TextFormField(
                        controller: _telCtrl,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onChanged: (_) {
                          if (_erreurPin) {
                            setState(() => _erreurPin = false);
                          }
                        },
                        decoration: InputDecoration(
                          labelText: _t(langue, 'telephone'),
                          prefixIcon:
                              const Icon(Icons.phone_outlined),
                          prefixText: '$indicatif ',
                          hintText: _t(langue, 'tel_hint'),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // PIN
                      _buildPinField(langue, pays, isSmall),
                      SizedBox(height: isSmall ? 24 : 32),

                      // Bouton connexion
                      _chargement
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: AppTheme.vert))
                          : SizedBox(
                              width: double.infinity,
                              height: isSmall ? 48 : 54,
                              child: ElevatedButton(
                                onPressed: () =>
                                    _connecter(langue, pays),
                                child: Text(
                                  _t(langue, 'connecter'),
                                  style: TextStyle(
                                      fontSize: isSmall ? 15 : 17),
                                ),
                              ),
                            ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () =>
                              context.go('/inscription'),
                          child: Text(
                            _t(langue, 'pas_compte'),
                            style: const TextStyle(
                                color: AppTheme.vert),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildAideVocale(langue, isSmall),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinField(String langue, String pays, bool isSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t(langue, 'pin'),
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: isSmall ? 12 : 13,
            color: AppTheme.grisTexte,
          ),
        ),
        const SizedBox(height: 10),
        // Affichage PIN
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final filled = _pinCtrl.text.length > i;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.symmetric(
                  horizontal: isSmall ? 6 : 8),
              width: isSmall ? 46 : 54,
              height: isSmall ? 46 : 54,
              decoration: BoxDecoration(
                color: _erreurPin
                    ? AppTheme.rougeClair
                    : filled
                        ? AppTheme.vertClair
                        : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _erreurPin
                      ? AppTheme.rouge
                      : filled
                          ? AppTheme.vert
                          : AppTheme.grisClair,
                  width: filled || _erreurPin ? 2 : 1,
                ),
              ),
              child: Center(
                child: filled
                    ? Text(
                        '●',
                        style: TextStyle(
                          fontSize: isSmall ? 18 : 22,
                          color: _erreurPin
                              ? AppTheme.rouge
                              : AppTheme.vert,
                        ),
                      )
                    : null,
              ),
            );
          }),
        ),
        const SizedBox(height: 14),
        // Clavier
        _buildClavier(langue, pays, isSmall),
      ],
    );
  }

  Widget _buildClavier(
      String langue, String pays, bool isSmall) {
    final touches = [
      '1', '2', '3',
      '4', '5', '6',
      '7', '8', '9',
      '', '0', '⌫',
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: isSmall ? 2.0 : 1.8,
      mainAxisSpacing: isSmall ? 6 : 8,
      crossAxisSpacing: isSmall ? 6 : 8,
      children: touches.map((t) {
        if (t.isEmpty) return const SizedBox();
        final isDelete = t == '⌫';
        return InkWell(
          onTap: () {
            setState(() {
              _erreurPin = false;
              if (isDelete) {
                if (_pinCtrl.text.isNotEmpty) {
                  _pinCtrl.text = _pinCtrl.text.substring(
                      0, _pinCtrl.text.length - 1);
                }
              } else if (_pinCtrl.text.length < 4) {
                _pinCtrl.text += t;
                if (_pinCtrl.text.length == 4) {
                  _connecter(langue, pays);
                }
              }
            });
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: isDelete
                  ? AppTheme.grisClair
                  : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppTheme.grisClair),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: isDelete
                  ? Icon(
                      Icons.backspace_outlined,
                      size: isSmall ? 20 : 22,
                      color: AppTheme.grisTexte,
                    )
                  : Text(
                      t,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: isSmall ? 18 : 22,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.texte,
                      ),
                    ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAideVocale(String langue, bool isSmall) {
    return GestureDetector(
      onTap: () => _tts.speak(_t(langue, 'vocal')),
      child: Container(
        padding: EdgeInsets.all(isSmall ? 12 : 14),
        decoration: BoxDecoration(
          color: AppTheme.vertClair,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.volume_up_rounded,
                color: AppTheme.vert, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _t(langue, 'aide'),
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: isSmall ? 12 : 13,
                  color: AppTheme.vertFonce,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _telCtrl.dispose();
    _pinCtrl.dispose();
    _tts.stop();
    super.dispose();
  }
}
