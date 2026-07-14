import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_theme.dart';
import '../../utils/pays_data.dart';
import '../../services/vocal_service.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../main.dart';

// ── TRADUCTIONS ───────────────────────────────────────
const Map<String, Map<String, String>> _tr = {
  'fr': {
    'titre': 'Catalogue',
    'rechercher': 'Rechercher un produit...',
    'aucun': 'Aucun produit trouvé',
    'populaire': 'Populaire',
    'livraison': 'Livraison',
    'creer_tontine': 'Créer une tontine pour ce produit',
    'fournisseur': 'Fournisseur',
    'commercant': 'Commerçant',
    'livraison_dispo': '🚚 Livraison disponible',
    'contact': 'Contacter',
    'tout': 'Tout',
    'vocal': 'Catalogue de produits. Choisissez un article pour créer une tontine.',
    'produits': 'produits',
    'voir_commercant': 'Voir le commerçant',
    'tontine_liee': 'Tontine liée',
    'rejoindre': 'Rejoindre la tontine',
    'nouveau': 'Nouveau',
    'prix_par_mois': 'par cotisation',
    'nbr_membres': 'membres requis',
    'commercants': 'Commerçants',
    'tous_produits': 'Tous les produits',
    'aucun_commercant': 'Aucun commerçant trouvé',
    'verifie': '✓ Vérifié',
    'partager': 'Partager',
  },
  'en': {
    'titre': 'Catalogue',
    'rechercher': 'Search a product...',
    'aucun': 'No product found',
    'populaire': 'Popular',
    'livraison': 'Delivery',
    'creer_tontine': 'Create a tontine for this product',
    'fournisseur': 'Supplier',
    'commercant': 'Merchant',
    'livraison_dispo': '🚚 Delivery available',
    'contact': 'Contact',
    'tout': 'All',
    'vocal': 'Product catalogue. Choose an item to create a tontine.',
    'produits': 'products',
    'voir_commercant': 'View merchant',
    'tontine_liee': 'Linked tontine',
    'rejoindre': 'Join tontine',
    'nouveau': 'New',
    'prix_par_mois': 'per contribution',
    'nbr_membres': 'members required',
    'commercants': 'Merchants',
    'tous_produits': 'All products',
    'aucun_commercant': 'No merchant found',
    'verifie': '✓ Verified',
    'partager': 'Share',
  },
  'mos': {
    'titre': 'Katalɔg',
    'rechercher': 'Bʋgs bũmb...',
    'aucun': 'Bũmb ka be ye',
    'populaire': 'Waoogã',
    'livraison': 'Kõ-rʋʋg',
    'creer_tontine': 'Bʋg tontine bũmb kãng yĩnga',
    'fournisseur': 'Neb rãmba',
    'commercant': 'Toeeg-ned',
    'livraison_dispo': '🚚 Kõ-rʋʋg bee',
    'contact': 'Kõ-taas',
    'tout': 'Fãa',
    'vocal': 'Katalɔg. Paam bũmb n bʋg tontine.',
    'produits': 'bũm-dãmba',
    'voir_commercant': 'Ges toeeg-ned',
    'tontine_liee': 'Tontine sẽgame',
    'rejoindre': 'Zãgs tontine',
    'nouveau': 'Paalg',
    'prix_par_mois': 'kõ fãa',
    'nbr_membres': 'neb tõnd',
    'commercants': 'Toeeg-neba',
    'tous_produits': 'Bũm-dãmba fãa',
    'aucun_commercant': 'Toeeg-ned ka be',
    'verifie': '✓ Sɩngsame',
    'partager': 'Wilg',
  },
  'bm': {
    'titre': 'Katalogi',
    'rechercher': 'Fɛn ɲini...',
    'aucun': 'Fɛn si sɔrɔla',
    'populaire': 'Caman b\'a fɛ',
    'livraison': 'Nali',
    'creer_tontine': 'Tontine daminɛ fɛn in na',
    'fournisseur': 'Jarabara',
    'commercant': 'Jarabarakɛla',
    'livraison_dispo': '🚚 Nali be yen',
    'contact': 'Bi kunbɛn',
    'tout': 'Bɛɛ',
    'vocal': 'Katalogi. Fɛn sugandi ka tontine daminɛ.',
    'produits': 'fɛnw',
    'voir_commercant': 'Jarabarakɛla ye',
    'tontine_liee': 'Tontine jɛnsɛgɛlen',
    'rejoindre': 'Tontine don',
    'nouveau': 'Kura',
    'prix_par_mois': 'sara o sara',
    'nbr_membres': 'mɔgɔ ɲɛnabɔ',
    'commercants': 'Jarabarakɛlaw',
    'tous_produits': 'Fɛnw bɛɛ',
    'aucun_commercant': 'Jarabarakɛla si sɔrɔla',
    'verifie': '✓ Sɛbɛnna',
    'partager': 'Labɛn',
  },
  'wo': {
    'titre': 'Katalog',
    'rechercher': 'Seet ay jëf...',
    'aucun': 'Dara amul',
    'populaire': 'Waaw waaw',
    'livraison': 'Yóbbale',
    'creer_tontine': 'Def tontine bi pour jëf bii',
    'fournisseur': 'Jëndkat',
    'commercant': 'Jaay-jaaykat',
    'livraison_dispo': '🚚 Yóbbale am na',
    'contact': 'Jokkoo',
    'tout': 'Yëpp',
    'vocal': 'Katalog. Tann ay jëf ngir def tontine.',
    'produits': 'jëf yi',
    'voir_commercant': 'Xool jaay-jaaykat bi',
    'tontine_liee': 'Tontine jëkël',
    'rejoindre': 'Dugg tontine bi',
    'nouveau': 'Bu bees',
    'prix_par_mois': 'cotisation o cotisation',
    'nbr_membres': 'nit waajib',
    'commercants': 'Jaay-jaaykat yi',
    'tous_produits': 'Jëf yi yëpp',
    'aucun_commercant': 'Jaay-jaaykat amul',
    'verifie': '✓ Dëgër na',
    'partager': 'Yëgël',
  },
};

