import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_theme.dart';
import '../../utils/pays_data.dart';
import '../../utils/langues_data.dart';
import '../../services/storage_service.dart';
import '../../services/vocal_service.dart';
import '../../services/api_service.dart';
import '../../main.dart';

// ── TRADUCTIONS ───────────────────────────────────────
const Map<String, Map<String, String>> _tr = {
  'fr': {
    'titre': 'Réglages',
    'enregistrer': 'Enregistrer',
    'pays': '🌍 Pays et région',
    'langue': '🗣️ Langue',
    'taille_texte': '🔤 Taille du texte',
    'notifications': '🔔 Notifications',
    'mobile_money': '💳 Mobile Money',
    'compte': '👤 Compte',
    'a_propos': 'ℹ️ À propos',
    'push': 'Notifications push',
    'push_desc': 'Rappels et alertes cotisations',
    'sons': 'Sons',
    'sons_desc': 'Sons lors des actions',
    'vocal': 'Aide vocale',
    'vocal_desc': 'Lecture audio des alertes',
    'changer_pin': 'Changer le code PIN',
    'deconnecter': 'Se déconnecter',
    'supprimer': 'Supprimer mon compte',
    'version': 'Version',
    'contact': 'Nous contacter',
    'politique': 'Politique de confidentialité',
    'conditions': 'Conditions d\'utilisation',
    'disponible': 'Disponible',
    'applique': 'Réglages appliqués !',
    'pin_ancien': 'Code PIN actuel',
    'pin_nouveau': 'Nouveau code PIN',
    'pin_confirmer': 'Confirmer le nouveau PIN',
    'pin_changer': 'Changer le PIN',
    'pin_succes': 'Code PIN changé avec succès !',
    'pin_erreur': 'Code PIN incorrect',
    'pin_match': 'Les codes PIN ne correspondent pas',
    'pin_4': 'PIN doit avoir 4 chiffres',
    'annuler': 'Annuler',
    'deconnexion_titre': 'Déconnexion',
    'deconnexion_msg': 'Voulez-vous vraiment vous déconnecter ?',
    'supprimer_titre': 'Supprimer le compte',
    'supprimer_msg': 'Cette action est irréversible. Toutes vos données seront supprimées.',
    'supprimer_btn': 'Supprimer',
    'apercu': 'Aperçu du texte',
    'taille_petit': 'Petit',
    'taille_normal': 'Normal',
    'taille_grand': 'Grand',
    'taille_tgrand': 'T.Grand',
    'taille_maxi': 'Maxi',
  },
  'en': {
    'titre': 'Settings',
    'enregistrer': 'Save',
    'pays': '🌍 Country & region',
    'langue': '🗣️ Language',
    'taille_texte': '🔤 Text size',
    'notifications': '🔔 Notifications',
    'mobile_money': '💳 Mobile Money',
    'compte': '👤 Account',
    'a_propos': 'ℹ️ About',
    'push': 'Push notifications',
    'push_desc': 'Reminders and contribution alerts',
    'sons': 'Sounds',
    'sons_desc': 'Sounds during actions',
    'vocal': 'Voice help',
    'vocal_desc': 'Audio reading of alerts',
    'changer_pin': 'Change PIN code',
    'deconnecter': 'Sign out',
    'supprimer': 'Delete my account',
    'version': 'Version',
    'contact': 'Contact us',
    'politique': 'Privacy policy',
    'conditions': 'Terms of use',
    'disponible': 'Available',
    'applique': 'Settings applied!',
    'pin_ancien': 'Current PIN code',
    'pin_nouveau': 'New PIN code',
    'pin_confirmer': 'Confirm new PIN',
    'pin_changer': 'Change PIN',
    'pin_succes': 'PIN code changed successfully!',
    'pin_erreur': 'Incorrect PIN code',
    'pin_match': 'PIN codes do not match',
    'pin_4': 'PIN must have 4 digits',
    'annuler': 'Cancel',
    'deconnexion_titre': 'Sign out',
    'deconnexion_msg': 'Do you really want to sign out?',
    'supprimer_titre': 'Delete account',
    'supprimer_msg': 'This action is irreversible. All your data will be deleted.',
    'supprimer_btn': 'Delete',
    'apercu': 'Text preview',
    'taille_petit': 'Small',
    'taille_normal': 'Normal',
    'taille_grand': 'Large',
    'taille_tgrand': 'X.Large',
    'taille_maxi': 'Max',
  },
  'mos': {
    'titre': 'Rɛɛgã',
    'enregistrer': 'Sɩbg',
    'pays': '🌍 Tẽng',
    'langue': '🗣️ Bʋʋdo',
    'taille_texte': '🔤 Sɩbg-tenga',
    'notifications': '🔔 Kõ-kaasã',
    'mobile_money': '💳 Mobile Money',
    'compte': '👤 Kaont',
    'a_propos': 'ℹ️ Bõn-sɩbgr',
    'push': 'Push kõ-kaasã',
    'push_desc': 'Kõ-wakatã kõ-kaasã',
    'sons': 'Kelm-bõnã',
    'sons_desc': 'Kelm-bõnã toeegã wakate',
    'vocal': 'Vocal sõsgr',
    'vocal_desc': 'Kelg kõ-kaasã',
    'changer_pin': 'Toeeg PIN code',
    'deconnecter': 'Yiis',
    'supprimer': 'Bũgs m kaont',
    'version': 'Versiõ',
    'contact': 'Kõ-taas',
    'politique': 'Yɛla-maaneg',
    'conditions': 'Norms',
    'disponible': 'Bee',
    'applique': 'Rɛɛgã sɩnga !',
    'pin_ancien': 'PIN code wakate',
    'pin_nouveau': 'PIN code paalg',
    'pin_confirmer': 'Wilg PIN paalg',
    'pin_changer': 'Toeeg PIN',
    'pin_succes': 'PIN code toeegame sɩda !',
    'pin_erreur': 'PIN code ka sɩd',
    'pin_match': 'PIN yii ka zemse',
    'pin_4': 'PIN tõnd woto 4',
    'annuler': 'Bas',
    'deconnexion_titre': 'Yiis',
    'deconnexion_msg': 'F dat n yiis sɩda?',
    'supprimer_titre': 'Bũgs kaont',
    'supprimer_msg': 'Bũmb kãng ka tõe n lebg ye. F yɛla fãa bũgsame.',
    'supprimer_btn': 'Bũgs',
    'apercu': 'Sɩbg-tenga',
    'taille_petit': 'Bɩtɩ',
    'taille_normal': 'Noor',
    'taille_grand': 'Kãsem',
    'taille_tgrand': 'Kãsem t',
    'taille_maxi': 'Zẽnde',
  },
  'bm': {
    'titre': 'Cogoya',
    'enregistrer': 'Mara',
    'pays': '🌍 Jamana',
    'langue': '🗣️ Kan',
    'taille_texte': '🔤 Sɛbɛn bonya',
    'notifications': '🔔 Kibaru',
    'mobile_money': '💳 Mobile Money',
    'compte': '👤 Konto',
    'a_propos': 'ℹ️ Kunnafoni',
    'push': 'Push kibaru',
    'push_desc': 'Sara waati kibaru',
    'sons': 'Kumaw',
    'sons_desc': 'Kumaw kɛtaw waati',
    'vocal': 'Kuma dɛmɛ',
    'vocal_desc': 'Kibaru lamɛn',
    'changer_pin': 'PIN yɛlɛma',
    'deconnecter': 'Bɔ',
    'supprimer': 'N ka konto jɔsi',
    'version': 'Verisiyo',
    'contact': 'Bi an kunbɛn',
    'politique': 'Gundo sariya',
    'conditions': 'Sariyaw',
    'disponible': 'Be yen',
    'applique': 'Cogoya kɛra !',
    'pin_ancien': 'PIN tile min',
    'pin_nouveau': 'PIN kura',
    'pin_confirmer': 'PIN kura sɛgɛsɛgɛ',
    'pin_changer': 'PIN yɛlɛma',
    'pin_succes': 'PIN yɛlɛmana ka ɲɛ !',
    'pin_erreur': 'PIN tɛ ɲɛ',
    'pin_match': 'PIN fila tɛ kelen ye',
    'pin_4': 'PIN tonbi 4 ɲɛnabɔ',
    'annuler': 'Datan',
    'deconnexion_titre': 'Bɔ',
    'deconnexion_msg': 'I b\'a fɛ ka bɔ sɩra?',
    'supprimer_titre': 'Konto jɔsi',
    'supprimer_msg': 'Kɛta tɛ se ka kɔsɛ. I ka kunnafoni bɛɛ jɔsina.',
    'supprimer_btn': 'Jɔsi',
    'apercu': 'Sɛbɛn kunnafoni',
    'taille_petit': 'Fitinin',
    'taille_normal': 'Dɔgɔ',
    'taille_grand': 'Belebele',
    'taille_tgrand': 'Caman',
    'taille_maxi': 'Fara',
  },
  'wo': {
    'titre': 'Réglages yi',
    'enregistrer': 'Bind',
    'pays': '🌍 Dëkk',
    'langue': '🗣️ Làkk',
    'taille_texte': '🔤 Binndeef',
    'notifications': '🔔 Xibaar yi',
    'mobile_money': '💳 Mobile Money',
    'compte': '👤 Kont',
    'a_propos': 'ℹ️ Ci kaw',
    'push': 'Push xibaar',
    'push_desc': 'Xibaar cotisations yi',
    'sons': 'Dëggël yi',
    'sons_desc': 'Dëggël yi ci kɛf yi',
    'vocal': 'Kàddu dëmm',
    'vocal_desc': 'Xibaar yi ngir dee',
    'changer_pin': 'Soppi PIN bi',
    'deconnecter': 'Dem',
    'supprimer': 'Def sa kont',
    'version': 'Versiyon',
    'contact': 'Xam nu',
    'politique': 'Saritu',
    'conditions': 'Dëkkandoo',
    'disponible': 'Am na',
    'applique': 'Réglages yi defar na !',
    'pin_ancien': 'PIN bi ci kanam',
    'pin_nouveau': 'PIN bu bees',
    'pin_confirmer': 'Seytaan PIN bu bees',
    'pin_changer': 'Soppi PIN',
    'pin_succes': 'PIN bi soppi na !',
    'pin_erreur': 'PIN bi dëgërul',
    'pin_match': 'PIN yi dafañu bokk',
    'pin_4': 'PIN dafa soxor ñent xët',
    'annuler': 'Dëkk du',
    'deconnexion_titre': 'Dem',
    'deconnexion_msg': 'Dëgg nga bëgg dem?',
    'supprimer_titre': 'Jël kont bi',
    'supprimer_msg': 'Li lai dëkk du mën a dellu. Say données yi bëgg na ñëw.',
    'supprimer_btn': 'Jël',
    'apercu': 'Binndeef',
    'taille_petit': 'Toñ',
    'taille_normal': 'Normal',
    'taille_grand': 'Magu',
    'taille_tgrand': 'Mag lool',
    'taille_maxi': 'Melo melo',
  },
};

