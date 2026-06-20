import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_theme.dart';
import '../../utils/pays_data.dart';
import '../../utils/langues_data.dart';
import '../../services/storage_service.dart';
import '../../services/vocal_service.dart';

class ReglagesScreen extends StatefulWidget {
  const ReglagesScreen({super.key});

  @override
  State<ReglagesScreen> createState() => _ReglagesScreenState();
}

class _ReglagesScreenState extends State<ReglagesScreen> {
  String _langue = 'fr';
  String _pays = 'BF';
  double _fontSize = 14.0;
  bool _vocalActif = true;
  final VocalService _vocal = VocalService();

  @override
  void initState() {
    super.initState();
    _langue = StorageService.getLangue() ?? 'fr';
    _pays = StorageService.getPays() ?? 'BF';
  }

  @override
  Widget build(BuildContext context) {
    final paysInfo = PaysData.getPays(_pays);

    return Scaffold(
      backgroundColor: AppTheme.fond,
      appBar: AppBar(
        backgroundColor: AppTheme.vert,
        foregroundColor: Colors.white,
        title: const Text('Réglages',
            style: TextStyle(fontFamily: 'Nunito', color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('🌍 Pays et région', [
              _buildItem(
                leading: Text(paysInfo?['drapeau'] ?? '🌍',
                    style: const TextStyle(fontSize: 24)),
                title: paysInfo?['nom'] ?? 'Burkina Faso',
                subtitle: '${paysInfo?['indicatif']} • ${paysInfo?['devise']}',
                onTap: () => _choisirPays(),
              ),
            ]),
            const SizedBox(height: 16),
            _buildSection('🗣️ Langue', [
              _buildItem(
                leading: Text(LanguesData.getDrapeau(_langue),
                    style: const TextStyle(fontSize: 24)),
                title: LanguesData.getNom(_langue),
                subtitle: LanguesData.getNatif(_langue),
                onTap: () => _choisirLangue(),
              ),
            ]),
            const SizedBox(height: 16),
            _buildSection('🔊 Aide vocale', [
              SwitchListTile(
                value: _vocalActif,
                onChanged: (v) {
                  setState(() => _vocalActif = v);
                  if (v) _vocal.parler('Aide vocale activée');
                },
                title: const Text('Notifications vocales',
                    style: TextStyle(fontFamily: 'Nunito', fontSize: 14)),
                subtitle: const Text('Recevoir les alertes en audio',
                    style: TextStyle(fontFamily: 'Nunito', fontSize: 12, color: AppTheme.grisTexte)),
                activeColor: AppTheme.vert,
              ),
            ]),
            const SizedBox(height: 16),
            _buildSection('🔤 Taille du texte', [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('A', style: TextStyle(fontSize: 12, color: AppTheme.grisTexte)),
                        Text('Aperçu du texte',
                            style: TextStyle(fontFamily: 'Nunito', fontSize: _fontSize)),
                        const Text('A', style: TextStyle(fontSize: 20, color: AppTheme.grisTexte)),
                      ],
                    ),
                    Slider(
                      value: _fontSize,
                      min: 12, max: 20,
                      divisions: 4,
                      activeColor: AppTheme.vert,
                      onChanged: (v) => setState(() => _fontSize = v),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['Petit', 'Normal', 'Grand', 'Très grand', 'Maxi']
                          .map((l) => Text(l,
                              style: const TextStyle(fontSize: 10, color: AppTheme.grisTexte)))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 16),
            _buildSection('💳 Mobile Money', [
              ...PaysData.getMobileMoney(_pays).map((mm) => ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.vert),
                title: Text(mm, style: const TextStyle(fontFamily: 'Nunito', fontSize: 14)),
                trailing: const Icon(Icons.chevron_right, color: AppTheme.grisTexte),
              )),
            ]),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _sauvegarder,
              child: const Text('Sauvegarder les réglages'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String titre, List<Widget> enfants) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(titre,
              style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w700,
                color: AppTheme.grisTexte,
              )),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8E8E5), width: 0.5),
          ),
          child: Column(children: enfants),
        ),
      ],
    );
  }

  Widget _buildItem({required Widget leading, required String title,
      String? subtitle, VoidCallback? onTap}) {
    return ListTile(
      leading: leading,
      title: Text(title,
          style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, color: AppTheme.grisTexte))
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
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.grisClair, borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Choisir un pays',
                  style: TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: PaysData.pays.length,
                itemBuilder: (ctx, i) {
                  final p = PaysData.pays[i];
                  final selected = _pays == p['code'];
                  return ListTile(
                    leading: Text(p['drapeau'], style: const TextStyle(fontSize: 24)),
                    title: Text(p['nom'],
                        style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600,
                            color: selected ? AppTheme.vert : AppTheme.texte)),
                    subtitle: Text('${p['indicatif']} • ${p['devise']}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.grisTexte)),
                    trailing: selected ? const Icon(Icons.check_circle, color: AppTheme.vert) : null,
                    onTap: () {
                      setState(() {
                        _pays = p['code'];
                        final langues = PaysData.getLanguesPays(p['code']);
                        if (!langues.contains(_langue)) _langue = langues.first;
                      });
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _choisirLangue() {
    final langues = PaysData.getLanguesPays(_pays);
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
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.grisClair, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Choisir une langue',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...langues.map((code) => ListTile(
              leading: Text(LanguesData.getDrapeau(code), style: const TextStyle(fontSize: 24)),
              title: Text(LanguesData.getNom(code),
                  style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600,
                      color: _langue == code ? AppTheme.vert : AppTheme.texte)),
              subtitle: Text(LanguesData.getNatif(code),
                  style: const TextStyle(fontSize: 12, color: AppTheme.grisTexte)),
              trailing: _langue == code ? const Icon(Icons.check_circle, color: AppTheme.vert) : null,
              onTap: () {
                setState(() => _langue = code);
                Navigator.pop(ctx);
              },
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _sauvegarder() async {
    await StorageService.saveLangue(_langue);
    await StorageService.savePays(_pays);
    _vocal.parler('Réglages sauvegardés');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Réglages sauvegardés !'), backgroundColor: AppTheme.vert),
      );
    }
  }

  @override
  void dispose() {
    _vocal.stop();
    super.dispose();
  }
}