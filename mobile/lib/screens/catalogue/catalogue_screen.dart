import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_theme.dart';
import '../../services/vocal_service.dart';
import '../../services/api_service.dart';
import '../../main.dart';

// ── TRADUCTIONS CATALOGUE ─────────────────────────────
const Map<String, Map<String, String>> _tr = {
  'fr': {
    'titre': 'Catalogue',
    'rechercher': 'Rechercher un produit...',
    'aucun': 'Aucun produit trouvé',
    'populaire': 'Populaire',
    'livraison': 'Livraison',
    'creer_tontine': 'Créer une tontine pour ce produit',
    'fournisseur': 'Fournisseur',
    'livraison_dispo': 'Livraison disponible',
    'tout': 'Tout',
    'vocal': 'Catalogue de produits. Choisissez un article pour créer une tontine.',
  },
  'en': {
    'titre': 'Catalogue',
    'rechercher': 'Search a product...',
    'aucun': 'No product found',
    'populaire': 'Popular',
    'livraison': 'Delivery',
    'creer_tontine': 'Create a tontine for this product',
    'fournisseur': 'Supplier',
    'livraison_dispo': 'Delivery available',
    'tout': 'All',
    'vocal': 'Product catalogue. Choose an item to create a tontine.',
  },
  'mos': {
    'titre': 'Katalɔg',
    'rechercher': 'Bʋgs bũmb...',
    'aucun': 'Bũmb ka be ye',
    'populaire': 'Waoogã',
    'livraison': 'Kõ-rʋʋg',
    'creer_tontine': 'Bʋg tontine bũmb kãng yĩnga',
    'fournisseur': 'Neb rãmba',
    'livraison_dispo': 'Kõ-rʋʋg bee',
    'tout': 'Fãa',
    'vocal': 'Katalɔg. Paam bũmb n bʋg tontine.',
  },
  'bm': {
    'titre': 'Katalogi',
    'rechercher': 'Fɛn ɲini...',
    'aucun': 'Fɛn si sɔrɔla',
    'populaire': 'Caman b\'a fɛ',
    'livraison': 'Nali',
    'creer_tontine': 'Tontine daminɛ fɛn in na',
    'fournisseur': 'Jarabara',
    'livraison_dispo': 'Nali be yen',
    'tout': 'Bɛɛ',
    'vocal': 'Katalogi. Fɛn sugandi ka tontine daminɛ.',
  },
  'wo': {
    'titre': 'Katalog',
    'rechercher': 'Seet ay jëf...',
    'aucun': 'Dara amul',
    'populaire': 'Waaw waaw',
    'livraison': 'Yóbbale',
    'creer_tontine': 'Def tontine bi pour jëf bii',
    'fournisseur': 'Jëndkat',
    'livraison_dispo': 'Yóbbale am na',
    'tout': 'Yëpp',
    'vocal': 'Katalog. Tann ay jëf ngir def tontine.',
  },
};

String _t(String langue, String key) {
  final lang = _tr[langue] ?? _tr['fr']!;
  return lang[key] ?? _tr['fr']![key] ?? key;
}

final catalogueProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    return await ApiService.getCatalogue();
  } catch (e) {
    return [];
  }
});

class CatalogueScreen extends ConsumerStatefulWidget {
  const CatalogueScreen({super.key});