String _t(String langue, String key) {
  final lang = _tr[langue] ?? _tr['fr']!;
  return lang[key] ?? _tr['fr']![key] ?? key;
}

class ReglagesScreen extends ConsumerStatefulWidget {
  const ReglagesScreen({super.key});

  @override
  ConsumerState<ReglagesScreen> createState() => _ReglagesScreenState();
}

class _ReglagesScreenState extends ConsumerState<ReglagesScreen> {
  String _langue = 'fr';
  String _pays = 'BF';
  double _fontSize = 14.0;
  bool _vocalActif = true;
  bool _notificationsActives = true;
  bool _sonActif = true;
  bool _modeSombre = false;
  final VocalService _vocal = VocalService();

  @override
  void initState() {
    super.initState();
    final settings = StorageService.getAllSettings();
    _langue = settings['langue'] ?? 'fr';
    _pays = settings['pays'] ?? 'BF';
    _fontSize = (settings['font_size'] as num?)?.toDouble() ?? 14.0;
    _vocalActif = settings['vocal_actif'] ?? true;
    _notificationsActives = settings['notifications_actives'] ?? true;
    _sonActif = settings['son_actif'] ?? true;
    _modeSombre = settings['mode_sombre'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final langue = ref.watch(langueProvider);
    final paysInfo = PaysData.getPays(_pays);
    final sw = MediaQuery.of(context).size.width;
    final isSmall = sw < 360;

    return Scaffold(
      backgroundColor: AppTheme.fond,
      appBar: AppBar(
        backgroundColor: AppTheme.vert,
        foregroundColor: Colors.white,
        title: Text(
          _t(langue, 'titre'),
          style: const TextStyle(
              fontFamily: 'Nunito', color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => _sauvegarder(langue),
            child: Text(
              _t(langue, 'enregistrer'),
              style: const TextStyle(
                fontFamily: 'Nunito',
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isSmall ? 14 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── PAYS ──────────────────────────────────
            _buildSectionTitre(_t(langue, 'pays')),
            _buildCard([
              _buildItem(
                leading: Text(paysInfo?['drapeau'] ?? '🌍',
                    style: const TextStyle(fontSize: 24)),
                title: paysInfo?['nom'] ?? 'Burkina Faso',
                subtitle:
                    '${paysInfo?['indicatif']} • ${paysInfo?['devise']}',
                onTap: _choisirPays,
              ),
            ]),
            const SizedBox(height: 16),

            // ── LANGUE ────────────────────────────────
            _buildSectionTitre(_t(langue, 'langue')),
            _buildCard([
              _buildItem(
                leading: Text(LanguesData.getDrapeau(_langue),
                    style: const TextStyle(fontSize: 24)),
                title: LanguesData.getNom(_langue),
                subtitle: LanguesData.getNatif(_langue),
                onTap: () => _choisirLangue(langue),
              ),
            ]),
            const SizedBox(height: 16),

            // ── TAILLE TEXTE ──────────────────────────
            _buildSectionTitre(_t(langue, 'taille_texte')),
            _buildCard([
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text('A',
                            style: TextStyle(
                                fontSize: isSmall ? 11 : 12,
                                color: AppTheme.grisTexte)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.vertClair,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _t(langue, 'apercu'),
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: _fontSize,
                              color: AppTheme.vertFonce,
                            ),
                          ),
                        ),
                        Text('A',
                            style: TextStyle(
                                fontSize: isSmall ? 20 : 22,
                                color: AppTheme.grisTexte)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _fontSize,
                      min: 12,
                      max: 20,
                      divisions: 4,
                      activeColor: AppTheme.vert,
                      label: _fontSize.toStringAsFixed(0),
                      onChanged: (v) => setState(() => _fontSize = v),
                    ),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        _t(langue, 'taille_petit'),
                        _t(langue, 'taille_normal'),
                        _t(langue, 'taille_grand'),
                        _t(langue, 'taille_tgrand'),
                        _t(langue, 'taille_maxi'),
                      ]
                          .map((l) => Text(l,
                              style: const TextStyle(
                                  fontSize: 9,
                                  color: AppTheme.grisTexte)))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // ── NOTIFICATIONS ─────────────────────────
            _buildSectionTitre(_t(langue, 'notifications')),
            _buildCard([
              SwitchListTile(
                value: _notificationsActives,
                onChanged: (v) =>
                    setState(() => _notificationsActives = v),
                title: Text(_t(langue, 'push'),
                    style: const TextStyle(
                        fontFamily: 'Nunito', fontSize: 14)),
                subtitle: Text(_t(langue, 'push_desc'),
                    style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: AppTheme.grisTexte)),
                activeThumbColor: AppTheme.vert,
              ),
              const Divider(height: 1, indent: 16),
              SwitchListTile(
                value: _sonActif,
                onChanged: (v) => setState(() => _sonActif = v),
                title: Text(_t(langue, 'sons'),
                    style: const TextStyle(
                        fontFamily: 'Nunito', fontSize: 14)),
                subtitle: Text(_t(langue, 'sons_desc'),
                    style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: AppTheme.grisTexte)),
                activeThumbColor: AppTheme.vert,
              ),
              const Divider(height: 1, indent: 16),
              SwitchListTile(
                value: _vocalActif,
                onChanged: (v) {
                  setState(() => _vocalActif = v);
                  if (v) _vocal.parler(_t(langue, 'vocal'));
                },
                title: Text(_t(langue, 'vocal'),
                    style: const TextStyle(
                        fontFamily: 'Nunito', fontSize: 14)),
                subtitle: Text(_t(langue, 'vocal_desc'),
                    style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: AppTheme.grisTexte)),
                activeThumbColor: AppTheme.vert,
              ),
            ]),
            const SizedBox(height: 16),

            // ── MOBILE MONEY ──────────────────────────
            _buildSectionTitre(_t(langue, 'mobile_money')),
            _buildCard([
              ...PaysData.getMobileMoney(_pays).map((mm) {
                final code = mm.toLowerCase().replaceAll(' ', '_');
                Color couleur = AppTheme.vert;
                if (mm.toLowerCase().contains('orange')) {
                  couleur = const Color(0xFFFF6600);
                } else if (mm.toLowerCase().contains('moov'))
                  couleur = const Color(0xFF0066CC);
                else if (mm.toLowerCase().contains('mtn'))
                  couleur = const Color(0xFFFFCC00);
                else if (mm.toLowerCase().contains('wave'))
                  couleur = const Color(0xFF1DC1C8);

                return ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: couleur.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        mm.split(' ').map((w) => w[0]).take(2).join(),
                        style: TextStyle(
                          color: couleur,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  title: Text(mm,
                      style: const TextStyle(
                          fontFamily: 'Nunito', fontSize: 14)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.vertClair,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _t(langue, 'disponible'),
                      style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 10,
                          color: AppTheme.vertFonce,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                );
              }),
            ]),
            const SizedBox(height: 16),

            // ── COMPTE ────────────────────────────────
            _buildSectionTitre(_t(langue, 'compte')),
            _buildCard([
              _buildItem(
                leading: const Icon(Icons.lock_outline,
                    color: AppTheme.grisTexte),
                title: _t(langue, 'changer_pin'),
                onTap: () => _changerPin(langue),
              ),
              const Divider(height: 1, indent: 16),
              _buildItem(
                leading: const Icon(Icons.logout,
                    color: AppTheme.rouge),
                title: _t(langue, 'deconnecter'),
                titleColor: AppTheme.rouge,
                onTap: () => _seDeconnecter(langue),
              ),
              const Divider(height: 1, indent: 16),
              _buildItem(
                leading: const Icon(Icons.delete_outline,
                    color: AppTheme.rouge),
                title: _t(langue, 'supprimer'),
                titleColor: AppTheme.rouge,
                onTap: () => _supprimerCompte(langue),
              ),
            ]),
            const SizedBox(height: 16),

            // ── À PROPOS ──────────────────────────────
            _buildSectionTitre(_t(langue, 'a_propos')),
            _buildCard([
              _buildItem(
                leading: const Icon(Icons.info_outline,
                    color: AppTheme.grisTexte),
                title: _t(langue, 'version'),
                subtitle: '1.0.0 • TontiLigdi',
                onTap: null,
                showArrow: false,
              ),
              const Divider(height: 1, indent: 16),
              _buildItem(
                leading: const Icon(Icons.email_outlined,
                    color: AppTheme.grisTexte),
                title: _t(langue, 'contact'),
                subtitle: 'support@tontiligdi.toeegdigital.com',
                onTap: () async {
                  final uri = Uri.parse('mailto:support@tontiligdi.toeegdigital.com');
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
                showArrow: true,
              ),
              const Divider(height: 1, indent: 16),
              _buildItem(
                leading: const Icon(Icons.privacy_tip_outlined,
                    color: AppTheme.grisTexte),
                title: _t(langue, 'politique'),
                onTap: () async {
                  final uri = Uri.parse('https://tontiligdi.toeegdigital.com/confidentialite');
                  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
              ),
              const Divider(height: 1, indent: 16),
              _buildItem(
                leading: const Icon(Icons.description_outlined,
                    color: AppTheme.grisTexte),
                title: _t(langue, 'conditions'),
                onTap: () async {
                  final uri = Uri.parse('https://tontiligdi.toeegdigital.com/conditions');
                  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
              ),
            ]),
            const SizedBox(height: 24),

            // ── BOUTON SAUVEGARDER ────────────────────
            ElevatedButton.icon(
              onPressed: () => _sauvegarder(langue),
              icon: const Icon(Icons.save_outlined),
              label: Text(_t(langue, 'enregistrer')),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'TontiLigdi v1.0.0 • 20+ pays',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    color: AppTheme.grisTexte),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitre(String titre) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        titre,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppTheme.grisTexte,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> enfants) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: const Color(0xFFE8E8E5), width: 0.5),
      ),
      child: Column(children: enfants),
    );
  }

  Widget _buildItem({
    required Widget leading,
    required String title,
    String? subtitle,
    Color? titleColor,
    VoidCallback? onTap,
    bool showArrow = true,
  }) {
    return ListTile(
      leading: leading,
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: titleColor ?? AppTheme.texte,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  color: AppTheme.grisTexte))
          : null,
      trailing: showArrow
          ? const Icon(Icons.chevron_right,
              color: AppTheme.grisTexte)
          : null,
      onTap: onTap,
    );
  }

  // ── CHOISIR PAYS ──────────────────────────────────
  void _choisirPays() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SelecteurPaysReglages(
        paysSelectionne: _pays,
        onPaysSelectionne: (code) {
          setState(() {
            _pays = code;
            final langues = PaysData.getLanguesPays(code);
            if (!langues.contains(_langue)) {
              _langue = langues.first;
            }
          });
        },
      ),
    );
  }

  // ── CHOISIR LANGUE ────────────────────────────────
  void _choisirLangue(String langue) {
    final langues = PaysData.getLanguesPays(_pays);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.grisClair,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Text(
              _t(langue, 'langue'),
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ...langues.map((code) => ListTile(
                  leading: Text(LanguesData.getDrapeau(code),
                      style: const TextStyle(fontSize: 24)),
                  title: Text(
                    LanguesData.getNom(code),
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w600,
                      color: _langue == code
                          ? AppTheme.vert
                          : AppTheme.texte,
                    ),
                  ),
                  subtitle: Text(LanguesData.getNatif(code),
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.grisTexte)),
                  trailing: _langue == code
                      ? const Icon(Icons.check_circle,
                          color: AppTheme.vert)
                      : null,
                  onTap: () {
                    setState(() => _langue = code);
                    Navigator.pop(ctx);
                  },
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── CHANGER PIN ───────────────────────────────────
  void _changerPin(String langue) {
    final ancienCtrl = TextEditingController();
    final nouveauCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
              String? erreur;
              bool chargement = false;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: AppTheme.grisClair,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _t(langue, 'changer_pin'),
                    style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 18,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 20),
                  // PIN actuel
                  TextField(
                    controller: ancienCtrl,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: InputDecoration(
                      labelText: _t(langue, 'pin_ancien'),
                      prefixIcon:
                          const Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Nouveau PIN
                  TextField(
                    controller: nouveauCtrl,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: InputDecoration(
                      labelText: _t(langue, 'pin_nouveau'),
                      prefixIcon:
                          const Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Confirmer PIN
                  TextField(
                    controller: confirmCtrl,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: InputDecoration(
                      labelText: _t(langue, 'pin_confirmer'),
                      prefixIcon:
                          const Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: chargement
                          ? null
                          : () async {
                              if (ancienCtrl.text.length != 4) {
                                setModalState(() =>
                                    erreur = _t(langue, 'pin_4'));
                                return;
                              }
                              if (nouveauCtrl.text.length != 4) {
                                setModalState(() =>
                                    erreur = _t(langue, 'pin_4'));
                                return;
                              }
                              if (nouveauCtrl.text !=
                                  confirmCtrl.text) {
                                setModalState(() => erreur =
                                    _t(langue, 'pin_match'));
                                return;
                              }
                              setModalState(
                                  () => chargement = true);
                              try {
                                await ApiService.changerPin(
                                  ancienCtrl.text,
                                  nouveauCtrl.text,
                                );
                                if (mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          _t(langue, 'pin_succes')),
                                      backgroundColor:
                                          AppTheme.vert,
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() {
                                  erreur = _t(langue, 'pin_erreur');
                                  chargement = false;
                                });
                              }
                            },
                      child: Text(_t(langue, 'pin_changer')),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ── SAUVEGARDER ───────────────────────────────────
  Future<void> _sauvegarder(String langue) async {
    await StorageService.saveAllSettings({
      'langue': _langue,
      'pays': _pays,
      'font_size': _fontSize,
      'vocal_actif': _vocalActif,
      'notifications_actives': _notificationsActives,
      'son_actif': _sonActif,
      'mode_sombre': _modeSombre,
      'indicatif':
          PaysData.getPays(_pays)?['indicatif'] ?? '+226',
      'devise': PaysData.getPays(_pays)?['devise'] ?? 'XOF',
    });

    ref.read(langueProvider.notifier).state = _langue;
    ref.read(paysProvider.notifier).state = _pays;
    ref.read(fontSizeProvider.notifier).state = _fontSize;

    if (_vocalActif) _vocal.parler(_t(langue, 'applique'));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '✅ ${LanguesData.getNom(_langue)} • ${PaysData.getPays(_pays)?['nom']}',
                  style: const TextStyle(
                      fontFamily: 'Nunito', fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.vert,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ── DÉCONNECTER ───────────────────────────────────
  Future<void> _seDeconnecter(String langue) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t(langue, 'deconnexion_titre'),
            style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700)),
        content: Text(_t(langue, 'deconnexion_msg'),
            style: const TextStyle(fontFamily: 'Nunito')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_t(langue, 'annuler')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_t(langue, 'deconnecter'),
                style: const TextStyle(color: AppTheme.rouge)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await StorageService.clearSession();
      if (mounted) context.go('/connexion');
    }
  }

  // ── SUPPRIMER COMPTE ──────────────────────────────
  Future<void> _supprimerCompte(String langue) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t(langue, 'supprimer_titre'),
            style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
                color: AppTheme.rouge)),
        content: Text(_t(langue, 'supprimer_msg'),
            style: const TextStyle(fontFamily: 'Nunito')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_t(langue, 'annuler')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_t(langue, 'supprimer_btn'),
                style:
                    const TextStyle(color: AppTheme.rouge)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ApiService.mettreAJourProfil(
            {'statut': 'supprime'});
        await StorageService.clearAll();
        if (mounted) context.go('/langue');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(e.toString()),
                backgroundColor: AppTheme.rouge),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _vocal.stop();
    super.dispose();
  }
}

// ── SELECTEUR PAYS ────────────────────────────────────
class _SelecteurPaysReglages extends StatefulWidget {
  final String paysSelectionne;
  final Function(String) onPaysSelectionne;

  const _SelecteurPaysReglages({
    required this.paysSelectionne,
    required this.onPaysSelectionne,
  });

  @override
  State<_SelecteurPaysReglages> createState() =>
      _SelecteurPaysReglagesState();
}

class _SelecteurPaysReglagesState
    extends State<_SelecteurPaysReglages> {
  final TextEditingController _ctrl = TextEditingController();
  List<Map<String, dynamic>> _paysFiltres = [];

  @override
  void initState() {
    super.initState();
    _paysFiltres = PaysData.pays;
  }

  void _filtrer(String v) {
    setState(() {
      _paysFiltres = v.isEmpty
          ? PaysData.pays
          : PaysData.pays
              .where((p) =>
                  p['nom']
                      .toString()
                      .toLowerCase()
                      .contains(v.toLowerCase()) ||
                  p['indicatif'].toString().contains(v))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: const Color(0xFFE8E8E5),
                borderRadius: BorderRadius.circular(2)),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Choisir un pays',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                hintText: 'Rechercher...',
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
                        color: Color(0xFFE8E8E5))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppTheme.vert, width: 2)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
              onChanged: _filtrer,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${_paysFiltres.length} pays',
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  color: AppTheme.grisTexte),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _paysFiltres.length,
              itemBuilder: (ctx, i) {
                final p = _paysFiltres[i];
                final selected =
                    widget.paysSelectionne == p['code'];
                return ListTile(
                  onTap: () {
                    widget.onPaysSelectionne(p['code']);
                    Navigator.pop(ctx);
                  },
                  leading: Text(p['drapeau'],
                      style: const TextStyle(fontSize: 26)),
                  title: Text(p['nom'],
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? AppTheme.vert
                              : AppTheme.texte)),
                  subtitle: Text(
                    '${p['indicatif']} • ${p['devise']}',
                    style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: AppTheme.grisTexte),
                  ),
                  trailing: selected
                      ? const Icon(Icons.check_circle,
                          color: AppTheme.vert)
                      : null,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
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
