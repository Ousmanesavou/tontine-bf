import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_theme.dart';
import '../../services/vocal_service.dart';

class CatalogueScreen extends StatefulWidget {
  const CatalogueScreen({super.key});

  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  final VocalService _vocal = VocalService();
  String _categorieSelectionnee = 'tous';
  final _rechercheCtrl = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {'code': 'tous', 'label': 'Tout', 'emoji': '🛍️'},
    {'code': 'electromenager', 'label': 'Électroménager', 'emoji': '❄️'},
    {'code': 'meubles', 'label': 'Meubles', 'emoji': '🛋️'},
    {'code': 'cuisine', 'label': 'Cuisine', 'emoji': '🍳'},
    {'code': 'bureau', 'label': 'Bureau', 'emoji': '💻'},
    {'code': 'habits', 'label': 'Habits', 'emoji': '👗'},
    {'code': 'agriculture', 'label': 'Agriculture', 'emoji': '🌾'},
  ];

  final List<Map<String, dynamic>> _produits = [
    {
      'nom': 'Frigo Samsung 250L',
      'categorie': 'electromenager',
      'prix': 150000,
      'emoji': '❄️',
      'fournisseur': 'Electroplus Ouaga',
      'livraison': true,
      'populaire': true,
    },
    {
      'nom': 'Télévision 43 pouces',
      'categorie': 'electromenager',
      'prix': 120000,
      'emoji': '📺',
      'fournisseur': 'TechStore BF',
      'livraison': true,
      'populaire': false,
    },
    {
      'nom': 'Climatiseur 1.5 CV',
      'categorie': 'electromenager',
      'prix': 250000,
      'emoji': '🌀',
      'fournisseur': 'Froid Express',
      'livraison': true,
      'populaire': false,
    },
    {
      'nom': 'Machine à laver',
      'categorie': 'electromenager',
      'prix': 180000,
      'emoji': '🫧',
      'fournisseur': 'Electroplus Ouaga',
      'livraison': true,
      'populaire': false,
    },
    {
      'nom': 'Salon complet 7 places',
      'categorie': 'meubles',
      'prix': 200000,
      'emoji': '🛋️',
      'fournisseur': 'Meubles Prestige',
      'livraison': true,
      'populaire': true,
    },
    {
      'nom': 'Lit + matelas 160x200',
      'categorie': 'meubles',
      'prix': 80000,
      'emoji': '🛏️',
      'fournisseur': 'Meubles Prestige',
      'livraison': true,
      'populaire': false,
    },
    {
      'nom': 'Ensemble cuisine complet',
      'categorie': 'cuisine',
      'prix': 60000,
      'emoji': '🍳',
      'fournisseur': 'Marché Rood Woko',
      'livraison': false,
      'populaire': true,
    },
    {
      'nom': 'Gazinière 4 feux',
      'categorie': 'cuisine',
      'prix': 45000,
      'emoji': '🔥',
      'fournisseur': 'Gaz BF',
      'livraison': false,
      'populaire': false,
    },
    {
      'nom': 'Ordinateur portable',
      'categorie': 'bureau',
      'prix': 300000,
      'emoji': '💻',
      'fournisseur': 'TechStore BF',
      'livraison': true,
      'populaire': false,
    },
    {
      'nom': 'Moto Jakarta 125cc',
      'categorie': 'agriculture',
      'prix': 500000,
      'emoji': '🛵',
      'fournisseur': 'Moto Plus Ouaga',
      'livraison': false,
      'populaire': true,
    },
  ];

  List<Map<String, dynamic>> get _produitsFiltres {
    return _produits.where((p) {
      final categorieOk = _categorieSelectionnee == 'tous' ||
          p['categorie'] == _categorieSelectionnee;
      final rechercheOk = _rechercheCtrl.text.isEmpty ||
          p['nom'].toString().toLowerCase().contains(
              _rechercheCtrl.text.toLowerCase());
      return categorieOk && rechercheOk;
    }).toList();
  }

  void _voirProduit(Map<String, dynamic> produit) {
    _vocal.parler(
        '${produit['nom']}. Prix : ${_formatPrix(produit['prix'])} francs CFA.');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildDetailProduit(produit),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fond,
      appBar: AppBar(
        backgroundColor: AppTheme.vert,
        foregroundColor: Colors.white,
        title: const Text('Catalogue',
            style: TextStyle(fontFamily: 'Nunito', color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded, color: Colors.white70),
            onPressed: () => _vocal.parler(
                'Catalogue de produits. Choisissez un article pour créer une tontine.'),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildRecherche(),
          _buildCategories(),
          Expanded(child: _buildGrilleProduits()),
        ],
      ),
    );
  }

  Widget _buildRecherche() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _rechercheCtrl,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Rechercher un produit...',
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

  Widget _buildCategories() {
    return Container(
      color: Colors.white,
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _categories.length,
        itemBuilder: (ctx, i) {
          final cat = _categories[i];
          final selected = _categorieSelectionnee == cat['code'];
          return GestureDetector(
            onTap: () => setState(() => _categorieSelectionnee = cat['code']),
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
                  Text(cat['emoji'], style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(cat['label'],
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppTheme.texte,
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrilleProduits() {
    final produits = _produitsFiltres;
    if (produits.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🔍', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('Aucun produit trouvé',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    color: AppTheme.grisTexte)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.75,
      ),
      itemCount: produits.length,
      itemBuilder: (ctx, i) => _buildCarteProduit(produits[i]),
    );
  }

  Widget _buildCarteProduit(Map<String, dynamic> produit) {
    return GestureDetector(
      onTap: () => _voirProduit(produit),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8E8E5), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.vertClair,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16)),
                  ),
                  child: Center(
                    child: Text(produit['emoji'],
                        style: const TextStyle(fontSize: 48)),
                  ),
                ),
                if (produit['populaire'] == true)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('Populaire',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          )),
                    ),
                  ),
                if (produit['livraison'] == true)
                  Positioned(
                    top: 8,
                    right: 8,
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
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(produit['nom'],
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.texte,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(_formatPrix(produit['prix']),
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.vert,
                      )),
                  const SizedBox(height: 4),
                  Text(produit['fournisseur'],
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 10,
                        color: AppTheme.grisTexte,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailProduit(Map<String, dynamic> produit) {
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
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.grisClair,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(produit['emoji'],
                style: const TextStyle(fontSize: 64)),
          ),
          const SizedBox(height: 16),
          Text(produit['nom'],
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.texte,
              )),
          const SizedBox(height: 4),
          Text(_formatPrix(produit['prix']),
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.vert,
              )),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.store_outlined,
                  size: 16, color: AppTheme.grisTexte),
              const SizedBox(width: 6),
              Text(produit['fournisseur'],
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      color: AppTheme.grisTexte)),
              const Spacer(),
              if (produit['livraison'] == true)
                Row(
                  children: const [
                    Icon(Icons.delivery_dining,
                        size: 16, color: AppTheme.vert),
                    SizedBox(width: 4),
                    Text('Livraison disponible',
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            color: AppTheme.vert)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              context.push('/tontine/creer');
            },
            icon: const Icon(Icons.group_add_outlined),
            label: const Text('Créer une tontine pour ce produit'),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  String _formatPrix(int prix) {
    if (prix >= 1000000) {
      return '${(prix / 1000000).toStringAsFixed(1)}M F CFA';
    } else if (prix >= 1000) {
      return '${(prix / 1000).toStringAsFixed(0)}k F CFA';
    }
    return '$prix F CFA';
  }

  @override
  void dispose() {
    _rechercheCtrl.dispose();
    _vocal.stop();
    super.dispose();
  }
}