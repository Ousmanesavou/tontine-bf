import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../utils/app_theme.dart';
import '../../utils/pays_data.dart';
import '../../utils/langues_data.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../main.dart';

// ── TRADUCTIONS ───────────────────────────────────────
const Map<String, Map<String, String>> _tr = {
  'fr': {
    'titre': 'Créer un compte',
    'qui': 'Qui êtes-vous ?',
    'qui_desc': 'Votre nom complet',
    'prenom': 'Prénom',
    'nom': 'Nom de famille',
    'suivant': 'Suivant →',
    'deja_compte': 'J\'ai déjà un compte',
    'telephone': 'Votre téléphone',
    'tel_desc': 'Numéro de téléphone',
    'tel_hint': '70 XX XX XX',
    'mobile_money': 'Mobile Money principal',
    'code_secret': 'Votre code secret',
    'pin_desc': 'Créez un code PIN à 4 chiffres. Mémorisez-le bien !',
    'pin': 'Code PIN (4 chiffres)',
    'pin_confirmer': 'Confirmer le PIN',
    'pin_attention': 'Ne partagez jamais votre code PIN avec personne.',
    'creer': 'Créer mon compte',
    'succes': 'Inscription réussie. Bienvenue sur TontiLigdi !',
    'requis': 'Requis',
    'tel_invalide': 'Numéro invalide',
    'pin_4': 'PIN doit avoir 4 chiffres',
    'pin_match': 'Les codes PIN ne correspondent pas',
    'vocal': 'Remplissez votre nom, prénom, numéro de téléphone et créez votre code PIN.',
    'etape1': 'Identité',
    'etape2': 'Téléphone',
    'etape3': 'Code PIN',
  },
  'en': {
    'titre': 'Create account',
    'qui': 'Who are you?',
    'qui_desc': 'Your full name',
    'prenom': 'First name',
    'nom': 'Last name',
    'suivant': 'Next →',
    'deja_compte': 'I already have an account',
    'telephone': 'Your phone',
    'tel_desc': 'Phone number',
    'tel_hint': '70 XX XX XX',
    'mobile_money': 'Primary Mobile Money',
    'code_secret': 'Your secret code',
    'pin_desc': 'Create a 4-digit PIN. Remember it well!',
    'pin': 'PIN code (4 digits)',
    'pin_confirmer': 'Confirm PIN',
    'pin_attention': 'Never share your PIN with anyone.',
    'creer': 'Create my account',
    'succes': 'Registration successful. Welcome to TontiLigdi!',
    'requis': 'Required',
    'tel_invalide': 'Invalid number',
    'pin_4': 'PIN must have 4 digits',
    'pin_match': 'PIN codes do not match',
    'vocal': 'Fill in your name, phone number and create your PIN code.',
    'etape1': 'Identity',
    'etape2': 'Phone',
    'etape3': 'PIN Code',
  },
  'mos': {
    'titre': 'Bʋg kaont',
    'qui': 'Yãmba ãnda?',
    'qui_desc': 'F yʋʋre fãa',
    'prenom': 'Yʋʋr paalg',
    'nom': 'Yʋʋr',
    'suivant': 'Tɩ zãg →',
    'deja_compte': 'M kaont bee ne',
    'telephone': 'F tɛlɛfõ',
    'tel_desc': 'Tɛlɛfõ nimero',
    'tel_hint': '70 XX XX XX',
    'mobile_money': 'Mobile Money',
    'code_secret': 'F code secret',
    'pin_desc': 'Bʋg PIN 4 woto. Tɩ tẽeg naoor !',
    'pin': 'PIN (woto 4)',
    'pin_confirmer': 'Wilg PIN kãsem',
    'pin_attention': 'Da wilg f PIN ned neba ye.',
    'creer': 'Bʋg m kaont',
    'succes': 'Toeega sɩnga. Aw laafi TontiLigdi !',
    'requis': 'Tõnd',
    'tel_invalide': 'Nimero ka sɩd',
    'pin_4': 'PIN tõnd woto 4',
    'pin_match': 'PIN yii ka zemse ye',
    'vocal': 'Sɩbg f yʋʋre, tɛlɛfõ la bʋg PIN.',
    'etape1': 'Yʋʋre',
    'etape2': 'Tɛlɛfõ',
    'etape3': 'PIN',
  },
  'bm': {
    'titre': 'Konto daminɛ',
    'qui': 'I ye jɛn?',
    'qui_desc': 'I tɔgɔ bɛɛ',
    'prenom': 'Tɔgɔ fɔlɔ',
    'nom': 'Jamu',
    'suivant': 'Taa ɲɛ →',
    'deja_compte': 'N ka konto be yen',
    'telephone': 'I ka telefɔni',
    'tel_desc': 'Telefɔni nimɔrɔ',
    'tel_hint': '70 XX XX XX',
    'mobile_money': 'Mobile Money',
    'code_secret': 'I ka code secret',
    'pin_desc': 'PIN 4 tonbi daminɛ. A kalan ka ɲɛ !',
    'pin': 'PIN (tonbi 4)',
    'pin_confirmer': 'PIN sɛgɛsɛgɛ',
    'pin_attention': 'I ka PIN mɔgɔ si ma fɔ.',
    'creer': 'N ka konto daminɛ',
    'succes': 'Sɛbɛnni kɛra. Bisimila TontiLigdi !',
    'requis': 'Ɲɛnabɔ',
    'tel_invalide': 'Nimɔrɔ tɛ ɲɛ',
    'pin_4': 'PIN tonbi 4 ɲɛnabɔ',
    'pin_match': 'PIN fila tɛ kelen ye',
    'vocal': 'I tɔgɔ, telefɔni ni PIN sɛbɛn.',
    'etape1': 'Tɔgɔ',
    'etape2': 'Telefɔni',
    'etape3': 'PIN',
  },
  'wo': {
    'titre': 'Def kont',
    'qui': 'Yow lan nga?',
    'qui_desc': 'Sa tur bu dëkk',
    'prenom': 'Tur bu njëkk',
    'nom': 'Jamu',
    'suivant': 'Dem ëntë →',
    'deja_compte': 'Am naa kont',
    'telephone': 'Sa telefon',
    'tel_desc': 'Nimero bu telefon',
    'tel_hint': '70 XX XX XX',
    'mobile_money': 'Mobile Money',
    'code_secret': 'Sa code secret',
    'pin_desc': 'Def PIN bu ñent xët. Xam ko !',
    'pin': 'PIN (ñent xët)',
    'pin_confirmer': 'Seytaan PIN bi',
    'pin_attention': 'Bul jox sa PIN nit ku bari.',
    'creer': 'Def sa kont',
    'succes': 'Sɛriñ rekk. Dalal TontiLigdi !',
    'requis': 'Waajib',
    'tel_invalide': 'Nimero bu baax',
    'pin_4': 'PIN dafa soxor ñent xët',
    'pin_match': 'PIN yi dafañu bokk',
    'vocal': 'Bind sa tur, telefon ak def PIN.',
    'etape1': 'Tur',
    'etape2': 'Telefon',
    'etape3': 'PIN',
  },
};

