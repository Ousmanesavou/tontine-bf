import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';

class ConnexionScreen extends StatefulWidget {
  const ConnexionScreen({super.key});

  @override
  State<ConnexionScreen> createState() => _ConnexionScreenState();
}

class _ConnexionScreenState extends State<ConnexionScreen> {
  final _telCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  bool _chargement = false;
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    final tel = StorageService.getDernierTelephone();
    if (tel != null) _telCtrl.text = tel;
  }

  Future<void> _connecter() async {
    if (_telCtrl.text.isEmpty || _pinCtrl.text.length != 4) return;
    setState(() => _chargement = true);

    try {
      final result = await ApiService.connexion(
        telephone: _telCtrl.text.trim(),
        codePin: _pinCtrl.text,
      );
      await StorageService.saveToken(result['token']);
      await StorageService.saveUser(result['user']);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        _tts.speak('Code PIN incorrect. Réessayez.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.rouge),
        );
        _pinCtrl.clear();
      }
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.vert,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text('💰', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            const Text(
              'Tontine BF',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Bienvenue !  •  Aw laafi !  •  I bisimila !',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'Connexion',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Entrez votre numéro et code PIN',
                        style: TextStyle(color: AppTheme.grisTexte),
                      ),
                      const SizedBox(height: 28),
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
                      ),
                      const SizedBox(height: 16),
                      _buildPinField(),
                      const SizedBox(height: 32),
                      _chargement
                          ? const Center(child: CircularProgressIndicator(color: AppTheme.vert))
                          : ElevatedButton(
                              onPressed: _connecter,
                              child: const Text('Se connecter'),
                            ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => context.go('/inscription'),
                          child: const Text(
                            'Pas encore de compte ? S\'inscrire',
                            style: TextStyle(color: AppTheme.vert),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildAideVocale(),
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

  Widget _buildPinField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Code PIN',
          style: TextStyle(fontSize: 13, color: AppTheme.grisTexte),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final filled = _pinCtrl.text.length > i;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: filled ? AppTheme.vertClair : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: filled ? AppTheme.vert : AppTheme.grisClair,
                  width: filled ? 2 : 1,
                ),
              ),
              child: Center(
                child: filled
                    ? const Text('●', style: TextStyle(fontSize: 20, color: AppTheme.vert))
                    : null,
              ),
            );
          }),
        ),
        const SizedBox(height: 14),
        _buildClavier(),
      ],
    );
  }

  Widget _buildClavier() {
    final touches = ['1','2','3','4','5','6','7','8','9','','0','⌫'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.8,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: touches.map((t) {
        if (t.isEmpty) return const SizedBox();
        return InkWell(
          onTap: () {
            setState(() {
              if (t == '⌫') {
                if (_pinCtrl.text.isNotEmpty) {
                  _pinCtrl.text = _pinCtrl.text.substring(0, _pinCtrl.text.length - 1);
                }
              } else if (_pinCtrl.text.length < 4) {
                _pinCtrl.text += t;
                if (_pinCtrl.text.length == 4) _connecter();
              }
            });
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.grisClair),
            ),
            child: Center(
              child: Text(
                t,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 20,
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

  Widget _buildAideVocale() {
    return GestureDetector(
      onTap: () => _tts.speak(
        'Pour vous connecter, entrez votre numéro de téléphone, puis votre code PIN à 4 chiffres.',
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.vertClair,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.volume_up_rounded, color: AppTheme.vert, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Appuyez ici pour entendre les instructions en mooré, dioula ou français',
                style: TextStyle(fontSize: 13, color: AppTheme.vertFonce),
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
