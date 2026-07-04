import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_theme.dart';
import '../../utils/pays_data.dart';
import '../../utils/langues_data.dart';
import '../../services/storage_service.dart';
import '../../services/vocal_service.dart';
import '../../services/api_service.dart';
import '../../main.dart';

const Map<String, Map<String, String>> _tr = {
  'fr': {
    'titre': 'Reglages',
    'enregistrer': 'Enregistrer',
    'pays': 'Pays et region',
    'langue': 'Langue',
    'taille_texte': 'Taille du texte',
    'notifications': 'Notifications',
    'mobile_money': 'Mobile Money',
    'compte': 'Compte',
    'a_propos': 'A propos',
    'push': 'Notifications push',
    'push_desc': 'Rappels et alertes cotisations',
    'sons': 'Sons',
    'sons_desc': 'Sons lors des actions',
    'vocal': 'Aide vocale',
    'vocal_desc': 'Lecture audio des alertes',
    'changer_pin': 'Changer le code PIN',
    'deconnecter': 'Se deconnecter',
    'supprimer': 'Supprimer mon compte',
    'version': 'Version',
    'contact': 'Nous contacter',
    'politique': 'Politique de confidentialite',
    'conditions': 'Conditions d utilisation',
    'disponible': 'Disponible',
    'applique': 'Reglages appliques !',
    'pin_ancien': 'Code PIN actuel',
    'pin_nouveau': 'Nouveau code PIN',
    'pin_confirmer': 'Confirmer le nouveau PIN',
    'pin_changer': 'Changer le PIN',
    'pin_succes': 'Code PIN change avec succes !',
    'pin_erreur': 'Code PIN actuel incorrect',
    'pin_match': 'Les codes PIN ne correspondent pas',
    'pin_4': 'PIN doit avoir 4 chiffres',
    'annuler': 'Annuler',
    'deconnexion_titre': 'Deconnexion',
    'deconnexion_msg': 'Voulez-vous vraiment vous deconnecter ?',
    'supprimer_titre': 'Supprimer le compte',
    'supprimer_msg': 'Cette action est irreversible. Toutes vos donnees seront supprimees.',
    'supprimer_btn': 'Supprimer',
    'apercu': 'Apercu du texte',
    'taille_petit': 'Petit',
    'taille_normal': 'Normal',
    'taille_grand': 'Grand',
    'taille_tgrand': 'T.Grand',
    'taille_maxi': 'Maxi',
    'indicatif': 'Indicatif telephonique',
    'devise': 'Devise',
    'theme': 'Theme',
    'theme_clair': 'Clair',
    'theme_sombre': 'Sombre',
  },
  'en': {
    'titre': 'Settings',
    'enregistrer': 'Save',
    'pays': 'Country and region',
    'langue': 'Language',
    'taille_texte': 'Text size',
    'notifications': 'Notifications',
    'mobile_money': 'Mobile Money',
    'compte': 'Account',
    'a_propos': 'About',
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
    'applique': 'Settings saved!',
    'pin_ancien': 'Current PIN code',
    'pin_nouveau': 'New PIN code',
    'pin_confirmer': 'Confirm new PIN',
    'pin_changer': 'Change PIN',
    'pin_succes': 'PIN code changed successfully!',
    'pin_erreur': 'Current PIN code incorrect',
    'pin_match': 'PIN codes do not match',
    'pin_4': 'PIN must have 4 digits',
    'annuler': 'Cancel',
    'deconnexion_titre': 'Sign out',
    'deconnexion_msg': 'Are you sure you want to sign out?',
    'supprimer_titre': 'Delete account',
    'supprimer_msg': 'This action is irreversible. All your data will be deleted.',
    'supprimer_btn': 'Delete',
    'apercu': 'Text preview',
    'taille_petit': 'Small',
    'taille_normal': 'Normal',
    'taille_grand': 'Large',
    'taille_tgrand': 'X.Large',
    'taille_maxi': 'Max',
    'indicatif': 'Phone prefix',
    'devise': 'Currency',
    'theme': 'Theme',
    'theme_clair': 'Light',
    'theme_sombre': 'Dark',
  },
  'mos': {
    'titre': 'Reglages',
    'enregistrer': 'Sɩng',
    'pays': 'Tẽnga',
    'langue': 'Bʋʋdo',
    'taille_texte': 'Tɩ-gʋlsg',
    'notifications': 'Ko-kaasã',
    'mobile_money': 'Mobile Money',
    'compte': 'Kaont',
    'a_propos': 'Wilgr',
    'push': 'Ko-kaasã push',
    'push_desc': 'Kõ-kaas ne tɩɩs',
    'sons': 'Koees',
    'sons_desc': 'Koees tʋʋmde',
    'vocal': 'Gomd-sõng',
    'vocal_desc': 'Kõ-kaas gomd zugu',
    'changer_pin': 'Toeeg PIN',
    'deconnecter': 'Yiis',
    'supprimer': 'Kʋʋs m kaont',
    'version': 'Nʋʋr',
    'contact': 'Togs-d rãmb',
    'politique': 'Zɩɩlgr noy',
    'conditions': 'Noy-rɛɛzã',
    'disponible': 'Bee',
    'applique': 'Reglages sɩda !',
    'pin_ancien': 'PIN koe',
    'pin_nouveau': 'PIN paalga',
    'pin_confirmer': 'Sɩng PIN paalga',
    'pin_changer': 'Toeeg PIN',
    'pin_succes': 'PIN toeegsame !',
    'pin_erreur': 'PIN ka sɩda',
    'pin_match': 'PIN rãmba ka zems',
    'pin_4': 'PIN fãa nʋʋr a naas',
    'annuler': 'Bas',
    'deconnexion_titre': 'Yiis',
    'deconnexion_msg': 'Yaa f sõng n dat n yiis?',
    'supprimer_titre': 'Kʋʋs kaont',
    'supprimer_msg': 'Tʋʋmdã ka tõe n lebg. F yɛla fãa na kʋʋse.',
    'supprimer_btn': 'Kʋʋs',
    'apercu': 'Tɩ-gʋlsg wilgr',
    'taille_petit': 'Bilf',
    'taille_normal': 'Sɩd-sɩda',
    'taille_grand': 'Kãseng',
    'taille_tgrand': 'Kãseng wʋsg',
    'taille_maxi': 'Kãseng n wʋsg',
    'indicatif': 'Tɩ-telef nʋʋr',
    'devise': 'Ligdi nʋʋr',
    'theme': 'Toeeng',
    'theme_clair': 'Vẽenga',
    'theme_sombre': 'Zĩigã',
  },
};

