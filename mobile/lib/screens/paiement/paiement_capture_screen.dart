import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../main.dart';

class PaiementCaptureScreen extends ConsumerStatefulWidget {
  final String tontineId;
  final double montant;
  final String numeroOrganisateur;
  final String operateur;
  final String nomTontine;

  const PaiementCaptureScreen({
    super.key,
    required this.tontineId,
    required this.montant,
    required this.numeroOrganisateur,
    required this.operateur,
    required this.nomTontine,
  });

  @override
  ConsumerState<PaiementCaptureScreen> createState() =>
      _PaiementCaptureScreenState();
}

class _PaiementCaptureScreenState
    extends ConsumerState<PaiementCaptureScreen> {
  File? _capture;
  bool _chargement = false;
  Map<String, dynamic>? _resultatIA;
  String? _erreur;
  int _etape = 1; // 1=instructions, 2=upload, 3=resultat

  Future<void> _prendreCapture(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (image != null) {
      setState(() {
        _capture = File(image.path);
        _etape = 2;
        _erreur = null;
        _resultatIA = null;
      });
    }
  }

  Future<void> _soumettre() async {
    if (_capture == null) return;
    setState(() { _chargement = true; _erreur = null; });

    try {
      final result = await ApiService.soumettreCapturePaiement(
        tontineId: widget.tontineId,
        montant: widget.montant,
        captureFile: _capture!,
        methode: widget.operateur,
      );

      setState(() {
        _resultatIA = result['analyse'];
        _etape = 3;
        _chargement = false;
      });
    } catch (e) {
      setState(() {
        _erreur = e.toString();
        _chargement = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final langue = ref.watch(langueProvider);
    final sw = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppTheme.fond,
      appBar: AppBar(
        backgroundColor: AppTheme.vert,
        foregroundColor: Colors.white,
        title: const Text('Payer ma cotisation',
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── STEPPER ───────────────────────────────
            _buildStepper(),
            const SizedBox(height: 20),

            // ── CONTENU SELON ÉTAPE ───────────────────
            if (_etape == 1) _buildEtape1(sw),
            if (_etape == 2) _buildEtape2(sw),
            if (_etape == 3) _buildEtape3(sw),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper() {
    return Row(
      children: [
        _stepItem(1, 'Instructions', _etape >= 1),
        Expanded(child: Container(height: 2,
            color: _etape >= 2 ? AppTheme.vert : AppTheme.grisClair)),
        _stepItem(2, 'Capture', _etape >= 2),
        Expanded(child: Container(height: 2,
            color: _etape >= 3 ? AppTheme.vert : AppTheme.grisClair)),
        _stepItem(3, 'Résultat', _etape >= 3),
      ],
    );
  }

  Widget _stepItem(int num, String label, bool actif) {
    return Column(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: actif ? AppTheme.vert : AppTheme.grisClair,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: actif && _etape > num
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Text('$num', style: TextStyle(
                  fontFamily: 'Nunito', fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: actif ? Colors.white : AppTheme.grisTexte)),
        ),
      ),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(
          fontFamily: 'Nunito', fontSize: 10,
          color: actif ? AppTheme.vert : AppTheme.grisTexte)),
    ]);
  }

  Widget _buildEtape1(double sw) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Carte montant
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.vert,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: [
            const Text('Montant à payer',
                style: TextStyle(fontFamily: 'Nunito',
                    fontSize: 14, color: Colors.white70)),
            const SizedBox(height: 8),
            Text('${_formatMontant(widget.montant)} F CFA',
                style: const TextStyle(fontFamily: 'Nunito',
                    fontSize: 32, fontWeight: FontWeight.w800,
                    color: Colors.white)),
            const SizedBox(height: 4),
            Text(widget.nomTontine,
                style: const TextStyle(fontFamily: 'Nunito',
                    fontSize: 13, color: Colors.white60)),
          ]),
        ),

        const SizedBox(height: 20),

        // Instructions de paiement
        const Text('Comment payer ?',
            style: TextStyle(fontFamily: 'Nunito',
                fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),

        _instructionCard(
          numero: '1',
          couleur: AppTheme.orange,
          titre: 'Ouvrez ${widget.operateur}',
          description: 'Ouvrez votre application ${widget.operateur} '
              'ou composez le code USSD.',
        ),
        _instructionCard(
          numero: '2',
          couleur: AppTheme.vert,
          titre: 'Envoyez ${_formatMontant(widget.montant)} F CFA',
          description: 'Numéro destinataire :',
          widget: Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.vertClair,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.vert),
            ),
            child: Row(children: [
              Text(widget.numeroOrganisateur,
                  style: const TextStyle(
                      fontFamily: 'Nunito', fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.vertFonce)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy, color: AppTheme.vert),
                onPressed: () {
                  // Copy to clipboard
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Numéro copié !')));
                },
              ),
            ]),
          ),
        ),
        _instructionCard(
          numero: '3',
          couleur: const Color(0xFF7B1FA2),
          titre: 'Faites une capture d\'écran',
          description: 'Capturez l\'écran de confirmation de votre paiement.',
        ),
        _instructionCard(
          numero: '4',
          couleur: const Color(0xFF1976D2),
          titre: 'Soumettez la capture',
          description: 'Uploadez la capture dans l\'étape suivante pour validation.',
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _etape = 2),
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('J\'ai payé, soumettre la capture',
                style: TextStyle(fontFamily: 'Nunito',
                    fontSize: 15, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.vert,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEtape2(double sw) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Soumettez votre capture',
            style: TextStyle(fontFamily: 'Nunito',
                fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text(
          'L\'IA analysera automatiquement votre capture pour valider le paiement.',
          style: TextStyle(fontFamily: 'Nunito',
              fontSize: 13, color: AppTheme.grisTexte),
        ),
        const SizedBox(height: 16),

        // Zone capture
        if (_capture == null)
          Row(children: [
            Expanded(
              child: _uploadBtn(
                icon: Icons.camera_alt,
                label: 'Prendre\nune photo',
                onTap: () => _prendreCapture(ImageSource.camera),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _uploadBtn(
                icon: Icons.photo_library_outlined,
                label: 'Choisir dans\nla galerie',
                onTap: () => _prendreCapture(ImageSource.gallery),
              ),
            ),
          ])
        else
          Column(children: [
            // Aperçu capture
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(_capture!,
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.contain),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _capture = null),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Changer',
                      style: TextStyle(fontFamily: 'Nunito')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.grisTexte,
                    side: const BorderSide(color: AppTheme.grisClair),
                  ),
                ),
              ),
            ]),
          ]),

        if (_erreur != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.rouge.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppTheme.rouge.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline,
                  color: AppTheme.rouge, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(_erreur!,
                  style: const TextStyle(fontFamily: 'Nunito',
                      fontSize: 12, color: AppTheme.rouge))),
            ]),
          ),
        ],

        const SizedBox(height: 20),

        if (_capture != null)
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _chargement ? null : _soumettre,
              icon: _chargement
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.auto_awesome),
              label: Text(
                _chargement ? 'Analyse en cours...' : 'Analyser et soumettre',
                style: const TextStyle(fontFamily: 'Nunito',
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.vert,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

        // Info IA
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(children: [
            Icon(Icons.auto_awesome, color: Color(0xFF1976D2), size: 18),
            SizedBox(width: 8),
            Expanded(child: Text(
              'Notre IA analyse automatiquement votre capture pour valider le paiement.',
              style: TextStyle(fontFamily: 'Nunito',
                  fontSize: 12, color: Color(0xFF1565C0)),
            )),
          ]),
        ),
      ],
    );
  }

  Widget _buildEtape3(double sw) {
    if (_resultatIA == null) return const SizedBox();

    final score = _resultatIA!['scoreConfiance'] as int? ?? 0;
    final decision = _resultatIA!['decision'] as String? ?? '';
    final operateur = _resultatIA!['operateur'] as String? ?? '';
    final alertes = List<String>.from(_resultatIA!['alertes'] ?? []);
    final details = _resultatIA!['details'] as Map? ?? {};

    Color couleurDecision;
    IconData iconeDecision;
    String messageDecision;
    String descriptionDecision;

    switch (decision) {
      case 'AUTO_VALIDE':
        couleurDecision = AppTheme.vert;
        iconeDecision = Icons.check_circle;
        messageDecision = '✅ Paiement validé automatiquement !';
        descriptionDecision =
            'Votre cotisation a été validée par notre IA avec un score de confiance de $score%.';
        break;
      case 'VALIDATION_MANUELLE':
        couleurDecision = AppTheme.orange;
        iconeDecision = Icons.pending;
        messageDecision = '⏳ En attente de validation';
        descriptionDecision =
            'Votre capture nécessite une vérification manuelle par l\'organisateur.';
        break;
      default:
        couleurDecision = AppTheme.rouge;
        iconeDecision = Icons.cancel;
        messageDecision = '❌ Paiement rejeté';
        descriptionDecision =
            'Votre capture n\'a pas pu être validée. Veuillez soumettre une nouvelle capture.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Résultat principal
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: couleurDecision.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: couleurDecision.withOpacity(0.3), width: 1.5),
          ),
          child: Column(children: [
            Icon(iconeDecision, color: couleurDecision, size: 48),
            const SizedBox(height: 12),
            Text(messageDecision,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Nunito',
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: couleurDecision)),
            const SizedBox(height: 8),
            Text(descriptionDecision,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Nunito',
                    fontSize: 13, color: AppTheme.grisTexte)),
          ]),
        ),

        const SizedBox(height: 16),

        // Score IA
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8E8E5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Analyse IA',
                  style: TextStyle(fontFamily: 'Nunito',
                      fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              // Score bar
              Row(children: [
                const Text('Score de confiance',
                    style: TextStyle(fontFamily: 'Nunito',
                        fontSize: 13, color: AppTheme.grisTexte)),
                const Spacer(),
                Text('$score%',
                    style: TextStyle(fontFamily: 'Nunito',
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: score >= 85 ? AppTheme.vert
                            : score >= 60 ? AppTheme.orange
                            : AppTheme.rouge)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: score / 100,
                  backgroundColor: AppTheme.grisClair,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      score >= 85 ? AppTheme.vert
                          : score >= 60 ? AppTheme.orange
                          : AppTheme.rouge),
                  minHeight: 8,
                ),
              ),

              // Opérateur détecté
              if (operateur.isNotEmpty) ...[
                const SizedBox(height: 12),
                _detailRow('Opérateur détecté', operateur),
              ],
              if (details['montant'] != null)
                _detailRow('Montant détecté', '${details['montant']} F CFA'),
              if (details['reference'] != null)
                _detailRow('Référence', details['reference']),
              if (details['date'] != null)
                _detailRow('Date', details['date']),
            ],
          ),
        ),

        // Alertes si présentes
        if (alertes.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppTheme.orange.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppTheme.orange, size: 18),
                  SizedBox(width: 8),
                  Text('Points d\'attention',
                      style: TextStyle(fontFamily: 'Nunito',
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: AppTheme.orange)),
                ]),
                const SizedBox(height: 8),
                ...alertes.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    const Text('• ',
                        style: TextStyle(color: AppTheme.orange)),
                    Expanded(child: Text(a,
                        style: const TextStyle(
                            fontFamily: 'Nunito', fontSize: 12))),
                  ]),
                )),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Boutons action
        if (decision == 'REJETE') ...[
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () => setState(() {
                _etape = 2;
                _capture = null;
                _resultatIA = null;
              }),
              icon: const Icon(Icons.upload),
              label: const Text('Soumettre une nouvelle capture',
                  style: TextStyle(fontFamily: 'Nunito',
                      fontSize: 14, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.vert,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Retour à l\'accueil',
                  style: TextStyle(fontFamily: 'Nunito',
                      fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.vert,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _instructionCard({
    required String numero,
    required Color couleur,
    required String titre,
    required String description,
    Widget? widget,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
                color: couleur, shape: BoxShape.circle),
            child: Center(child: Text(numero,
                style: const TextStyle(fontFamily: 'Nunito',
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: Colors.white))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titre, style: const TextStyle(
                  fontFamily: 'Nunito', fontSize: 14,
                  fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(description, style: const TextStyle(
                  fontFamily: 'Nunito', fontSize: 12,
                  color: AppTheme.grisTexte)),
              if (widget != null) widget,
            ],
          )),
        ],
      ),
    );
  }

  Widget _uploadBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppTheme.vert.withOpacity(0.4),
              width: 1.5,
              style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.vert, size: 32),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Nunito',
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppTheme.vertFonce)),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String valeur) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(children: [
        Text(label, style: const TextStyle(
            fontFamily: 'Nunito', fontSize: 12,
            color: AppTheme.grisTexte)),
        const Spacer(),
        Text(valeur, style: const TextStyle(
            fontFamily: 'Nunito', fontSize: 12,
            fontWeight: FontWeight.w600)),
      ]),
    );
  }

  String _formatMontant(double m) {
    if (m >= 1000000) return '${(m/1000000).toStringAsFixed(1)}M';
    if (m >= 1000) return '${(m/1000).toStringAsFixed(0)}k';
    return m.toStringAsFixed(0);
  }
}