String _t(String langue, String key) {
  final lang = _tr[langue] ?? _tr['fr']!;
  return lang[key] ?? _tr['fr']![key] ?? key;
}

// ── PROVIDERS ──────────────────────────────────────────
final catalogueProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    return await ApiService.getCatalogue();
  } catch (e) {
    return [];
  }
});

final commercantsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    return await ApiService.getCommercants();
  } catch (e) {
    return [];
  }
});

class CatalogueScreen extends ConsumerStatefulWidget {
  const CatalogueScreen({super.key});

  @override
  ConsumerState<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends ConsumerState<CatalogueScreen>
    with SingleTickerProviderStateMixin {
  final VocalService _vocal = VocalService();
  String _categorieSelectionnee = 'tous';
  final _rechercheCtrl = TextEditingController();
  late TabController _tabController;

  // ── PRODUITS LOCAUX FALLBACK ───────────────────────
  final List<Map<String, dynamic>> _produitsLocaux = [
    {'id':'1','nom':'Frigo Samsung 250L','categorie':'electromenager','prix':150000,'emoji':'❄️','fournisseur':'Electroplus','livraison':true,'populaire':true},
    {'id':'2','nom':'Télévision 43 pouces','categorie':'electromenager','prix':120000,'emoji':'📺','fournisseur':'TechStore','livraison':true,'populaire':false},
    {'id':'3','nom':'Climatiseur 1.5 CV','categorie':'electromenager','prix':250000,'emoji':'🌀','fournisseur':'Froid Express','livraison':true,'populaire':false},
    {'id':'4','nom':'Machine à laver','categorie':'electromenager','prix':180000,'emoji':'🫧','fournisseur':'Electroplus','livraison':true,'populaire':false},
    {'id':'5','nom':'Salon complet 7 places','categorie':'meubles','prix':200000,'emoji':'🛋️','fournisseur':'Meubles Prestige','livraison':true,'populaire':true},
    {'id':'6','nom':'Lit + matelas 160x200','categorie':'meubles','prix':80000,'emoji':'🛏️','fournisseur':'Meubles Prestige','livraison':true,'populaire':false},
    {'id':'7','nom':'Ensemble cuisine','categorie':'cuisine','prix':60000,'emoji':'🍳','fournisseur':'Marché Central','livraison':false,'populaire':true},
    {'id':'8','nom':'Gazinière 4 feux','categorie':'cuisine','prix':45000,'emoji':'🔥','fournisseur':'Gaz Express','livraison':false,'populaire':false},
    {'id':'9','nom':'Ordinateur portable','categorie':'bureau','prix':300000,'emoji':'💻','fournisseur':'TechStore','livraison':true,'populaire':false},
    {'id':'10','nom':'Moto Jakarta 125cc','categorie':'agriculture','prix':500000,'emoji':'🛵','fournisseur':'Moto Plus','livraison':false,'populaire':true},
    {'id':'11','nom':'Téléphone Android','categorie':'bureau','prix':80000,'emoji':'📱','fournisseur':'TechStore','livraison':true,'populaire':true},
    {'id':'12','nom':'Générateur 2KVA','categorie':'electromenager','prix':350000,'emoji':'⚡','fournisseur':'Energy Plus','livraison':true,'populaire':false},
  ];

  // ── COMMERÇANTS LOCAUX FALLBACK ───────────────────
  final List<Map<String, dynamic>> _commercantsLocaux = [
    {'id':'1','nom':'Electroplus BF','categorie':'electromenager','telephone':'+22670000001','adresse':'Ouagadougou, Zone du Bois','livraison_disponible':true,'est_verifie':true,'nb_produits':5},
    {'id':'2','nom':'TechStore Africa','categorie':'informatique','telephone':'+22670000002','adresse':'Ouagadougou, Zogona','livraison_disponible':true,'est_verifie':true,'nb_produits':8},
    {'id':'3','nom':'Meubles Prestige','categorie':'meubles','telephone':'+22670000003','adresse':'Ouagadougou, Gounghin','livraison_disponible':true,'est_verifie':false,'nb_produits':3},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  List<Map<String, dynamic>> _getCategories(String langue) => [
    {'code': 'tous', 'label': _t(langue, 'tout'), 'emoji': '🛍️'},
    {'code': 'electromenager', 'label': langue == 'en' ? 'Appliances' : 'Électroménager', 'emoji': '❄️'},
    {'code': 'meubles', 'label': langue == 'en' ? 'Furniture' : 'Meubles', 'emoji': '🛋️'},
    {'code': 'cuisine', 'label': langue == 'en' ? 'Kitchen' : 'Cuisine', 'emoji': '🍳'},
    {'code': 'bureau', 'label': langue == 'en' ? 'Office' : 'Bureau', 'emoji': '💻'},
    {'code': 'agriculture', 'label': 'Agriculture', 'emoji': '🌾'},
    {'code': 'sante', 'label': langue == 'en' ? 'Health' : 'Santé', 'emoji': '🏥'},
    {'code': 'transport', 'label': 'Transport', 'emoji': '🚗'},
  ];

  List<Map<String, dynamic>> _filtrer(List<Map<String, dynamic>> produits) {
    return produits.where((p) {
      final catOk = _categorieSelectionnee == 'tous' ||
          p['categorie'] == _categorieSelectionnee;
      final rechOk = _rechercheCtrl.text.isEmpty ||
          (p['nom']?.toString().toLowerCase() ?? '')
              .contains(_rechercheCtrl.text.toLowerCase()) ||
          (p['fournisseur']?.toString().toLowerCase() ?? '')
              .contains(_rechercheCtrl.text.toLowerCase());
      return catOk && rechOk;
    }).toList();
  }

  void _voirProduit(BuildContext context, Map<String, dynamic> produit, String langue) {
    _vocal.parler('${produit['nom']}. ${_formatPrix(_parseInt(produit['prix']))}');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildDetailProduit(produit, langue),
    );
  }

  void _voirCommercant(Map<String, dynamic> commercant, String langue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildDetailCommercant(commercant, langue),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langue = ref.watch(langueProvider);
    final sw = MediaQuery.of(context).size.width;
    final isSmall = sw < 360;

    return Scaffold(
      backgroundColor: AppTheme.fond,
      appBar: AppBar(
        backgroundColor: AppTheme.vert,
        foregroundColor: Colors.white,
        title: Text(
          _t(langue, 'titre'),
          style: TextStyle(
            fontFamily: 'Nunito',
            color: Colors.white,
            fontSize: isSmall ? 16 : 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded, color: Colors.white70),
            onPressed: () => _vocal.parler(_t(langue, 'vocal')),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () {
              ref.refresh(catalogueProvider);
              ref.refresh(commercantsProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
            fontSize: isSmall ? 12 : 13,
          ),
          tabs: [
            Tab(text: _t(langue, 'tous_produits')),
            Tab(text: _t(langue, 'commercants')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── ONGLET PRODUITS ─────────────────────────
          _buildOngletProduits(langue, isSmall),
          // ── ONGLET COMMERÇANTS ──────────────────────
          _buildOngletCommercants(langue, isSmall),
        ],
      ),
    );
  }

  // ── ONGLET PRODUITS ───────────────────────────────────
  Widget _buildOngletProduits(String langue, bool isSmall) {
    final catalogueAsync = ref.watch(catalogueProvider);

    return Column(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              '${produits.length} ${_t(langue, 'produits')}',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                color: AppTheme.grisTexte,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: isSmall ? 0.62 : 0.70,
              ),
              itemCount: produits.length,
              itemBuilder: (ctx, i) =>
                  _buildCarteProduit(produits[i], langue, isSmall),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarteProduit(Map<String, dynamic> produit,
      String langue, bool isSmall) {
    final emoji = produit['emoji'] ?? produit['image_url'] ?? '📦';
    final estEmoji = emoji.length <= 4;
    final prix = _parseInt(produit['prix']);
    final estNouveau = produit['nouveau'] == true;
    final estPopulaire = produit['populaire'] == true;
    final aLivraison = produit['livraison'] == true ||
        produit['livraison_disponible'] == true;

    return GestureDetector(
      onTap: () => _voirProduit(context, produit, langue),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8E8E5), width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
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
                  decoration: const BoxDecoration(
                    color: AppTheme.vertClair,
                    borderRadius: BorderRadius.vertical(
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
                              width: double.infinity,
                              errorBuilder: (_, __, ___) => const Text(
                                  '📦',
                                  style: TextStyle(fontSize: 48)),
                            ),
                          ),
                  ),
                ),
                if (estPopulaire || estNouveau)
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: estNouveau
                            ? const Color(0xFF9B59B6)
                            : AppTheme.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        estNouveau
                            ? _t(langue, 'nouveau')
                            : _t(langue, 'populaire'),
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: isSmall ? 9 : 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                if (aLivraison)
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.delivery_dining,
                          size: 14, color: AppTheme.vert),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(isSmall ? 8 : 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      produit['nom'] ?? '',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: isSmall ? 11 : 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.texte,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatPrix(prix),
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: isSmall ? 13 : 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.vert,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.store_outlined,
                                size: 10, color: AppTheme.grisTexte),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                produit['fournisseur'] ??
                                    produit['fournisseur_nom'] ?? '',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: isSmall ? 9 : 10,
                                  color: AppTheme.grisTexte,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── ONGLET COMMERÇANTS ────────────────────────────────
  Widget _buildOngletCommercants(String langue, bool isSmall) {
    final commercantsAsync = ref.watch(commercantsProvider);

    return commercantsAsync.when(
      data: (data) {
        final commercants = data.isEmpty ? _commercantsLocaux : data;
        return _buildListeCommercants(commercants, langue, isSmall);
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.vert)),
      error: (_, __) =>
          _buildListeCommercants(_commercantsLocaux, langue, isSmall),
    );
  }

  Widget _buildListeCommercants(List<Map<String, dynamic>> commercants,
      String langue, bool isSmall) {
    if (commercants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏪', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              _t(langue, 'aucun_commercant'),
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
      onRefresh: () => ref.refresh(commercantsProvider.future),
      child: ListView.builder(
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        itemCount: commercants.length,
        itemBuilder: (ctx, i) =>
            _buildCarteCommercant(commercants[i], langue, isSmall),
      ),
    );
  }

  Widget _buildCarteCommercant(Map<String, dynamic> commercant,
      String langue, bool isSmall) {
    final estVerifie = commercant['est_verifie'] == true;
    final nbProduits = commercant['nb_produits'] ?? 0;
    final aLivraison = commercant['livraison_disponible'] == true;

    final categEmoji = {
      'electromenager': '❄️',
      'informatique': '💻',
      'meubles': '🛋️',
      'cuisine': '🍳',
      'agriculture': '🌾',
      'alimentation': '🍎',
      'transport': '🚗',
      'general': '🏪',
    };
    final emoji = categEmoji[commercant['categorie']] ?? '🏪';

    return GestureDetector(
      onTap: () => _voirCommercant(commercant, langue),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: estVerifie
                ? AppTheme.vert.withOpacity(0.3)
                : const Color(0xFFE8E8E5),
            width: estVerifie ? 1.5 : 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: isSmall ? 50 : 60,
              height: isSmall ? 50 : 60,
              decoration: BoxDecoration(
                color: AppTheme.vertClair,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(emoji,
                    style: TextStyle(fontSize: isSmall ? 24 : 28)),
              ),
            ),
            SizedBox(width: isSmall ? 10 : 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          commercant['nom'] ?? '',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: isSmall ? 13 : 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.texte,
                          ),
                        ),
                      ),
                      if (estVerifie)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.vertClair,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _t(langue, 'verifie'),
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: isSmall ? 9 : 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.vert,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (commercant['adresse'] != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: AppTheme.grisTexte),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            commercant['adresse'],
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: isSmall ? 10 : 11,
                              color: AppTheme.grisTexte,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.grisClair,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '📦 $nbProduits ${_t(langue, 'produits')}',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: isSmall ? 9 : 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.grisTexte,
                          ),
                        ),
                      ),
                      if (aLivraison) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.vertClair,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '🚚 ${_t(langue, 'livraison')}',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: isSmall ? 9 : 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.vertFonce,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppTheme.grisTexte, size: 20),
          ],
        ),
      ),
    );
  }

  // ── DETAIL PRODUIT ────────────────────────────────────
  Widget _buildDetailProduit(Map<String, dynamic> produit, String langue) {
    final emoji = produit['emoji'] ?? produit['image_url'] ?? '📦';
    final estEmoji = emoji.length <= 4;
    final prix = _parseInt(produit['prix']);
    final aLivraison = produit['livraison'] == true ||
        produit['livraison_disponible'] == true;
    final tontineId = produit['tontine_id']?.toString();

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
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          // Image / emoji
          Center(
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: AppTheme.vertClair,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: estEmoji
                    ? Text(emoji, style: const TextStyle(fontSize: 56))
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(emoji,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Text('📦',
                                    style: TextStyle(fontSize: 56))),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Nom + Prix
          Text(
            produit['nom'] ?? '',
            style: const TextStyle(
              fontFamily: 'Nunito', fontSize: 20,
              fontWeight: FontWeight.w800, color: AppTheme.texte,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatPrix(prix),
            style: const TextStyle(
              fontFamily: 'Nunito', fontSize: 26,
              fontWeight: FontWeight.w800, color: AppTheme.vert,
            ),
          ),
          const SizedBox(height: 14),
          // Infos
          _buildInfoLigne(
            Icons.store_outlined,
            '${_t(langue, 'fournisseur')}: ${produit['fournisseur'] ?? produit['fournisseur_nom'] ?? '—'}',
          ),
          if (aLivraison)
            _buildInfoLigne(
              Icons.delivery_dining,
              _t(langue, 'livraison_dispo'),
              couleur: AppTheme.vert,
            ),
          if (produit['description'] != null &&
              produit['description'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              produit['description'],
              style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 13,
                color: AppTheme.grisTexte, height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Tontine liée si existe
          if (tontineId != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.vertClair,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('💰', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t(langue, 'tontine_liee'),
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 11,
                            color: AppTheme.grisTexte,
                          ),
                        ),
                        Text(
                          produit['tontine_nom'] ?? 'Tontine disponible',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.vertFonce,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/tontine/$tontineId');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    child: Text(
                      _t(langue, 'rejoindre'),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Bouton créer tontine
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.push('/tontine/creer', extra: produit);
              },
              icon: const Icon(Icons.group_add_outlined),
              label: Text(_t(langue, 'creer_tontine')),
            ),
          ),
          const SizedBox(height: 8),

          // Bouton contacter fournisseur
          if (produit['fournisseur_contact'] != null ||
              produit['telephone'] != null)
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Appel téléphonique
                },
                icon: const Icon(Icons.phone_outlined,
                    color: AppTheme.vert),
                label: Text(
                  _t(langue, 'contact'),
                  style: const TextStyle(color: AppTheme.vert),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.vert),
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── DETAIL COMMERÇANT ─────────────────────────────────
  Widget _buildDetailCommercant(
      Map<String, dynamic> commercant, String langue) {
    final estVerifie = commercant['est_verifie'] == true;
    final nbProduits = commercant['nb_produits'] ?? 0;
    final aLivraison = commercant['livraison_disponible'] == true;
    final categEmoji = {
      'electromenager': '❄️',
      'informatique': '💻',
      'meubles': '🛋️',
      'cuisine': '🍳',
      'agriculture': '🌾',
      'alimentation': '🍎',
      'transport': '🚗',
    };
    final emoji = categEmoji[commercant['categorie']] ?? '🏪';

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
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          // Header
          Row(
            children: [
              Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  color: AppTheme.vertClair,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(emoji,
                      style: const TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            commercant['nom'] ?? '',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.texte,
                            ),
                          ),
                        ),
                        if (estVerifie)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.vertClair,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _t(langue, 'verifie'),
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.vert,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      commercant['categorie'] ?? '',
                      style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          color: AppTheme.grisTexte),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          // Infos
          if (commercant['adresse'] != null)
            _buildInfoLigne(
                Icons.location_on_outlined, commercant['adresse']),
          if (commercant['telephone'] != null)
            _buildInfoLigne(
                Icons.phone_outlined, commercant['telephone']),
          if (commercant['email'] != null)
            _buildInfoLigne(Icons.email_outlined, commercant['email']),
          if (aLivraison)
            _buildInfoLigne(
              Icons.delivery_dining,
              _t(langue, 'livraison_dispo'),
              couleur: AppTheme.vert,
            ),
          if (commercant['description'] != null) ...[
            const SizedBox(height: 8),
            Text(
              commercant['description'],
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: AppTheme.grisTexte,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Stats
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.vertClair,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$nbProduits',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.vert,
                        ),
                      ),
                      Text(
                        _t(langue, 'produits'),
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11,
                          color: AppTheme.grisTexte,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: aLivraison
                        ? AppTheme.vertClair
                        : AppTheme.grisClair,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        aLivraison ? '✅' : '❌',
                        style: const TextStyle(fontSize: 22),
                      ),
                      Text(
                        _t(langue, 'livraison'),
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11,
                          color: AppTheme.grisTexte,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bouton contacter
          if (commercant['telephone'] != null)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.phone_outlined),
                label: Text(_t(langue, 'contact')),
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.push('/tontine/creer');
              },
              icon: const Icon(Icons.group_add_outlined,
                  color: AppTheme.vert),
              label: Text(
                _t(langue, 'creer_tontine'),
                style: const TextStyle(color: AppTheme.vert),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.vert),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoLigne(IconData icon, String texte,
      {Color? couleur}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: couleur ?? AppTheme.grisTexte),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texte,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: couleur ?? AppTheme.grisTexte,
                fontWeight: couleur != null
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
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
        childAspectRatio: 0.70,
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
              decoration: const BoxDecoration(
                color: AppTheme.grisClair,
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _parseInt(dynamic val) {
    if (val is int) return val;
    if (val is double) return val.toInt();
    return int.tryParse(val?.toString() ?? '0') ?? 0;
  }

  String _formatPrix(int prix) {
    if (prix >= 1000000) return '${(prix/1000000).toStringAsFixed(1)}M F';
    if (prix >= 1000) return '${(prix/1000).toStringAsFixed(0)}k F';
    return '$prix F';
  }

  @override
  void dispose() {
    _rechercheCtrl.dispose();
    _tabController.dispose();
    _vocal.stop();
    super.dispose();
  }
}
