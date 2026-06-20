import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_theme.dart';
import '../../services/storage_service.dart';
import '../../services/vocal_service.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final VocalService _vocal = VocalService();
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _user = StorageService.getUser();
  }

  Future<void> _deconnecter() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Déconnexion',
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
        content: const Text('Voulez-vous vraiment vous déconnecter ?',
            style: TextStyle(fontFamily: 'Nunito')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler',
                style: TextStyle(color: AppTheme.grisTexte)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.rouge,
              minimumSize: const Size(100, 40),
            ),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.clearAll();
      if (mounted) context.go('/connexion');
    }
  }

  @override
  Widget build(BuildContext context) {
    final prenom = _user?['prenom'] ?? '';
    final nom = _user?['nom'] ?? '';
    final telephone = _user?['telephone'] ?? '';
    final langue = _user?['langue'] ?? 'fr';
    final score = _user?['score_fiabilite'] ?? 100;

    return Scaffold(
      backgroundColor: AppTheme.fond,
      appBar: AppBar(
        backgroundColor: AppTheme.vert,
        foregroundColor: Colors.white,
        title: const Text('Mon profil',
            style: TextStyle(fontFamily: 'Nunito', color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded, color: Colors.white70),
            onPressed: () => _vocal.parler('Votre profil. $prenom $nom.'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(prenom, nom, telephone, score),
            const SizedBox(height: 16),
            _buildSection('Mon compte', [
              _buildItem(Icons.person_outline, 'Nom complet', '$prenom $nom'),
              _buildItem(Icons.phone_outlined, 'Téléphone', telephone),
              _buildItem(Icons.language_outlined, 'Langue',
                  langue == 'moore' ? 'Mooré' : langue == 'dioula' ? 'Dioula' : 'Français'),
            ]),
            const SizedBox(height: 12),
            _buildSection('Mobile Money', [
              _buildItem(Icons.account_balance_wallet_outlined,
                  'Orange Money', _user?['orange_money_numero'] ?? 'Non configuré'),
              _buildItem(Icons.account_balance_wallet_outlined,
                  'Moov Money', _user?['moov_money_numero'] ?? 'Non configuré'),
            ]),
            const SizedBox(height: 12),
            _buildSection('Paramètres', [
              _buildItemAction(
                Icons.notifications_outlined,
                'Notifications',
                'Activées',
                () {},
              ),
              _buildItemAction(
                Icons.security_outlined,
                'Changer mon PIN',
                '',
                () {},
              ),
              _buildItemAction(
                Icons.help_outline,
                'Aide vocale',
                '',
                () => _vocal.parler(
                    'Bienvenue dans l\'aide. Pour créer une tontine, appuyez sur le bouton nouvelle tontine.'),
              ),
            ]),
            const SizedBox(height: 12),
            _buildSection('Score de fiabilité', [
              _buildScoreCard(score),
            ]),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: _deconnecter,
                icon: const Icon(Icons.logout, color: AppTheme.rouge),
                label: const Text('Se déconnecter',
                    style: TextStyle(color: AppTheme.rouge)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  side: const BorderSide(color: AppTheme.rouge),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text('Tontine BF v1.0.0',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: AppTheme.grisTexte)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String prenom, String nom, String telephone, int score) {
    return Container(
      color: AppTheme.vert,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Text(
                '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('$prenom $nom',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              )),
          const SizedBox(height: 4),
          Text(telephone,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                color: Colors.white70,
              )),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text('Score de fiabilité : $score/100',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String titre, List<Widget> enfants) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titre.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.grisTexte,
                letterSpacing: 0.8,
              )),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8E8E5), width: 0.5),
            ),
            child: Column(children: enfants),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(IconData icon, String label, String valeur) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.grisTexte),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        color: AppTheme.grisTexte)),
                Text(valeur,
                    style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.texte)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemAction(
      IconData icon, String label, String valeur, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.grisTexte),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ),
            if (valeur.isNotEmpty)
              Text(valeur,
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      color: AppTheme.grisTexte)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppTheme.grisTexte, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(int score) {
    final couleur = score >= 80
        ? AppTheme.vert
        : score >= 50
            ? AppTheme.orange
            : AppTheme.rouge;
    final message = score >= 80
        ? 'Excellent ! Vous êtes un membre très fiable.'
        : score >= 50
            ? 'Bien. Continuez à payer à temps.'
            : 'Attention. Des retards ont été enregistrés.';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    backgroundColor: AppTheme.grisClair,
                    valueColor: AlwaysStoppedAnimation<Color>(couleur),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('$score/100',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: couleur,
                  )),
            ],
          ),
          const SizedBox(height: 8),
          Text(message,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                color: AppTheme.grisTexte,
              )),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _vocal.stop();
    super.dispose();
  }
}