String _t(String langue, String key) {
  final lang = _tr[langue] ?? _tr['fr']!;
  return lang[key] ?? _tr['fr']![key] ?? key;
}

class InscriptionScreen extends ConsumerStatefulWidget {
  const InscriptionScreen({super.key});

  @override
  ConsumerState<InscriptionScreen> createState() =>
      _InscriptionScreenState();
}

class _InscriptionScreenState extends ConsumerState<InscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _pinConfirmCtrl = TextEditingController();
  String _moyenPaiement = 'orange_money';
  bool _chargement = false;
  bool _pinVisible = false;
  final FlutterTts _tts = FlutterTts();
  int _etape = 1;

  Future<void> _inscrire(String langue, String pays) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _chargement = true);

    try {
      final paysInfo = PaysData.getPays(pays);
      final indicatif = paysInfo?['indicatif'] ?? '+226';

      final result = await ApiService.inscription(
        nom: _nomCtrl.text.trim(),
        prenom: _prenomCtrl.text.trim(),
        telephone: _telCtrl.text.trim(),
        codePin: _pinCtrl.text,
        langue: langue,
        pays: pays,
        moyenPaiement: _moyenPaiement,
        indicatif: indicatif,
      );

      await StorageService.saveToken(result['token']);
      await StorageService.saveUser(result['user']);

      if (mounted) {
        _tts.speak(_t(langue, 'succes'));
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.rouge,
          ),
        );
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
    final isSmall = sw < 360;
    final paysInfo = PaysData.getPays(pays);
    final mobileMoney = List<String>.from(
        paysInfo?['mobile_money'] ?? ['Orange Money']);

    return Scaffold(
      backgroundColor: AppTheme.fond,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(langue, isSmall),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isSmall ? 16 : 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEtapeIndicateur(langue, isSmall),
                      SizedBox(height: isSmall ? 16 : 24),
                      if (_etape == 1)
                        _buildEtape1(langue, isSmall),
                      if (_etape == 2)
                        _buildEtape2(langue, pays, paysInfo,
                            mobileMoney, isSmall),
                      if (_etape == 3)
                        _buildEtape3(langue, pays, isSmall),
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

  Widget _buildHeader(String langue, bool isSmall) {
    return Container(
      color: AppTheme.vert,
      padding: EdgeInsets.fromLTRB(8, isSmall ? 8 : 12, 8, isSmall ? 12 : 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (_etape > 1) {
                setState(() => _etape--);
              } else {
                context.go('/langue');
              }
            },
          ),
          Expanded(
            child: Text(
              _t(langue, 'titre'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: isSmall ? 16 : 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.volume_up_rounded,
                color: Colors.white70),
            onPressed: () => _tts.speak(_t(langue, 'vocal')),
          ),
        ],
      ),
    );
  }

  Widget _buildEtapeIndicateur(String langue, bool isSmall) {
    final etapes = [
      _t(langue, 'etape1'),
      _t(langue, 'etape2'),
      _t(langue, 'etape3'),
    ];
    return Row(
      children: List.generate(3, (i) {
        final active = i + 1 == _etape;
        final done = i + 1 < _etape;
        return Expanded(
          child: GestureDetector(
            onTap: done ? () => setState(() => _etape = i + 1) : null,
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: done || active
                        ? AppTheme.vert
                        : AppTheme.grisClair,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  etapes[i],
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: isSmall ? 9 : 10,
                    fontWeight: active
                        ? FontWeight.w700
                        : FontWeight.normal,
                    color: active
                        ? AppTheme.vert
                        : AppTheme.grisTexte,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ── ÉTAPE 1 : IDENTITÉ ────────────────────────────
  Widget _buildEtape1(String langue, bool isSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t(langue, 'qui'),
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: isSmall ? 18 : 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.texte,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _t(langue, 'qui_desc'),
          style: const TextStyle(
              color: AppTheme.grisTexte, fontFamily: 'Nunito'),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _prenomCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: _t(langue, 'prenom'),
            prefixIcon: const Icon(Icons.person_outline),
          ),
          validator: (v) =>
              v == null || v.isEmpty ? _t(langue, 'requis') : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _nomCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: _t(langue, 'nom'),
            prefixIcon: const Icon(Icons.person_outline),
          ),
          validator: (v) =>
              v == null || v.isEmpty ? _t(langue, 'requis') : null,
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: isSmall ? 46 : 52,
          child: ElevatedButton(
            onPressed: () {
              if (_prenomCtrl.text.isNotEmpty &&
                  _nomCtrl.text.isNotEmpty) {
                setState(() => _etape = 2);
              }
            },
            child: Text(_t(langue, 'suivant')),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: TextButton(
            onPressed: () => context.go('/connexion'),
            child: Text(
              _t(langue, 'deja_compte'),
              style: const TextStyle(color: AppTheme.vert),
            ),
          ),
        ),
      ],
    );
  }

  // ── ÉTAPE 2 : TÉLÉPHONE ───────────────────────────
  Widget _buildEtape2(String langue, String pays,
      Map<String, dynamic>? paysInfo,
      List<String> mobileMoney, bool isSmall) {
    final indicatif = paysInfo?['indicatif'] ?? '+226';
    final drapeau = paysInfo?['drapeau'] ?? '🌍';
    final nomPays = paysInfo?['nom'] ?? pays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t(langue, 'telephone'),
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: isSmall ? 18 : 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.texte,
          ),
        ),
        const SizedBox(height: 4),
        // Indicateur pays
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.vertClair,
            borderRadius: BorderRadius.circular(10),
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
                  fontWeight: FontWeight.w600,
                  color: AppTheme.vertFonce,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _telCtrl,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly
          ],
          decoration: InputDecoration(
            labelText: _t(langue, 'tel_desc'),
            prefixIcon: const Icon(Icons.phone_outlined),
            prefixText: '$indicatif ',
            hintText: _t(langue, 'tel_hint'),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) {
              return _t(langue, 'requis');
            }
            if (v.length < 6) {
              return _t(langue, 'tel_invalide');
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        Text(
          _t(langue, 'mobile_money'),
          style: const TextStyle(
            color: AppTheme.grisTexte,
            fontSize: 13,
            fontFamily: 'Nunito',
          ),
        ),
        const SizedBox(height: 10),
        // Mobile Money dynamique selon le pays
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: mobileMoney.map((mm) {
            final code = mm
                .toLowerCase()
                .replaceAll(' ', '_');
            final selected = _moyenPaiement == code;
            final color = mm.toLowerCase().contains('orange')
                ? Colors.orange
                : mm.toLowerCase().contains('moov')
                    ? const Color(0xFF0066CC)
                    : mm.toLowerCase().contains('mtn')
                        ? const Color(0xFFFFCC00)
                        : AppTheme.vert;
            return GestureDetector(
              onTap: () =>
                  setState(() => _moyenPaiement = code),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? color.withOpacity(0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? color
                        : AppTheme.grisClair,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          mm.split(' ').map((w) => w[0]).take(2).join(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      mm,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? color
                            : AppTheme.texte,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: isSmall ? 46 : 52,
          child: ElevatedButton(
            onPressed: () {
              if (_telCtrl.text.length >= 6) {
                setState(() => _etape = 3);
              }
            },
            child: Text(_t(langue, 'suivant')),
          ),
        ),
      ],
    );
  }

  // ── ÉTAPE 3 : PIN ─────────────────────────────────
  Widget _buildEtape3(String langue, String pays, bool isSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t(langue, 'code_secret'),
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: isSmall ? 18 : 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.texte,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _t(langue, 'pin_desc'),
          style: const TextStyle(
              color: AppTheme.grisTexte, fontFamily: 'Nunito'),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _pinCtrl,
          obscureText: !_pinVisible,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          decoration: InputDecoration(
            labelText: _t(langue, 'pin'),
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_pinVisible
                  ? Icons.visibility_off
                  : Icons.visibility),
              onPressed: () =>
                  setState(() => _pinVisible = !_pinVisible),
            ),
          ),
          validator: (v) {
            if (v == null || v.length != 4) {
              return _t(langue, 'pin_4');
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _pinConfirmCtrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          decoration: InputDecoration(
            labelText: _t(langue, 'pin_confirmer'),
            prefixIcon: const Icon(Icons.lock_outline),
          ),
          validator: (v) {
            if (v != _pinCtrl.text) {
              return _t(langue, 'pin_match');
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.orangeClair,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppTheme.orangeFonce, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _t(langue, 'pin_attention'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.orangeFonce,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _chargement
            ? const Center(
                child: CircularProgressIndicator(
                    color: AppTheme.vert))
            : SizedBox(
                width: double.infinity,
                height: isSmall ? 46 : 52,
                child: ElevatedButton(
                  onPressed: () => _inscrire(langue, pays),
                  child: Text(_t(langue, 'creer')),
                ),
              ),
      ],
    );
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _telCtrl.dispose();
    _pinCtrl.dispose();
    _pinConfirmCtrl.dispose();
    _tts.stop();
    super.dispose();
  }
}
