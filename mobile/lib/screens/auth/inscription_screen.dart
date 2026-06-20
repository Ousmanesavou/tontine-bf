import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../utils/app_localizations.dart';

class InscriptionScreen extends ConsumerStatefulWidget {
  const InscriptionScreen({super.key});

  @override
  ConsumerState<InscriptionScreen> createState() => _InscriptionScreenState();
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

  Future<void> _inscrire() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _chargement = true);

    try {
      final langue = StorageService.getLangue() ?? 'fr';
      final result = await ApiService.inscription(
        nom: _nomCtrl.text.trim(),
        prenom: _prenomCtrl.text.trim(),
        telephone: _telCtrl.text.trim(),
        codePin: _pinCtrl.text,
        langue: langue,
        moyenPaiement: _moyenPaiement,
      );

      await StorageService.saveToken(result['token']);
      await StorageService.saveUser(result['user']);

      if (mounted) {
        _tts.speak('Inscription réussie. Bienvenue sur Tontine BF !');
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
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppTheme.fond,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(l),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEtapeIndicateur(),
                      const SizedBox(height: 24),
                      if (_etape == 1) _buildEtape1(l),
                      if (_etape == 2) _buildEtape2(l),
                      if (_etape == 3) _buildEtape3(l),
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

  Widget _buildHeader(AppLocalizations l) {
    return Container(
      color: AppTheme.vert,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        children: [
          Row(
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
                  l.t('inscription'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up_rounded, color: Colors.white70),
                onPressed: () => _tts.speak(
                  'Remplissez votre nom, prénom, numéro de téléphone et créez votre code PIN.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEtapeIndicateur() {
    return Row(
      children: List.generate(3, (i) {
        final active = i + 1 == _etape;
        final done = i + 1 < _etape;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: done || active ? AppTheme.vert : AppTheme.grisClair,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEtape1(AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Qui êtes-vous ?',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        const Text('Votre nom complet',
            style: TextStyle(color: AppTheme.grisTexte)),
        const SizedBox(height: 20),
        TextFormField(
          controller: _prenomCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Prénom',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _nomCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nom de famille',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: () {
            if (_prenomCtrl.text.isNotEmpty && _nomCtrl.text.isNotEmpty) {
              setState(() => _etape = 2);
            }
          },
          child: const Text('Suivant →'),
        ),
        const SizedBox(height: 14),
        Center(
          child: TextButton(
            onPressed: () => context.go('/connexion'),
            child: const Text(
              'J\'ai déjà un compte',
              style: TextStyle(color: AppTheme.vert),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEtape2(AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Votre téléphone',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        const Text('Numéro Burkina Faso (Orange ou Moov)',
            style: TextStyle(color: AppTheme.grisTexte)),
        const SizedBox(height: 20),
        TextFormField(
          controller: _telCtrl,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Numéro de téléphone',
            prefixIcon: Icon(Icons.phone_outlined),
            prefixText: '+226 ',
            hintText: '70 XX XX XX',
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Requis';
            if (v.length < 8) return 'Numéro invalide';
            return null;
          },
        ),
        const SizedBox(height: 20),
        const Text('Mobile Money principal',
            style: TextStyle(color: AppTheme.grisTexte, fontSize: 13)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildMoyenPaiementBtn('orange_money', 'Orange Money', Colors.orange)),
            const SizedBox(width: 10),
            Expanded(child: _buildMoyenPaiementBtn('moov_money', 'Moov Money', const Color(0xFF0066CC))),
          ],
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: () {
            if (_telCtrl.text.length >= 8) setState(() => _etape = 3);
          },
          child: const Text('Suivant →'),
        ),
      ],
    );
  }

  Widget _buildMoyenPaiementBtn(String code, String label, Color color) {
    final selected = _moyenPaiement == code;
    return GestureDetector(
      onTap: () => setState(() => _moyenPaiement = code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AppTheme.grisClair,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
              child: Center(
                child: Text(
                  code == 'orange_money' ? 'OM' : 'MM',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? color : AppTheme.texte)),
          ],
        ),
      ),
    );
  }

  Widget _buildEtape3(AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Votre code secret',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        const Text('Créez un code PIN à 4 chiffres. Mémorisez-le bien !',
            style: TextStyle(color: AppTheme.grisTexte)),
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
            labelText: 'Code PIN (4 chiffres)',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_pinVisible ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _pinVisible = !_pinVisible),
            ),
          ),
          validator: (v) {
            if (v == null || v.length != 4) return 'PIN doit avoir 4 chiffres';
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
          decoration: const InputDecoration(
            labelText: 'Confirmer le PIN',
            prefixIcon: Icon(Icons.lock_outline),
          ),
          validator: (v) {
            if (v != _pinCtrl.text) return 'Les codes PIN ne correspondent pas';
            return null;
          },
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.orangeClair,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.orangeFonce, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ne partagez jamais votre code PIN avec personne.',
                  style: TextStyle(fontSize: 12, color: AppTheme.orangeFonce),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _chargement
            ? const Center(child: CircularProgressIndicator(color: AppTheme.vert))
            : ElevatedButton(
                onPressed: _inscrire,
                child: const Text('Créer mon compte'),
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