  @override
  ConsumerState<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends ConsumerState<CatalogueScreen> {
  final VocalService _vocal = VocalService();
  String _categorieSelectionnee = 'tous';
  final _rechercheCtrl = TextEditingController();

  // Produits locaux par défaut si le backend ne répond pas
  final List<Map<String, dynamic>> _produitsLocaux = [
    {
      'id': '1', 'nom': 'Frigo Samsung 250L',
      'categorie': 'electromenager', 'prix': 150000,
      'emoji': '❄️', 'fournisseur': 'Electroplus',
      'livraison': true, 'populaire': true,
    },
    {
      'id': '2', 'nom': 'Télévision 43 pouces',
      'categorie': 'electromenager', 'prix': 120000,
      'emoji': '📺', 'fournisseur': 'TechStore',
      'livraison': true, 'populaire': false,
    },
    {
      'id': '3', 'nom': 'Climatiseur 1.5 CV',
      'categorie': 'electromenager', 'prix': 250000,
      'emoji': '🌀', 'fournisseur': 'Froid Express',
      'livraison': true, 'populaire': false,
    },
    {
      'id': '4', 'nom': 'Machine à laver',
      'categorie': 'electromenager', 'prix': 180000,
      'emoji': '🫧', 'fournisseur': 'Electroplus',
      'livraison': true, 'populaire': false,
    },
    {
      'id': '5', 'nom': 'Salon complet 7 places',
      'categorie': 'meubles', 'prix': 200000,
      'emoji': '🛋️', 'fournisseur': 'Meubles Prestige',
      'livraison': true, 'populaire': true,
    },
    {
      'id': '6', 'nom': 'Lit + matelas 160x200',
      'categorie': 'meubles', 'prix': 80000,
      'emoji': '🛏️', 'fournisseur': 'Meubles Prestige',
      'livraison': true, 'populaire': false,
    },
    {
      'id': '7', 'nom': 'Ensemble cuisine',
      'categorie': 'cuisine', 'prix': 60000,
      'emoji': '🍳', 'fournisseur': 'Marché Central',
      'livraison': false, 'populaire': true,
    },
    {
      'id': '8', 'nom': 'Gazinière 4 feux',
      'categorie': 'cuisine', 'prix': 45000,
      'emoji': '🔥', 'fournisseur': 'Gaz Express',
      'livraison': false, 'populaire': false,
    },
    {
      'id': '9', 'nom': 'Ordinateur portable',
      'categorie': 'bureau', 'prix': 300000,
      'emoji': '💻', 'fournisseur': 'TechStore',
      'livraison': true, 'populaire': false,
    },
    {
      'id': '10', 'nom': 'Moto Jakarta 125cc',
      'categorie': 'agriculture', 'prix': 500000,
      'emoji': '🛵', 'fournisseur': 'Moto Plus',
      'livraison': false, 'populaire': true,
    },
    {
      'id': '11', 'nom': 'Téléphone Android',
      'categorie': 'bureau', 'prix': 80000,
      'emoji': '📱', 'fournisseur': 'TechStore',
      'livraison': true, 'populaire': true,
    },
    {
      'id': '12', 'nom': 'Générateur 2KVA',
      'categorie': 'electromenager', 'prix': 350000,
      'emoji': '⚡', 'fournisseur': 'Energy Plus',
      'livraison': true, 'populaire': false,
    },
  ];

  List<Map<String, dynamic>> _getCategories(String langue) => [
    {'code': 'tous', 'label': _t(langue, 'tout'), 'emoji': '🛍️'},
    {'code': 'electromenager', 'label': langue == 'en' ? 'Appliances' : 'Électroménager', 'emoji': '❄️'},
    {'code': 'meubles', 'label': langue == 'en' ? 'Furniture' : 'Meubles', 'emoji': '🛋️'},
    {'code': 'cuisine', 'label': langue == 'en' ? 'Kitchen' : 'Cuisine', 'emoji': '🍳'},
    {'code': 'bureau', 'label': langue == 'en' ? 'Office' : 'Bureau', 'emoji': '💻'},
    {'code': 'habits', 'label': langue == 'en' ? 'Clothing' : 'Habits', 'emoji': '👗'},
    {'code': 'agriculture', 'label': langue == 'en' ? 'Agriculture' : 'Agriculture', 'emoji': '🌾'},
  ];

  List<Map<String, dynamic>> _filtrer(List<Map<String, dynamic>> produits) {
    return produits.where((p) {
      final categorieOk = _categorieSelectionnee == 'tous' ||
          p['categorie'] == _categorieSelectionnee;
      final rechercheOk = _rechercheCtrl.text.isEmpty ||
          p['nom'].toString().toLowerCase()
              .contains(_rechercheCtrl.text.toLowerCase());
      return categorieOk && rechercheOk;
    }).toList();
  }

  void _voirProduit(Map<String, dynamic> produit, String langue) {
    _vocal.parler(
        '${produit['nom']}. ${_t(langue, 'fournisseur')} : ${produit['fournisseur']}.');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildDetailProduit(produit, langue),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langue = ref.watch(langueProvider);
    final catalogueAsync = ref.watch(catalogueProvider);
    final sw = MediaQuery.of(context).size.width;
    final isSmall = sw < 360;

    return Scaffold(
      backgroundColor: AppTheme.fond,
      appBar: AppBar(
        backgroundColor: AppTheme.vert,
        foregroundColor: Colors.white,
        title: Text(
          _t(langue, 'titre'),
          style: const TextStyle(fontFamily: 'Nunito', color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded, color: Colors.white70),
            onPressed: () => _vocal.parler(_t(langue, 'vocal')),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () => ref.refresh(catalogueProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildRecherche(langue),
          _buildCategories(langue),
          Expanded(
            child: catalogueAsync.when(
              data: (data) {
                final produits = data.isEmpty ? _produitsLocaux : data;
                final filtres = _filtrer(produits);
                return _buildGrilleProduits(filtres, langue, isSmall);
              },
              loading: () => _buildChargement(),
              error: (_, __) {
                final filtres = _filtrer(_produitsLocaux);
                return _buildGrilleProduits(filtres, langue, isSmall);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecherche(String langue) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _rechercheCtrl,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: _t(langue, 'rechercher'),
          prefixIcon: const Icon(Icons.search, color: AppTheme.grisTexte),
          suffixIcon: _rechercheCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppTheme.grisTexte),
                  onPressed: () {
                    _rechercheCtrl.clear();
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: AppTheme.grisClair,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildCategories(String langue) {
    final categories = _getCategories(langue);
    return Container(
      color: Colors.white,
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: categories.length,
        itemBuilder: (ctx, i) {
          final cat = categories[i];
          final selected = _categorieSelectionnee == cat['code'];
          return GestureDetector(
            onTap: () =>
                setState(() => _categorieSelectionnee = cat['code']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: selected ? AppTheme.vert : AppTheme.grisClair,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Text(cat['emoji'],
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    cat['label'],
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppTheme.texte,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrilleProduits(List<Map<String, dynamic>> produits,
      String langue, bool isSmall) {
    if (produits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              _t(langue, 'aucun'),
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  color: AppTheme.grisTexte),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.vert,
      onRefresh: () => ref.refresh(catalogueProvider.future),
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isSmall ? 2 : 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: isSmall ? 0.65 : 0.72,
        ),
        itemCount: produits.length,
        itemBuilder: (ctx, i) =>
            _buildCarteProduit(produits[i], langue, isSmall),
      ),
    );
  }

  Widget _buildCarteProduit(Map<String, dynamic> produit,
      String langue, bool isSmall) {
    final emoji = produit['emoji'] ?? produit['image_url'] ?? '📦';
    final estEmoji = emoji.length <= 4;

    return GestureDetector(
      onTap: () => _voirProduit(produit, langue),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFFE8E8E5), width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: isSmall ? 90 : 110,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.vertClair,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16)),
                  ),
                  child: Center(
                    child: estEmoji
                        ? Text(emoji,
                            style: TextStyle(
                                fontSize: isSmall ? 40 : 48))
                        : ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                            child: Image.network(
                              emoji,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Text(
                                  '📦',
                                  style: TextStyle(fontSize: 48)),
                            ),
                          ),
                  ),
                ),
                if (produit['populaire'] == true)
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _t(langue, 'populaire'),
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: isSmall ? 9 : 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                if (produit['livraison'] == true)
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delivery_dining,
                          size: 14, color: AppTheme.vert),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(isSmall ? 8 : 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    produit['nom'],
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: isSmall ? 11 : 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.texte,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatPrix(produit['prix'] is int
                        ? produit['prix']
                        : int.tryParse(
                                produit['prix']?.toString() ?? '0') ??
                            0),
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: isSmall ? 12 : 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.vert,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    produit['fournisseur'] ?? '',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: isSmall ? 9 : 10,
                      color: AppTheme.grisTexte,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailProduit(
      Map<String, dynamic> produit, String langue) {
    final emoji = produit['emoji'] ?? produit['image_url'] ?? '📦';
    final estEmoji = emoji.length <= 4;
    final prix = produit['prix'] is int
        ? produit['prix']
        : int.tryParse(produit['prix']?.toString() ?? '0') ?? 0;

    return Container(
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
          Center(
            child: estEmoji
                ? Text(emoji,
                    style: const TextStyle(fontSize: 64))
                : ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(emoji,
                        height: 120, fit: BoxFit.cover),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            produit['nom'],
            style: const TextStyle(
              fontFamily: 'Nunito', fontSize: 20,
              fontWeight: FontWeight.w700, color: AppTheme.texte,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatPrix(prix),
            style: const TextStyle(
              fontFamily: 'Nunito', fontSize: 24,
              fontWeight: FontWeight.w700, color: AppTheme.vert,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.store_outlined,
                  size: 16, color: AppTheme.grisTexte),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${_t(langue, 'fournisseur')}: ${produit['fournisseur'] ?? ''}',
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      color: AppTheme.grisTexte),
                ),
              ),
            ],
          ),
          if (produit['livraison'] == true) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.delivery_dining,
                    size: 16, color: AppTheme.vert),
                const SizedBox(width: 6),
                Text(
                  _t(langue, 'livraison_dispo'),
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      color: AppTheme.vert),
                ),
              ],
            ),
          ],
          if (produit['description'] != null &&
              produit['description'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              produit['description'],
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: AppTheme.grisTexte,
              ),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              context.push('/tontine/creer');
            },
            icon: const Icon(Icons.group_add_outlined),
            label: Text(_t(langue, 'creer_tontine')),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildChargement() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (ctx, i) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              height: 110,
              decoration: BoxDecoration(
                color: AppTheme.grisClair,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                      height: 12,
                      child: DecoratedBox(
                          decoration: BoxDecoration(
                              color: AppTheme.grisClair))),
                  SizedBox(height: 6),
                  SizedBox(
                      height: 12,
                      child: DecoratedBox(
                          decoration: BoxDecoration(
                              color: AppTheme.grisClair))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrix(int prix) {
    if (prix >= 1000000) {
      return '${(prix / 1000000).toStringAsFixed(1)}M F';
    } else if (prix >= 1000) {
      return '${(prix / 1000).toStringAsFixed(0)}k F';
    }
    return '$prix F';
  }

  @override
  void dispose() {
    _rechercheCtrl.dispose();
    _vocal.stop();
    super.dispose();
  }
}