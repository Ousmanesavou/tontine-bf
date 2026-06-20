import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/vocal_service.dart';

class MembresScreen extends StatefulWidget {
  final String tontineId;
  const MembresScreen({super.key, required this.tontineId});

  @override
  State<MembresScreen> createState() => _MembresScreenState();
}

class _MembresScreenState extends State<MembresScreen> {
  List<Map<String, dynamic>> _membres = [];
  bool _chargement = true;
  final VocalService _vocal = VocalService();
  final _telCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final tontine = await ApiService.getTontine(widget.tontineId);
      setState(() {
        _membres = List<Map<String, dynamic>>.from(tontine['membres'] ?? []);
        _chargement = false;
      });
    } catch (e) {
      setState(() => _chargement = false);
    }
  }

  Future<void> _inviter() async {
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.grisClair,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Inviter un membre',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 6),
              const Text(
                'La personne recevra un SMS d\'invitation même sans smartphone.',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    color: AppTheme.grisTexte),
              ),
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
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  if (_telCtrl.text.length >= 8) {
                    try {
                      await ApiService.inviterMembre(
                          widget.tontineId, '+226${_telCtrl.text}');
                      _telCtrl.clear();
                      if (mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Invitation envoyée par SMS !'),
                            backgroundColor: AppTheme.vert,
                          ),
                        );
                        _vocal.parler('Invitation envoyée avec succès.');
                        _charger();
                      }
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
                },
                icon: const Icon(Icons.send_outlined),
                label: const Text('Envoyer l\'invitation'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fond,
      appBar: AppBar(
        backgroundColor: AppTheme.vert,
        foregroundColor: Colors.white,
        title: Text('Membres (${_membres.length})',
            style: const TextStyle(
                fontFamily: 'Nunito', color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded, color: Colors.white70),
            onPressed: () => _vocal.parler(
                '${_membres.length} membres dans cette tontine.'),
          ),
          IconButton(
            icon: const Icon(Icons.person_add_outlined, color: Colors.white),
            onPressed: _inviter,
          ),
        ],
      ),
      body: _chargement
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.vert))
          : _membres.isEmpty
              ? _buildEtatVide()
              : RefreshIndicator(
                  color: AppTheme.vert,
                  onRefresh: _charger,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _membres.length,
                    itemBuilder: (ctx, i) => _buildCarteMembre(_membres[i], i),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _inviter,
        backgroundColor: AppTheme.vert,
        icon: const Icon(Icons.person_add_outlined, color: Colors.white),
        label: const Text('Inviter',
            style: TextStyle(
                fontFamily: 'Nunito',
                color: Colors.white,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildCarteMembre(Map<String, dynamic> membre, int index) {
    final aRecu = membre['a_recu'] == true;
    final score = membre['score_fiabilite'] as int? ?? 100;
    final couleurScore = score >= 80
        ? AppTheme.vert
        : score >= 50
            ? AppTheme.orange
            : AppTheme.rouge;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: aRecu
              ? AppTheme.vert.withOpacity(0.3)
              : const Color(0xFFE8E8E5),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: aRecu ? AppTheme.vert : AppTheme.grisClair,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${membre['prenom']?[0] ?? '?'}${membre['nom']?[0] ?? ''}',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: aRecu ? Colors.white : AppTheme.grisTexte,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${membre['prenom']} ${membre['nom']}',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.texte,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  membre['telephone'] ?? '',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: AppTheme.grisTexte,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.vertClair,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Tour ${membre['position_rotation']}',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.vertFonce,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: couleurScore.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Fiabilité $score%',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: couleurScore,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (aRecu)
            const Icon(Icons.check_circle, color: AppTheme.vert, size: 24)
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.orangeClair,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'En attente',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.orangeFonce,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEtatVide() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👥', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text('Aucun membre pour l\'instant',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.texte,
              )),
          const SizedBox(height: 8),
          const Text(
            'Invitez des membres pour démarrer\nvotre tontine',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: AppTheme.grisTexte),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _inviter,
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('Inviter un membre'),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 48)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _telCtrl.dispose();
    _vocal.stop();
    super.dispose();
  }
}