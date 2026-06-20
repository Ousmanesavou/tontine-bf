import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/vocal_service.dart';

class PaiementScreen extends StatefulWidget {
  final String cotisationId;
  const PaiementScreen({super.key, required this.cotisationId});

  @override
  State<PaiementScreen> createState() => _PaiementScreenState();
}

class _PaiementScreenState extends State<PaiementScreen> {
  String _methode = 'orange_money';
  bool _chargement = false;
  final VocalService _vocal = VocalService();

  final List<Map<String, dynamic>> _methodes = [
    {
      'code': 'orange_money',
      'label': 'Orange Money',
      'couleur': const Color(0xFFFF6600),
      'initiales': 'OM',
    },
    {
      'code': 'moov_money',
      'label': 'Moov Money',
      'couleur': const Color(0xFF0066CC),
      'initiales': 'MM',
    },
    {
      'code': 'depot_physique',
      'label': 'Dépôt physique',
      'couleur': AppTheme.vert,
      'initiales': 'DP',
    },
  ];

  Future<void> _payer() async {
    setState(() => _chargement = true);
    try {
      final user = StorageService.getUser();
      await ApiService.initierPaiement(
        cotisationId: widget.cotisationId,
        methodePaiement: _methode,
        telephone: user?['telephone'],
      );
      _vocal.annoncerPaiementReussi('', '');
      if (mounted) context.go('/paiement/succes');
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
    return Scaffold(
      backgroundColor: AppTheme.fond,
      appBar: AppBar(
        backgroundColor: AppTheme.vert,
        foregroundColor: Colors.white,
        title: const Text('Payer ma cotisation',
            style: TextStyle(fontFamily: 'Nunito', color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded, color: Colors.white70),
            onPressed: () => _vocal.parler(
                'Choisissez votre moyen de paiement et confirmez.'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMontantCard(),
            const SizedBox(height: 24),
            const Text('Moyen de paiement',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.grisTexte,
                  letterSpacing: 0.5,
                )),
            const SizedBox(height: 12),
            ..._methodes.map((m) => _buildMethodeCard(m)),
            const SizedBox(height: 16),
            _buildInfoBox(),
            const Spacer(),
            _chargement
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.vert))
                : ElevatedButton.icon(
                    onPressed: _payer,
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('Confirmer le paiement'),
                  ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildMontantCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.vert,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: const [
          Text('Montant à payer',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: Colors.white70,
              )),
          SizedBox(height: 8),
          Text('15 000 F CFA',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              )),
          SizedBox(height: 4),
          Text('Tontine · Période en cours',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                color: Colors.white60,
              )),
        ],
      ),
    );
  }

  Widget _buildMethodeCard(Map<String, dynamic> methode) {
    final selected = _methode == methode['code'];
    return GestureDetector(
      onTap: () => setState(() => _methode = methode['code']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? methode['couleur'] : const Color(0xFFE8E8E5),
            width: selected ? 2 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: methode['couleur'],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(methode['initiales'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    )),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(methode['label'],
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  )),
            ),
            if (selected)
              Icon(Icons.check_circle,
                  color: methode['couleur'], size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.vertClair,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.volume_up_rounded, color: AppTheme.vert, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Après le paiement, tous les membres recevront une notification vocale de confirmation.',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                color: AppTheme.vertFonce,
              ),
            ),
          ),
        ],
      ),
    );
  }
}