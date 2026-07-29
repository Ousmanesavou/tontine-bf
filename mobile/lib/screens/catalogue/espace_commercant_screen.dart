import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';
import '../../main.dart';
import '../../widgets/media_picker_widget.dart';

class EspaceCommercantScreen extends ConsumerStatefulWidget {
  const EspaceCommercantScreen({super.key});

  @override
  ConsumerState<EspaceCommercantScreen> createState() =>
      _EspaceCommercantScreenState();
}

class _EspaceCommercantScreenState
    extends ConsumerState<EspaceCommercantScreen> {
  bool _chargement = true;
  Map<String, dynamic>? _statut;
  List<Map<String, dynamic>> _produits = [];

  // Formulaire de demande
  final _nomCtrl = TextEditingController();
  final _proprietaireCtrl = TextEditingController();
  final _telephoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  String _categorie = 'general';
  bool _livraisonDemande = false;
  bool _envoiEnCours = false;

  final List<Map<String, String>> _categories = const [
    {'valeur': 'electromenager', 'label': '❄️ Électroménager'},
    {'valeur': 'meubles', 'label': '🛋️ Meubles'},
    {'valeur': 'alimentation', 'label': '🍎 Alimentation'},
    {'valeur': 'agriculture', 'label': '🌾 Agriculture'},
    {'valeur': 'informatique', 'label': '💻 Informatique'},
    {'valeur': 'general', 'label': '🏪 Général'},
  ];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _proprietaireCtrl.dispose();
    _telephoneCtrl.dispose();
    _emailCtrl.dispose();
    _adresseCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    try {
      final statut = await ApiService.getMonStatutCommercant();
      List<Map<String, dynamic>> produits = [];
      if (statut != null && statut['statut'] == 'valide') {
        try {
          produits = await ApiService.getMesProduitsCommercant();
        } catch (_) {}
      }
      setState(() {
        _statut = statut;
        _produits = produits;
        _chargement = false;
      });
    } catch (e) {
      setState(() => _chargement = false);
    }
  }

  void _snack(String msg, Color couleur) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: couleur));
  }

  Future<void> _envoyerDemande() async {
    if (_nomCtrl.text.trim().isEmpty) {
      _snack('Le nom de l\'entreprise est requis', AppTheme.rouge);
      return;
    }
    setState(() => _envoiEnCours = true);
    try {
      await ApiService.demanderCommercant({
        'nom': _nomCtrl.text.trim(),
        'proprietaire': _proprietaireCtrl.text.trim(),
        'telephone': _telephoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'categorie': _categorie,
        'adresse': _adresseCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim(),
        'livraison_disponible': _livraisonDemande,
      });
      _snack('Demande envoyée ! En attente de validation.', AppTheme.vert);
      await _charger();
    } catch (e) {
      _snack(e.toString(), AppTheme.rouge);
    } finally {
      if (mounted) setState(() => _envoiEnCours = false);
    }
  }

  Future<void> _ouvrirFormulaireProduit({Map<String, dynamic>? produit}) async {
    final nomCtrl = TextEditingController(text: produit?['nom'] ?? '');
    final prixCtrl = TextEditingController(
        text: produit?['prix'] != null ? produit!['prix'].toString() : '');
    final descCtrl = TextEditingController(text: produit?['description'] ?? '');
    final emojiCtrl = TextEditingController(text: produit?['emoji'] ?? '📦');
    String categorie = produit?['categorie'] ?? 'general';
    bool livraison = produit?['livraison_disponible'] ?? false;
    List<Map<String, dynamic>> mediasSelectionnes = [];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(produit == null ? 'Nouveau produit' : 'Modifier le produit',
                    style: const TextStyle(fontFamily: 'Nunito',
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                TextField(
                  controller: nomCtrl,
                  decoration: const InputDecoration(labelText: 'Nom du produit'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: categorie,
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                  items: _categories.map((c) => DropdownMenuItem(
                      value: c['valeur'], child: Text(c['label']!))).toList(),
                  onChanged: (v) => setModal(() => categorie = v ?? 'general'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: prixCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Prix (F CFA)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emojiCtrl,
                  maxLength: 4,
                  decoration: const InputDecoration(labelText: 'Emoji représentatif'),
                ),
                
                const SizedBox(height: 8),
                const Text('Photos / vidéos du produit',
                    style: TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                MediaPickerWidget(
                  onMediaChanged: (medias) => setModal(() => mediasSelectionnes = medias),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: livraison,
                  activeThumbColor: AppTheme.vert,
                  title: const Text('Livraison disponible',
                      style: TextStyle(fontFamily: 'Nunito', fontSize: 14)),
                  onChanged: (v) => setModal(() => livraison = v),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.vert, padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () async {
                      if (nomCtrl.text.trim().isEmpty || prixCtrl.text.trim().isEmpty) {
                        _snack('Nom et prix requis', AppTheme.rouge);
                        return;
                      }
                      final data = {
                        'nom': nomCtrl.text.trim(),
                        'categorie': categorie,
                        'prix': double.tryParse(prixCtrl.text.trim()) ?? 0,
                        'description': descCtrl.text.trim(),
                        'emoji': emojiCtrl.text.trim().isEmpty ? '📦' : emojiCtrl.text.trim(),
                        'livraison_disponible': livraison,
                        'medias': mediasSelectionnes,
                      };
                      try {
                        if (produit == null) {
                          await ApiService.ajouterProduitCommercant(data);
                        } else {
                          await ApiService.modifierProduitCommercant(
                              produit['id'].toString(), data);
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                        _snack('Produit enregistré !', AppTheme.vert);
                        _charger();
                      } catch (e) {
                        _snack(e.toString(), AppTheme.rouge);
                      }
                    },
                    child: Text(produit == null ? 'Publier le produit' : 'Enregistrer',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _supprimerProduit(String id) async {
    try {
      await ApiService.supprimerProduitCommercant(id);
      _snack('Produit retiré', AppTheme.orange);
      _charger();
    } catch (e) {
      _snack(e.toString(), AppTheme.rouge);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fond,
      appBar: AppBar(
        backgroundColor: AppTheme.vertFonce,
        foregroundColor: Colors.white,
        title: const Text('Espace commerçant',
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: AppTheme.vert))
          : _buildContenu(),
    );
  }

  Widget _buildContenu() {
    if (_statut == null) return _buildFormulaireDemande();
    final statut = _statut!['statut'];
    if (statut == 'en_attente') return _buildEnAttente();
    if (statut == 'refuse') return _buildRefuse();
    if (statut == 'valide') return _buildEspaceProduits();
    return _buildFormulaireDemande();
  }

  Widget _buildFormulaireDemande() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.vertTresClair,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.vertClair),
            ),
            child: const Text(
              'Devenez commerçant partenaire et publiez vos produits dans le catalogue TontiLigdi. Remplissez ce formulaire, un administrateur validera votre demande.',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: AppTheme.vertFonce),
            ),
          ),
          const SizedBox(height: 20),
          TextField(controller: _nomCtrl,
              decoration: const InputDecoration(labelText: 'Nom de l\'entreprise / boutique *')),
          const SizedBox(height: 12),
          TextField(controller: _proprietaireCtrl,
              decoration: const InputDecoration(labelText: 'Propriétaire')),
          const SizedBox(height: 12),
          TextField(controller: _telephoneCtrl, keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Téléphone')),
          const SizedBox(height: 12),
          TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _categorie,
            decoration: const InputDecoration(labelText: 'Catégorie principale'),
            items: _categories.map((c) => DropdownMenuItem(
                value: c['valeur'], child: Text(c['label']!))).toList(),
            onChanged: (v) => setState(() => _categorie = v ?? 'general'),
          ),
          const SizedBox(height: 12),
          TextField(controller: _adresseCtrl,
              decoration: const InputDecoration(labelText: 'Adresse / Localisation')),
          const SizedBox(height: 12),
          TextField(controller: _descriptionCtrl, maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description / Spécialité')),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _livraisonDemande,
            activeThumbColor: AppTheme.vert,
            title: const Text('Livraison disponible',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 14)),
            onChanged: (v) => setState(() => _livraisonDemande = v),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.vert, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: _envoiEnCours ? null : _envoyerDemande,
              child: _envoiEnCours
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Envoyer la demande',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnAttente() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hourglass_top_rounded, size: 56, color: AppTheme.orange),
            const SizedBox(height: 16),
            const Text('Demande en cours d\'examen',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Votre demande pour "${_statut!['nom']}" a été envoyée. Un administrateur va l\'examiner sous peu.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, color: AppTheme.grisTexte),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefuse() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cancel_outlined, size: 56, color: AppTheme.rouge),
            const SizedBox(height: 16),
            const Text('Demande refusée',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'Votre précédente demande n\'a pas été validée. Vous pouvez soumettre une nouvelle demande.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: AppTheme.grisTexte),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.vert),
              onPressed: () => setState(() => _statut = null),
              child: const Text('Nouvelle demande', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEspaceProduits() {
    return Stack(
      children: [
        RefreshIndicator(
          color: AppTheme.vert,
          onRefresh: _charger,
          child: _produits.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(60),
                      child: Center(
                        child: Text('Aucun produit publié pour l\'instant',
                            style: TextStyle(fontFamily: 'Nunito', color: AppTheme.grisTexte)),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                  itemCount: _produits.length,
                  itemBuilder: (ctx, i) {
                    final p = _produits[i];
                    final actif = p['est_actif'] == true;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE8E8E5)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46, height: 46,
                            decoration: BoxDecoration(
                                color: AppTheme.vertClair, borderRadius: BorderRadius.circular(10)),
                            child: Center(child: Text(p['emoji'] ?? '📦', style: const TextStyle(fontSize: 22))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p['nom'] ?? '', style: const TextStyle(
                                    fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 14)),
                                Text('${p['prix']} F CFA', style: const TextStyle(
                                    fontFamily: 'Nunito', color: AppTheme.vert, fontWeight: FontWeight.w600)),
                                if (!actif)
                                  const Text('Désactivé', style: TextStyle(
                                      fontFamily: 'Nunito', fontSize: 11, color: AppTheme.rouge)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppTheme.grisTexte, size: 20),
                            onPressed: () => _ouvrirFormulaireProduit(produit: p),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.rouge, size: 20),
                            onPressed: () => _supprimerProduit(p['id'].toString()),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        Positioned(
          right: 16, bottom: 16,
          child: FloatingActionButton.extended(
            backgroundColor: AppTheme.vert,
            onPressed: () => _ouvrirFormulaireProduit(),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Ajouter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}