String _t(String langue, String key) =>
    (_tr[langue] ?? _tr['fr']!)[key] ?? (_tr['fr']![key] ?? key);

class ReglagesScreen extends ConsumerStatefulWidget {
  const ReglagesScreen({super.key});

  @override
  ConsumerState<ReglagesScreen> createState() => _ReglagesScreenState();
}

class _ReglagesScreenState extends ConsumerState<ReglagesScreen> {
  late String _langue;
  late String _pays;
  late double _fontSize;
  late bool _notifActives;
  late bool _sonActif;
  late bool _vocalActif;
  late bool _modeSombre;
  late String _indicatif;
  late String _devise;
  bool _chargement = false;

  @override
  void initState() {
    super.initState();
    _langue = StorageService.getLangue() ?? 'fr';
    _pays = StorageService.getPays() ?? 'BF';
    _fontSize = StorageService.getFontSize() ?? 14.0;
    _notifActives = StorageService.getNotificationsActives();
    _sonActif = StorageService.getSonActif();
    _vocalActif = StorageService.getVocalActif();
    _modeSombre = StorageService.getModeSombre();
    _indicatif = StorageService.getIndicatif();
    _devise = StorageService.getDevise();
  }

  Future<void> _sauvegarder(String langue) async {
    setState(() => _chargement = true);
    await StorageService.saveLangue(_langue);
    await StorageService.savePays(_pays);
    await StorageService.saveFontSize(_fontSize);
    await StorageService.saveNotificationsActives(_notifActives);
    await StorageService.saveSonActif(_sonActif);
    await StorageService.saveVocalActif(_vocalActif);
    await StorageService.saveModeSombre(_modeSombre);
    await StorageService.saveIndicatif(_indicatif);
    await StorageService.saveDevise(_devise);
    ref.read(langueProvider.notifier).state = _langue;
    setState(() => _chargement = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_t(langue, 'applique')),
        backgroundColor: AppTheme.vert,
      ));
    }
  }

  void _changerPin(String langue) {
    final ancienCtrl = TextEditingController();
    final nouveauCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool _obscureAncien = true;
    bool _obscureNouveau = true;
    bool _obscureConfirm = true;

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
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                          color: AppTheme.grisClair,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(_t(langue, 'changer_pin'),
                      style: const TextStyle(fontFamily: 'Nunito',
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  // PIN actuel
                  StatefulBuilder(builder: (ctx2, ss) => TextField(
                    controller: ancienCtrl,
                    obscureText: _obscureAncien,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: _t(langue, 'pin_ancien'),
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureAncien ? Icons.visibility_off : Icons.visibility),
                        onPressed: () { ss(() => _obscureAncien = !_obscureAncien); },
                      ),
                    ),
                  )),
                  const SizedBox(height: 12),
                  // Nouveau PIN
                  StatefulBuilder(builder: (ctx2, ss) => TextField(
                    controller: nouveauCtrl,
                    obscureText: _obscureNouveau,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: _t(langue, 'pin_nouveau'),
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNouveau ? Icons.visibility_off : Icons.visibility),
                        onPressed: () { ss(() => _obscureNouveau = !_obscureNouveau); },
                      ),
                    ),
                  )),
                  const SizedBox(height: 12),
                  // Confirmer PIN
                  StatefulBuilder(builder: (ctx2, ss) => TextField(
                    controller: confirmCtrl,
                    obscureText: _obscureConfirm,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: _t(langue, 'pin_confirmer'),
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                        onPressed: () { ss(() => _obscureConfirm = !_obscureConfirm); },
                      ),
                    ),
                  )),
                  if (erreur != null) ...[
                    const SizedBox(height: 8),
                    Text(erreur!, style: const TextStyle(color: AppTheme.rouge, fontSize: 13)),
                  ],
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(_t(langue, 'annuler')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatefulBuilder(builder: (ctx2, ss) => ElevatedButton(
                        onPressed: chargement ? null : () async {
                          // Validation
                          if (ancienCtrl.text.length != 4) {
                            setModalState(() => erreur = _t(langue, 'pin_4'));
                            return;
                          }
                          if (nouveauCtrl.text.length != 4) {
                            setModalState(() => erreur = _t(langue, 'pin_4'));
                            return;
                          }
                          if (nouveauCtrl.text != confirmCtrl.text) {
                            setModalState(() => erreur = _t(langue, 'pin_match'));
                            return;
                          }
                          setModalState(() { erreur = null; chargement = true; });
                          try {
                            await ApiService.changerPin(
                              ancienCtrl.text,
                              nouveauCtrl.text,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(_t(langue, 'pin_succes')),
                                backgroundColor: AppTheme.vert,
                              ));
                            }
                          } catch (e) {
                            print('PIN ERROR: ' + e.toString());
                            setModalState(() {
                              erreur = e.toString();
                              chargement = false;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.vert),
                        child: chargement
                            ? const SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(_t(langue, 'pin_changer'),
                                style: const TextStyle(color: Colors.white)),
                      )),
                    ),
                  ]),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _seDeconnecter(String langue) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_t(langue, 'deconnexion_titre'),
            style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
        content: Text(_t(langue, 'deconnexion_msg'),
            style: const TextStyle(fontFamily: 'Nunito')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text(_t(langue, 'annuler'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.rouge),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_t(langue, 'deconnecter'),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await StorageService.clearSession();
      if (mounted) context.go('/connexion');
    }
  }

  Future<void> _supprimerCompte(String langue) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_t(langue, 'supprimer_titre'),
            style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700,
                color: AppTheme.rouge)),
        content: Text(_t(langue, 'supprimer_msg'),
            style: const TextStyle(fontFamily: 'Nunito')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text(_t(langue, 'annuler'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.rouge),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_t(langue, 'supprimer_btn'),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ApiService.supprimerCompte();
        await StorageService.clearAll();
        if (mounted) context.go('/connexion');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.rouge,
          ));
        }
      }
    }
  }

  Future<void> _ouvrirUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _choisirLangue(String langue) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.grisClair,
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(_t(langue, 'langue'), style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...LanguesData.getToutesLesLangues().map((l) => ListTile(
              leading: Text(l['drapeau'] ?? '', style: const TextStyle(fontSize: 24)),
              title: Text(l['nom'] ?? '', style: const TextStyle(fontFamily: 'Nunito')),
              subtitle: Text(l['nom_local'] ?? '', style: const TextStyle(
                  fontFamily: 'Nunito', fontSize: 12, color: AppTheme.grisTexte)),
              trailing: _langue == l['code']
                  ? const Icon(Icons.check_circle, color: AppTheme.vert) : null,
              onTap: () {
                setState(() => _langue = l['code'] ?? 'fr');
                Navigator.pop(ctx);
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langue = ref.watch(langueProvider);
    final sw = MediaQuery.of(context).size.width;
    final isSmall = sw < 360;
    final langueActuelle = LanguesData.getToutesLesLangues()
        .firstWhere((l) => l['code'] == _langue, orElse: () => {'nom': _langue});
    final paysActuel = PaysData.pays
        .firstWhere((p) => p['code'] == _pays, orElse: () => {'nom': _pays, 'drapeau': ''});

    return Scaffold(
      backgroundColor: AppTheme.fond,
      appBar: AppBar(
        backgroundColor: AppTheme.vert,
        foregroundColor: Colors.white,
        title: Text(_t(langue, 'titre'),
            style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
        actions: [
          if (_chargement)
            const Padding(padding: EdgeInsets.all(16),
                child: SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
          else
            TextButton(
              onPressed: () => _sauvegarder(langue),
              child: Text(_t(langue, 'enregistrer'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        children: [

          // ── PAYS & LANGUE ─────────────────────────────
          _buildSection(
            icon: Icons.language,
            title: _t(langue, 'pays'),
            children: [
              _buildItem(
                leading: Text(paysActuel['drapeau'] ?? '',
                    style: const TextStyle(fontSize: 24)),
                title: paysActuel['nom'] ?? _pays,
                subtitle: _pays,
                onTap: () => _choisirPays(langue),
              ),
              const Divider(height: 1, indent: 16),
              _buildItem(
                leading: Text(
                  LanguesData.getToutesLesLangues()
                      .firstWhere((l) => l['code'] == _langue,
                          orElse: () => {'drapeau': 'fr'})['drapeau'] ?? '',
                  style: const TextStyle(fontSize: 24)),
                title: langueActuelle['nom'] ?? _langue,
                subtitle: _t(langue, 'langue'),
                onTap: () => _choisirLangue(langue),
              ),
              const Divider(height: 1, indent: 16),
              _buildItem(
                leading: const Icon(Icons.phone, color: AppTheme.grisTexte),
                title: _indicatif,
                subtitle: _t(langue, 'indicatif'),
                onTap: () => _choisirIndicatif(langue),
              ),
              const Divider(height: 1, indent: 16),
              _buildItem(
                leading: const Icon(Icons.monetization_on_outlined,
                    color: AppTheme.grisTexte),
                title: _devise,
                subtitle: _t(langue, 'devise'),
                onTap: () => _choisirDevise(langue),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── TAILLE TEXTE ──────────────────────────────
          _buildSection(
            icon: Icons.text_fields,
            title: _t(langue, 'taille_texte'),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_t(langue, 'apercu'),
                        style: TextStyle(fontFamily: 'Nunito',
                            fontSize: _fontSize, color: AppTheme.texte)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.text_fields, size: 14, color: AppTheme.grisTexte),
                        Expanded(
                          child: Slider(
                            value: _fontSize,
                            min: 12, max: 22, divisions: 4,
                            activeColor: AppTheme.vert,
                            onChanged: (v) => setState(() => _fontSize = v),
                          ),
                        ),
                        const Icon(Icons.text_fields, size: 22, color: AppTheme.grisTexte),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _taillePill(_t(langue, 'taille_petit'), 12),
                        _taillePill(_t(langue, 'taille_normal'), 14),
                        _taillePill(_t(langue, 'taille_grand'), 16),
                        _taillePill(_t(langue, 'taille_tgrand'), 18),
                        _taillePill(_t(langue, 'taille_maxi'), 22),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── NOTIFICATIONS ─────────────────────────────
          _buildSection(
            icon: Icons.notifications_outlined,
            title: _t(langue, 'notifications'),
            children: [
              _buildSwitchItem(
                icon: Icons.notifications_active_outlined,
                title: _t(langue, 'push'),
                subtitle: _t(langue, 'push_desc'),
                value: _notifActives,
                onChanged: (v) => setState(() => _notifActives = v),
              ),
              const Divider(height: 1, indent: 16),
              _buildSwitchItem(
                icon: Icons.volume_up_outlined,
                title: _t(langue, 'sons'),
                subtitle: _t(langue, 'sons_desc'),
                value: _sonActif,
                onChanged: (v) => setState(() => _sonActif = v),
              ),
              const Divider(height: 1, indent: 16),
              _buildSwitchItem(
                icon: Icons.record_voice_over_outlined,
                title: _t(langue, 'vocal'),
                subtitle: _t(langue, 'vocal_desc'),
                value: _vocalActif,
                onChanged: (v) => setState(() => _vocalActif = v),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── THEME ─────────────────────────────────────
          _buildSection(
            icon: Icons.palette_outlined,
            title: _t(langue, 'theme'),
            children: [
              _buildSwitchItem(
                icon: Icons.dark_mode_outlined,
                title: _t(langue, 'theme_sombre'),
                subtitle: '',
                value: _modeSombre,
                onChanged: (v) => setState(() => _modeSombre = v),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── COMPTE ────────────────────────────────────
          _buildSection(
            icon: Icons.person_outline,
            title: _t(langue, 'compte'),
            children: [
              _buildItem(
                leading: const Icon(Icons.lock_outline, color: AppTheme.vert),
                title: _t(langue, 'changer_pin'),
                onTap: () => _changerPin(langue),
              ),
              const Divider(height: 1, indent: 16),
              _buildItem(
                leading: const Icon(Icons.logout, color: AppTheme.rouge),
                title: _t(langue, 'deconnecter'),
                titleColor: AppTheme.rouge,
                onTap: () => _seDeconnecter(langue),
              ),
              const Divider(height: 1, indent: 16),
              _buildItem(
                leading: const Icon(Icons.delete_outline, color: AppTheme.rouge),
                title: _t(langue, 'supprimer'),
                titleColor: AppTheme.rouge,
                onTap: () => _supprimerCompte(langue),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── A PROPOS ──────────────────────────────────
          _buildSection(
            icon: Icons.info_outline,
            title: _t(langue, 'a_propos'),
            children: [
              _buildItem(
                leading: const Icon(Icons.mail_outline, color: AppTheme.grisTexte),
                title: _t(langue, 'contact'),
                subtitle: 'support@tontiligdi.com',
                onTap: () => _ouvrirUrl('mailto:support@tontiligdi.com'),
              ),
              const Divider(height: 1, indent: 16),
              _buildItem(
                leading: const Icon(Icons.privacy_tip_outlined, color: AppTheme.grisTexte),
                title: _t(langue, 'politique'),
                onTap: () => _ouvrirUrl('https://tontiligdi.toeegdigital.com/confidentialite'),
              ),
              const Divider(height: 1, indent: 16),
              _buildItem(
                leading: const Icon(Icons.description_outlined, color: AppTheme.grisTexte),
                title: _t(langue, 'conditions'),
                onTap: () => _ouvrirUrl('https://tontiligdi.toeegdigital.com/conditions'),
              ),
              const Divider(height: 1, indent: 16),
              _buildItem(
                leading: const Icon(Icons.info_outline, color: AppTheme.grisTexte),
                title: _t(langue, 'version'),
                subtitle: '1.0.0 • TontiLigdi by Toeeg Digital SARL',
                showArrow: false,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ── LOGO BAS DE PAGE ──────────────────────────
          Center(
            child: Column(children: [
              Text('TontiLigdi',
                  style: TextStyle(fontFamily: 'Nunito',
                      fontSize: isSmall ? 16 : 18, fontWeight: FontWeight.w700,
                      color: AppTheme.vert)),
              const SizedBox(height: 4),
              Text('Lagem Ligdi • Rassemblons l argent',
                  style: TextStyle(fontFamily: 'Nunito',
                      fontSize: isSmall ? 11 : 12, color: AppTheme.grisTexte)),
              const SizedBox(height: 4),
              Text('by Toeeg Digital SARL • Ouagadougou, Burkina Faso',
                  style: TextStyle(fontFamily: 'Nunito',
                      fontSize: isSmall ? 10 : 11, color: AppTheme.grisTexte)),
            ]),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── WIDGETS ───────────────────────────────────────────

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(children: [
            Icon(icon, size: 16, color: AppTheme.vert),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 13,
                fontWeight: FontWeight.w700, color: AppTheme.vert)),
          ]),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8E8E5), width: 0.5),
          ),
          child: Column(children: children),
        ),
      ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(
                    fontFamily: 'Nunito', fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: titleColor ?? AppTheme.texte)),
                if (subtitle != null)
                  Text(subtitle, style: const TextStyle(
                      fontFamily: 'Nunito', fontSize: 12,
                      color: AppTheme.grisTexte)),
              ],
            ),
          ),
          if (showArrow && onTap != null)
            const Icon(Icons.chevron_right, color: AppTheme.grisTexte, size: 20),
        ]),
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        Icon(icon, color: AppTheme.grisTexte, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(
                  fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w600)),
              if (subtitle.isNotEmpty)
                Text(subtitle, style: const TextStyle(
                    fontFamily: 'Nunito', fontSize: 12, color: AppTheme.grisTexte)),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged, activeColor: AppTheme.vert),
      ]),
    );
  }

  Widget _taillePill(String label, double size) {
    final selected = _fontSize == size;
    return GestureDetector(
      onTap: () => setState(() => _fontSize = size),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppTheme.vert : AppTheme.grisClair,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(
            fontFamily: 'Nunito', fontSize: 10,
            color: selected ? Colors.white : AppTheme.grisTexte,
            fontWeight: selected ? FontWeight.w700 : FontWeight.normal)),
      ),
    );
  }

  void _choisirPays(String langue) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (ctx, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            const SizedBox(height: 12),
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.grisClair,
                    borderRadius: BorderRadius.circular(2)))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  hintText: 'Rechercher un pays...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (v) => setState(() {}),
              ),
            ),
            Expanded(
              child: StatefulBuilder(builder: (ctx2, ss) {
                final pays = PaysData.pays.where((p) =>
                    p['nom'].toString().toLowerCase().contains(ctrl.text.toLowerCase()) ||
                    p['code'].toString().toLowerCase().contains(ctrl.text.toLowerCase())
                ).toList();
                return ListView.builder(
                  controller: scrollCtrl,
                  itemCount: pays.length,
                  itemBuilder: (ctx3, i) {
                    final p = pays[i];
                    return ListTile(
                      leading: Text(p['drapeau'] ?? '',
                          style: const TextStyle(fontSize: 24)),
                      title: Text(p['nom'] ?? '',
                          style: const TextStyle(fontFamily: 'Nunito')),
                      subtitle: Text(p['code'] ?? '',
                          style: const TextStyle(fontFamily: 'Nunito',
                              fontSize: 12, color: AppTheme.grisTexte)),
                      trailing: _pays == p['code']
                          ? const Icon(Icons.check_circle, color: AppTheme.vert) : null,
                      onTap: () {
                        setState(() {
                          _pays = p['code'] ?? 'BF';
                          _indicatif = p['indicatif'] ?? '+226';
                          _devise = p['devise'] ?? 'XOF';
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                );
              }),
            ),
          ]),
        ),
      ),
    );
  }

  void _choisirIndicatif(String langue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (ctx, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            const SizedBox(height: 12),
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.grisClair,
                    borderRadius: BorderRadius.circular(2)))),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Indicatif telephonique',
                  style: TextStyle(fontFamily: 'Nunito',
                      fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            Expanded(
              child: ListView(controller: scrollCtrl,
                children: PaysData.pays.map((p) => ListTile(
                  leading: Text(p['drapeau'] ?? '',
                      style: const TextStyle(fontSize: 20)),
                  title: Text('${p['indicatif']} — ${p['nom']}',
                      style: const TextStyle(fontFamily: 'Nunito', fontSize: 13)),
                  trailing: _indicatif == p['indicatif']
                      ? const Icon(Icons.check_circle, color: AppTheme.vert) : null,
                  onTap: () {
                    setState(() => _indicatif = p['indicatif'] ?? '+226');
                    Navigator.pop(ctx);
                  },
                )).toList(),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _choisirDevise(String langue) {
    final devises = [
      {'code': 'XOF', 'nom': 'Franc CFA UEMOA', 'symbole': 'F CFA'},
      {'code': 'XAF', 'nom': 'Franc CFA CEMAC', 'symbole': 'F CFA'},
      {'code': 'GHS', 'nom': 'Cedi ghaneen', 'symbole': 'GH₵'},
      {'code': 'NGN', 'nom': 'Naira nigerien', 'symbole': '₦'},
      {'code': 'EUR', 'nom': 'Euro', 'symbole': '€'},
      {'code': 'USD', 'nom': 'Dollar americain', 'symbole': '\$'},
      {'code': 'GNF', 'nom': 'Franc guineen', 'symbole': 'FG'},
      {'code': 'MRU', 'nom': 'Ouguiya mauritanien', 'symbole': 'UM'},
    ];
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.grisClair,
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(_t(langue, 'devise'), style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...devises.map((d) => ListTile(
              leading: Text(d['symbole'] ?? '',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              title: Text(d['nom'] ?? '',
                  style: const TextStyle(fontFamily: 'Nunito')),
              subtitle: Text(d['code'] ?? '',
                  style: const TextStyle(fontFamily: 'Nunito', fontSize: 12)),
              trailing: _devise == d['code']
                  ? const Icon(Icons.check_circle, color: AppTheme.vert) : null,
              onTap: () {
                setState(() => _devise = d['code'] ?? 'XOF');
                Navigator.pop(ctx);
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
