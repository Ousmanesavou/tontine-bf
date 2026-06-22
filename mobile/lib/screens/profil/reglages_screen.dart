import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_theme.dart';
import '../../utils/pays_data.dart';
import '../../utils/langues_data.dart';
import '../../services/storage_service.dart';
import '../../services/vocal_service.dart';
import '../../main.dart';

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
    _fontSize = settings['font_size'] ?? 14.0;
    _vocalActif = settings['vocal_actif'] ?? true;
    _notificationsActives = settings['notifications_actives'] ?? true;
    _sonActif = settings['son_actif'] ?? true;
    _modeSombre = settings['mode_sombre'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final paysInfo = PaysData.getPays(_pays);

    return Scaffold(
      backgroundColor: AppTheme.fond,
      appBar: AppBar(
        backgroundColor: AppTheme.vert,
        foregroundColor: Colors.white,
        title: const Text(
          'Réglages',
          style: TextStyle(fontFamily: 'Nunito', color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: _sauvegarder,
            child: const Text(
              'Enregistrer',
              style: TextStyle(
                fontFamily: 'Nunito',
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── PAYS ──────────────────────────────────────
            _buildSectionTitre('🌍 Pays et région'),
            _buildCard([
              _buildItem(
                leading: Text(paysInfo?['drapeau'] ?? '🌍',
                    style: const TextStyle(fontSize: 24)),
                title: paysInfo?['nom'] ?? 'Burkina Faso',
                subtitle: '${paysInfo?['indicatif']} • ${paysInfo?['devise']}',
                onTap: _choisirPays,
              ),
            ]),
            const SizedBox(height: 16),

            // ── LANGUE ────────────────────────────────────
            _buildSectionTitre('🗣️ Langue de l\'application'),
            _buildCard([
              _buildItem(
                leading: Text(LanguesData.getDrapeau(_langue),
                    style: const TextStyle(fontSize: 24)),
                title: LanguesData.getNom(_langue),
                subtitle: LanguesData.getNatif(_langue),
                onTap: _choisirLangue,
              ),
            ]),
            const SizedBox(height: 16),

            // ── TAILLE TEXTE ──────────────────────────────
            _buildSectionTitre('🔤 Taille du texte'),
            _buildCard([
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('A',
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.grisTexte)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.vertClair,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Aperçu du texte',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: _fontSize,
                              color: AppTheme.vertFonce,
                            ),
                          ),
                        ),
                        const Text('A',
                            style: TextStyle(
                                fontSize: 22, color: AppTheme.grisTexte)),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['Petit', 'Normal', 'Grand', 'T.Grand', 'Maxi']
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

            // ── NOTIFICATIONS ─────────────────────────────
            _buildSectionTitre('🔔 Notifications'),
            _buildCard([
              SwitchListTile(
                value: _notificationsActives,
                onChanged: (v) =>
                    setState(() => _notificationsActives = v),
                title: const Text('Notifications push',
                    style: TextStyle(
                        fontFamily: 'Nunito', fontSize: 14)),
                subtitle: const Text('Rappels et alertes cotisations',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: AppTheme.grisTexte)),
                activeColor: AppTheme.vert,
              ),
              const Divider(height: 1, indent: 16),
              SwitchListTile(
                value: _sonActif,
                onChanged: (v) => setState(() => _sonActif = v),
                title: const Text('Sons',
                    style: TextStyle(
                        fontFamily: 'Nunito', fontSize: 14)),
                subtitle: const Text('Sons lors des actions',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: AppTheme.grisTexte)),
                activeColor: AppTheme.vert,
              ),
              const Divider(height: 1, indent: 16),
              SwitchListTile(
                value: _vocalActif,
                onChanged: (v) {
                  setState(() => _vocalActif = v);
                  if (v) _vocal.parler('Aide vocale activée');
                },
                title: const Text('Aide vocale',
                    style: TextStyle(
                        fontFamily: 'Nunito', fontSize: 14)),
                subtitle: const Text('Lecture audio des alertes',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: AppTheme.grisTexte)),
                activeColor: AppTheme.vert,
              ),
            ]),
            const SizedBox(height: 16),

            // ── MOBILE MONEY ──────────────────────────────
            _buildSectionTitre('💳 Mobile Money disponible'),
            _buildCard([
              ...PaysData.getMobileMoney(_pays).map((mm) => ListTile(
                    leading: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: AppTheme.vert),
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
                      child: const Text('Disponible',
                          style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 10,
                              color: AppTheme.vertFonce,
                              fontWeight: FontWeight.w600)),
                    ),
                  )),
            ]),
            const SizedBox(height: 16),

            // ── COMPTE ────────────────────────────────────
            _buildSectionTitre('👤 Compte'),
            _buildCard([
              _buildItem(
                leading: const Icon(Icons.lock_outline,
                    color: AppTheme.grisTexte),
                title: 'Changer le code PIN',
                onTap: () {},
              ),
              const Divider(height: 1, indent: 16),
              _buildItem(
                leading: const Icon(Icons.logout,
                    color: AppTheme.rouge),
                title: 'Se déconnecter',
                titleColor: AppTheme.rouge,
                onTap: _seDeconnecter,
              ),
            ]),
            const SizedBox(height: 24),

            // ── BOUTON SAUVEGARDER ────────────────────────
            ElevatedButton.icon(
              onPressed: _sauvegarder,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Appliquer les réglages'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Version 1.0.0 • Tontine Africa',
                style: const TextStyle(
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
        border: Border.all(color: const Color(0xFFE8E8E5), width: 0.5),
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
      trailing: const Icon(Icons.chevron_right, color: AppTheme.grisTexte),
      onTap: onTap,
    );
  }

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
            if (!langues.contains(_langue)) _langue = langues.first;
          });
        },
      ),
    );
  }

  void _choisirLangue() {
    final langues = PaysData.getLanguesPays(_pays);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Choisir une langue',
              style: TextStyle(
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
                  subtitle: Text(
                    LanguesData.getNatif(code),
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.grisTexte),
                  ),
                  trailing: _langue == code
                      ? const Icon(Icons.check_circle, color: AppTheme.vert)
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

  Future<void> _sauvegarder() async {
    // Sauvegarder dans SharedPreferences
    await StorageService.saveAllSettings({
      'langue': _langue,
      'pays': _pays,
      'font_size': _fontSize,
      'vocal_actif': _vocalActif,
      'notifications_actives': _notificationsActives,
      'son_actif': _sonActif,
      'mode_sombre': _modeSombre,
      'indicatif': PaysData.getPays(_pays)?['indicatif'] ?? '+226',
      'devise': PaysData.getPays(_pays)?['devise'] ?? 'XOF',
    });

    // ✅ Synchroniser avec les providers — change toute l'app instantanément
    ref.read(langueProvider.notifier).state = _langue;
    ref.read(paysProvider.notifier).state = _pays;
    ref.read(fontSizeProvider.notifier).state = _fontSize;

    if (_vocalActif) {
      _vocal.parler('Réglages appliqués avec succès');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                '✅ Langue : ${LanguesData.getNom(_langue)} • Pays : ${PaysData.getPays(_pays)?['nom']}',
                style: const TextStyle(fontFamily: 'Nunito', fontSize: 13),
              ),
            ],
          ),
          backgroundColor: AppTheme.vert,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _seDeconnecter() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion',
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
        content: const Text('Voulez-vous vraiment vous déconnecter ?',
            style: TextStyle(fontFamily: 'Nunito')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Déconnecter',
                style: TextStyle(color: AppTheme.rouge)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.clearSession();
      if (mounted) context.go('/connexion');
    }
  }

  @override
  void dispose() {
    _vocal.stop();
    super.dispose();
  }
}

// ── SELECTEUR PAYS RÉGLAGES ───────────────────────────
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

class _SelecteurPaysReglagesState extends State<_SelecteurPaysReglages> {
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
                  p['nom'].toString().toLowerCase().contains(v.toLowerCase()) ||
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _ctrl,
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
                    borderSide:
                        const BorderSide(color: Color(0xFFE8E8E5))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.vert, width: 2)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
              onChanged: _filtrer,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${_paysFiltres.length} pays disponibles',
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  color: AppTheme.grisTexte),
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
                      ? const Icon(Icons.check_circle, color: AppTheme.vert)
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