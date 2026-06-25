import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/app_theme.dart';
import '../../services/storage_service.dart';
import '../../services/vocal_service.dart';
import '../../services/cloudinary_service.dart';
import '../../services/api_service.dart';
import '../../main.dart';

class ProfilScreen extends ConsumerStatefulWidget {
  const ProfilScreen({super.key});

  @override
  ConsumerState<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends ConsumerState<ProfilScreen> {
  final VocalService _vocal = VocalService();
  Map<String, dynamic>? _user;
  bool _uploadEnCours = false;
  String? _photoUrl;

  @override
void initState() {
  super.initState();
  _user = StorageService.getUser();
  // ✅ Chercher photo_url ET photo_profil
  _photoUrl = _user?['photo_url'] ?? _user?['photo_profil'];
}

  Future<void> _changerPhoto() async {
    final langue = ref.read(langueProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.grisClair,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              langue == 'en' ? 'Change photo' :
              langue == 'mos' ? 'Foto yiisi' :
              langue == 'bm' ? 'Foto yɛlɛma' :
              'Changer la photo',
              style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.vertClair,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_outlined,
                    color: AppTheme.vert),
              ),
              title: Text(
                langue == 'en' ? 'Take photo' : 'Prendre une photo',
                style: const TextStyle(
                    fontFamily: 'Nunito', fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.vertClair,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_outlined,
                    color: AppTheme.vert),
              ),
              title: Text(
                langue == 'en' ? 'Choose from gallery' : 'Choisir depuis la galerie',
                style: const TextStyle(
                    fontFamily: 'Nunito', fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_photoUrl != null)
              ListTile(
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.rougeClair,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline,
                      color: AppTheme.rouge),
                ),
                title: Text(
                  langue == 'en' ? 'Remove photo' : 'Supprimer la photo',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                    color: AppTheme.rouge,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _supprimerPhoto();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null) return;
      await _uploadPhoto(picked.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.rouge,
          ),
        );
      }
    }
  }

  Future<void> _uploadPhoto(String filePath) async {
    setState(() => _uploadEnCours = true);
    try {
      final userId = _user?['id']?.toString() ?? 'unknown';
      final url = await CloudinaryService.uploadPhotoProfil(filePath, userId);

      if (url != null) {
        // Mettre à jour sur le backend
        await ApiService.mettreAJourProfil({'photo_url': url});

        // Mettre à jour en local
        final userMaj = Map<String, dynamic>.from(_user ?? {});
        userMaj['photo_url'] = url;
        await StorageService.saveUser(userMaj);

        setState(() {
          _user = userMaj;
          _photoUrl = url;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Photo mise à jour !'),
              backgroundColor: AppTheme.vert,
            ),
          );
        }
      } else {
        throw Exception('Upload échoué');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur upload: $e'),
            backgroundColor: AppTheme.rouge,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadEnCours = false);
    }
  }

  Future<void> _supprimerPhoto() async {
    final userMaj = Map<String, dynamic>.from(_user ?? {});
    userMaj['photo_url'] = null;
    await StorageService.saveUser(userMaj);
    await ApiService.mettreAJourProfil({'photo_url': null});
    setState(() {
      _user = userMaj;
      _photoUrl = null;
    });
  }

  Future<void> _deconnecter() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Déconnexion',
            style: TextStyle(
                fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
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
    final langue = ref.watch(langueProvider);
    final sw = MediaQuery.of(context).size.width;
    final isSmall = sw < 360;

    final prenom = _user?['prenom'] ?? '';
    final nom = _user?['nom'] ?? '';
    final telephone = _user?['telephone'] ?? '';
    final score = _user?['score_fiabilite'] ?? 100;

    return Scaffold(
      backgroundColor: AppTheme.fond,
      appBar: AppBar(
        backgroundColor: AppTheme.vert,
        foregroundColor: Colors.white,
        title: Text(
          langue == 'en' ? 'My profile' :
          langue == 'mos' ? 'Mam yɛl' :
          langue == 'bm' ? 'N ka kunnafoni' :
          'Mon profil',
          style: const TextStyle(
              fontFamily: 'Nunito', color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded,
                color: Colors.white70),
            onPressed: () =>
                _vocal.parler('Votre profil. $prenom $nom.'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(prenom, nom, telephone, score, isSmall),
            const SizedBox(height: 16),

            // ── MON COMPTE ────────────────────────────
            _buildSection(
              langue == 'en' ? 'MY ACCOUNT' : 'MON COMPTE',
              [
                _buildItem(Icons.person_outline,
                    langue == 'en' ? 'Full name' : 'Nom complet',
                    '$prenom $nom'),
                _buildDivider(),
                _buildItem(Icons.phone_outlined,
                    langue == 'en' ? 'Phone' : 'Téléphone',
                    telephone),
                _buildDivider(),
                _buildItem(Icons.language_outlined,
                    langue == 'en' ? 'Language' : 'Langue',
                    _getNomLangue(langue)),
                _buildDivider(),
                _buildItem(Icons.public_outlined,
                    langue == 'en' ? 'Country' : 'Pays',
                    _getNomPays()),
              ],
            ),
            const SizedBox(height: 12),

            // ── MOBILE MONEY ──────────────────────────
            _buildSection('MOBILE MONEY', [
              _buildItem(
                Icons.account_balance_wallet_outlined,
                'Orange Money',
                _user?['orange_money_numero'] ??
                    (langue == 'en' ? 'Not configured' : 'Non configuré'),
              ),
              _buildDivider(),
              _buildItem(
                Icons.account_balance_wallet_outlined,
                'Moov Money',
                _user?['moov_money_numero'] ??
                    (langue == 'en' ? 'Not configured' : 'Non configuré'),
              ),
            ]),
            const SizedBox(height: 12),

            // ── PARAMÈTRES ────────────────────────────
            _buildSection(
              langue == 'en' ? 'SETTINGS' : 'PARAMÈTRES',
              [
                _buildItemAction(
                  Icons.settings_outlined,
                  langue == 'en' ? 'Settings' : 'Réglages',
                  '',
                  () => context.push('/reglages'),
                ),
                _buildDivider(),
                _buildItemAction(
                  Icons.notifications_outlined,
                  langue == 'en' ? 'Notifications' : 'Notifications',
                  langue == 'en' ? 'Active' : 'Activées',
                  () {},
                ),
                _buildDivider(),
                _buildItemAction(
                  Icons.security_outlined,
                  langue == 'en' ? 'Change PIN' : 'Changer mon PIN',
                  '',
                  () {},
                ),
                _buildDivider(),
                _buildItemAction(
                  Icons.help_outline,
                  langue == 'en' ? 'Voice help' : 'Aide vocale',
                  '',
                  () => _vocal.parler(
                      'Pour créer une tontine, appuyez sur nouvelle tontine.'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── SCORE ─────────────────────────────────
            _buildSection(
              langue == 'en' ? 'RELIABILITY SCORE' : 'SCORE DE FIABILITÉ',
              [_buildScoreCard(score is int ? score : 100, langue)],
            ),
            const SizedBox(height: 24),

            // ── DECONNEXION ───────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: _deconnecter,
                icon: const Icon(Icons.logout, color: AppTheme.rouge),
                label: Text(
                  langue == 'en' ? 'Sign out' : 'Se déconnecter',
                  style: const TextStyle(color: AppTheme.rouge),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  side: const BorderSide(color: AppTheme.rouge),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tontine Africa v1.0.0',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  color: AppTheme.grisTexte),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String prenom, String nom, String telephone,
      dynamic score, bool isSmall) {
    return Container(
      color: AppTheme.vert,
      padding: EdgeInsets.fromLTRB(16, 16, 16, isSmall ? 24 : 32),
      child: Column(
        children: [
          // Avatar avec bouton modifier
          Stack(
            children: [
              GestureDetector(
                onTap: _changerPhoto,
                child: Container(
                  width: isSmall ? 70 : 90,
                  height: isSmall ? 70 : 90,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: _uploadEnCours
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : _photoUrl != null
                          ? ClipOval(
                              child: Image.network(
                                _photoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildInitiales(
                                prenom, nom, isSmall),
                              ),
                            )
                          : _buildInitiales(prenom, nom, isSmall),
                ),
              ),
              // Bouton appareil photo
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _changerPhoto,
                  child: Container(
                    width: 28, height: 28,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: AppTheme.vert, size: 16),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmall ? 8 : 12),
          Text(
            '$prenom $nom',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: isSmall ? 17 : 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            telephone,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: isSmall ? 12 : 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Score : $score/100',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: isSmall ? 11 : 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitiales(String prenom, String nom, bool isSmall) {
  final p = prenom.isNotEmpty ? prenom[0] : '?';
  final n = nom.isNotEmpty ? nom[0] : '';
  return Center(
    child: Text(
      '$p$n',
      style: TextStyle(
        fontFamily: 'Nunito',
        fontSize: isSmall ? 22 : 28,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
  );
}

  Widget _buildSection(String titre, List<Widget> enfants) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titre,
            style: const TextStyle(
              fontFamily: 'Nunito', fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.grisTexte,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFFE8E8E5), width: 0.5),
            ),
            child: Column(children: enfants),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() =>
      const Divider(height: 1, indent: 48, color: Color(0xFFE8E8E5));

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

  Widget _buildItemAction(IconData icon, String label, String valeur,
      VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
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
            const Icon(Icons.chevron_right,
                color: AppTheme.grisTexte, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(int score, String langue) {
    final couleur = score >= 80
        ? AppTheme.vert
        : score >= 50
            ? AppTheme.orange
            : AppTheme.rouge;
    final message = score >= 80
        ? (langue == 'en'
            ? 'Excellent! You are a very reliable member.'
            : 'Excellent ! Vous êtes un membre très fiable.')
        : score >= 50
            ? (langue == 'en'
                ? 'Good. Keep paying on time.'
                : 'Bien. Continuez à payer à temps.')
            : (langue == 'en'
                ? 'Warning. Late payments recorded.'
                : 'Attention. Des retards ont été enregistrés.');

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
              Text(
                '$score/100',
                style: TextStyle(
                  fontFamily: 'Nunito', fontSize: 16,
                  fontWeight: FontWeight.w700, color: couleur,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Nunito', fontSize: 12,
              color: AppTheme.grisTexte,
            ),
          ),
        ],
      ),
    );
  }

  String _getNomLangue(String langue) {
    const noms = {
      'fr': 'Français', 'en': 'English', 'mos': 'Mooré',
      'bm': 'Dioula', 'wo': 'Wolof', 'ar': 'العربية',
      'pt': 'Português', 'sw': 'Kiswahili',
    };
    return noms[langue] ?? langue;
  }

  String _getNomPays() {
    final pays = StorageService.getPays() ?? 'BF';
    const noms = {
      'BF': 'Burkina Faso', 'SN': 'Sénégal', 'CI': 'Côte d\'Ivoire',
      'ML': 'Mali', 'GN': 'Guinée', 'CM': 'Cameroun',
      'CD': 'RD Congo', 'TG': 'Togo', 'BJ': 'Bénin',
      'NE': 'Niger', 'GH': 'Ghana', 'NG': 'Nigeria',
    };
    return noms[pays] ?? pays;
  }

  @override
  void dispose() {
    _vocal.stop();
    super.dispose();
  }
}