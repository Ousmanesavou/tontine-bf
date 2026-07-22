import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/vocal_service.dart';
import '../../services/storage_service.dart';
import '../../main.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../../utils/pays_data.dart';
import '../../services/storage_service.dart';
const Map<String, Map<String, String>> _tr = {
  'fr': {
    'prochain_tour': 'Prochain tour',
    'progression': 'Progression',
    'membres': 'Membres',
    'cotisations': 'Cotisations',
    'infos': 'Informations',
    'sur': 'sur',
    'ont_recu': 'membres ont reçu',
    'prochain': 'Prochain',
    'tour': 'Tour',
    'payer': 'Payer',
    'paye': 'Payé',
    'deposer': 'Déposer',
    'a_jour': 'Cotisations à jour ✅',
    'en_retard': 'En retard',
    'due_dans': 'Due dans',
    'jour': 'jour',
    'jours': 'jours',
    'date_debut': 'Date de début',
    'date_fin': 'Date de fin',
    'periodicite': 'Périodicité',
    'montant': 'Montant cotisation',
    'type': 'Type',
    'statut': 'Statut',
    'actif': 'Actif',
    'termine': 'Terminé',
    'en_attente': 'En attente',
    'responsable': 'Responsable',
    'description': 'Description',
    'non_trouve': 'Tontine non trouvée',
    'vocal_detail': 'Tontine',
    'membres_recu': 'ont reçu leur tour',
    'par_jour': 'par jour',
    'par_semaine': 'par semaine',
    'par_mois': 'par mois',
    'par_2j': 'tous les 2 jours',
    'par_2sem': 'toutes les 2 semaines',
    'par_trim': 'par trimestre',
    'score': 'Fiabilité',
    'aucune_cotisation': 'Aucune cotisation',
    'rejoindre': 'Rejoindre cette tontine',
    'demande_envoyee': 'Demande envoyée !',
    'compte_virtuel': 'Compte virtuel',
    'solde': 'Solde',
    'pas_membre': 'Vous n\'êtes pas membre',
    'complet': 'Groupe complet',
    'total_membres': 'Total membres',
    'inviter_membre': 'Inviter un membre',
    'telephone': 'Numéro de téléphone',
    'envoyer': 'Envoyer l\'invitation',
    'annuler': 'Annuler',
    'periode': 'Période',
    'moi': 'Moi',
    'historique_cotisations': 'Historique des cotisations',
    'taux_paiement': 'Taux de paiement',
    'partager': 'Partager',
    'partager_msg': 'Rejoins ma tontine "{nom}" sur TontiLigdi ! 🌍\nLagem Ligdi\nhttps://tontiligdi.toeegdigital.com',
  },
  'en': {
    'prochain_tour': 'Next round',
    'progression': 'Progress',
    'membres': 'Members',
    'cotisations': 'Contributions',
    'infos': 'Information',
    'sur': 'of',
    'ont_recu': 'members received',
    'prochain': 'Next',
    'tour': 'Round',
    'payer': 'Pay',
    'paye': 'Paid',
    'deposer': 'Deposit',
    'a_jour': 'Up to date ✅',
    'en_retard': 'Late',
    'due_dans': 'Due in',
    'jour': 'day',
    'jours': 'days',
    'date_debut': 'Start date',
    'date_fin': 'End date',
    'periodicite': 'Frequency',
    'montant': 'Amount',
    'type': 'Type',
    'statut': 'Status',
    'actif': 'Active',
    'termine': 'Finished',
    'en_attente': 'Pending',
    'responsable': 'Manager',
    'description': 'Description',
    'non_trouve': 'Tontine not found',
    'vocal_detail': 'Tontine',
    'membres_recu': 'have received',
    'par_jour': 'per day',
    'par_semaine': 'per week',
    'par_mois': 'per month',
    'par_2j': 'every 2 days',
    'par_2sem': 'every 2 weeks',
    'par_trim': 'per quarter',
    'score': 'Reliability',
    'aucune_cotisation': 'No contribution',
    'rejoindre': 'Join this tontine',
    'demande_envoyee': 'Request sent!',
    'compte_virtuel': 'Virtual account',
    'solde': 'Balance',
    'pas_membre': 'You are not a member',
    'complet': 'Group full',
    'total_membres': 'Total members',
    'inviter_membre': 'Invite a member',
    'telephone': 'Phone number',
    'envoyer': 'Send invitation',
    'annuler': 'Cancel',
    'periode': 'Period',
    'moi': 'Me',
    'historique_cotisations': 'Contribution history',
    'taux_paiement': 'Payment rate',
    'partager': 'Share',
    'partager_msg': 'Join my tontine "{nom}" on TontiLigdi! 🌍\nLagem Ligdi\nhttps://tontiligdi.toeegdigital.com',
  },
  'mos': {
    'prochain_tour': 'Tɩɩs paalga',
    'progression': 'Zagsem',
    'membres': 'Neb',
    'cotisations': 'Kõ-dãmba',
    'infos': 'Sɩb-rɛɛzã',
    'sur': 'zugu',
    'ont_recu': 'neb paamame',
    'prochain': 'Paalga',
    'tour': 'Tɩɩs',
    'payer': 'Kõ',
    'paye': 'Kõame',
    'deposer': 'Kõ-kẽng',
    'a_jour': 'Sɩda ✅',
    'en_retard': 'Yɩɩr',
    'due_dans': 'Rãmba',
    'jour': 'dãmb',
    'jours': 'dãmba',
    'date_debut': 'Sɩng-dãmba',
    'date_fin': 'Tɩɩm-dãmba',
    'periodicite': 'Kõ-wakatã',
    'montant': 'Ligdi',
    'type': 'Bõne',
    'statut': 'Tɩɩga',
    'actif': 'Bee',
    'termine': 'Tɩɩmame',
    'en_attente': 'Rog-m-tɩɩg',
    'responsable': 'Naab',
    'description': 'Sɩbgrã',
    'non_trouve': 'Tontine ka be ye',
    'vocal_detail': 'Tontine',
    'membres_recu': 'paamame',
    'par_jour': 'dũnni fãa',
    'par_semaine': 'wiki fãa',
    'par_mois': 'kiuugã fãa',
    'par_2j': 'dũnni 2',
    'par_2sem': 'wiki 2',
    'par_trim': 'kiuugu 3',
    'score': 'Kaseto',
    'aucune_cotisation': 'Kõ ka be ye',
    'rejoindre': 'Kẽng tontine',
    'demande_envoyee': 'Kẽngr tõog !',
    'compte_virtuel': 'Compte virtuel',
    'solde': 'Ligdi',
    'pas_membre': 'F ka be neb pʋgẽ',
    'complet': 'Neb pida',
    'total_membres': 'Neb sõore',
    'inviter_membre': 'Bool ned',
    'telephone': 'Telẽfõn',
    'envoyer': 'Tõog bool',
    'annuler': 'Bas',
    'periode': 'Wakatã',
    'moi': 'Mam',
    'historique_cotisations': 'Kõ-dãmba yɛl-tɛɛsã',
    'taux_paiement': 'Kõ kaseto',
    'partager': 'Pʋgd',
    'partager_msg': 'Kẽng m tontine "{nom}" TontiLigdi pʋgẽ ! 🌍\nhttps://tontiligdi.toeegdigital.com',
  },
  'bm': {
    'prochain_tour': 'Yɔrɔ kura',
    'progression': 'Taabolo',
    'membres': 'Mɔgɔw',
    'cotisations': 'Saraliw',
    'infos': 'Kunnafoni',
    'sur': 'kan',
    'ont_recu': 'mɔgɔw sɔrɔla',
    'prochain': 'Kura',
    'tour': 'Yɔrɔ',
    'payer': 'Sara',
    'paye': 'Saranna',
    'deposer': 'Sara don',
    'a_jour': 'Ɲɛ ✅',
    'en_retard': 'Suura',
    'due_dans': 'Tile',
    'jour': 'tile',
    'jours': 'tile',
    'date_debut': 'Daminɛ tile',
    'date_fin': 'Laban tile',
    'periodicite': 'Sara waati',
    'montant': 'Wari',
    'type': 'Sugandi',
    'statut': 'Cogoya',
    'actif': 'Be kɔnɔ',
    'termine': 'Bannana',
    'en_attente': 'Kɔnɔ',
    'responsable': 'Kuntigui',
    'description': 'Fɔtɔ',
    'non_trouve': 'Tontine si sɔrɔla',
    'vocal_detail': 'Tontine',
    'membres_recu': 'ye sɔrɔ',
    'par_jour': 'tile o tile',
    'par_semaine': 'dɔgɔkun kelen',
    'par_mois': 'kalo kelen',
    'par_2j': 'tile fila',
    'par_2sem': 'dɔgɔkun fila',
    'par_trim': 'kalo saba',
    'score': 'Danbe',
    'aucune_cotisation': 'Sara si be yen',
    'rejoindre': 'Tontine don',
    'demande_envoyee': 'Daali tɔgɔlen !',
    'compte_virtuel': 'Compte virtuel',
    'solde': 'Wari',
    'pas_membre': 'I tε mɔgɔw la',
    'complet': 'Mɔgɔw bɛ yen',
    'total_membres': 'Mɔgɔ hakɛ',
    'inviter_membre': 'Mɔgɔ wele',
    'telephone': 'Telefɔni',
    'envoyer': 'Ci',
    'annuler': 'Dabila',
    'periode': 'Waati',
    'moi': 'Ne',
    'historique_cotisations': 'Saraliw kunnafoni',
    'taux_paiement': 'Sara danbe',
    'partager': 'Labɛn',
    'partager_msg': 'Don n ka tontine "{nom}" TontiLigdi la ! 🌍\nhttps://tontiligdi.toeegdigital.com',
  },
  'wo': {
    'prochain_tour': 'Yoon bu bees',
    'progression': 'Xam-xam',
    'membres': 'Nit yi',
    'cotisations': 'Cotisations yi',
    'infos': 'Xam-xam',
    'sur': 'ci',
    'ont_recu': 'nit yi jotoon',
    'prochain': 'Bu bees',
    'tour': 'Yoon',
    'payer': 'Fay',
    'paye': 'Fayoon',
    'deposer': 'Dëkk xaalis',
    'a_jour': 'Siiw ✅',
    'en_retard': 'Suura',
    'due_dans': 'Ci fan',
    'jour': 'fan',
    'jours': 'fan',
    'date_debut': 'Bët ci kanam',
    'date_fin': 'Bët ci dëkk',
    'periodicite': 'Waxt bu fay',
    'montant': 'Xaalis',
    'type': 'Xam-xam',
    'statut': 'Cogna',
    'actif': 'Am na',
    'termine': 'Jeex na',
    'en_attente': 'Xaaraan',
    'responsable': 'Boroom',
    'description': 'Wandlu',
    'non_trouve': 'Tontine bi amul',
    'vocal_detail': 'Tontine',
    'membres_recu': 'jotoon',
    'par_jour': 'fan bu nekk',
    'par_semaine': 'ayu bu nekk',
    'par_mois': 'weer bu nekk',
    'par_2j': 'fan yu ñaar',
    'par_2sem': 'ayu yu ñaar',
    'par_trim': 'weer yu ñett',
    'score': 'Diggante',
    'aucune_cotisation': 'Cotisation amul',
    'rejoindre': 'Dugg tontine bi',
    'demande_envoyee': 'Dëkk yónnéen !',
    'compte_virtuel': 'Compte virtuel',
    'solde': 'Xaalis',
    'pas_membre': 'Duñ la jënd',
    'complet': 'Donn na',
    'total_membres': 'Nit yu am',
    'inviter_membre': 'Wele nit',
    'telephone': 'Telefon',
    'envoyer': 'Yónnee',
    'annuler': 'Sàcc',
    'periode': 'Waxt',
    'moi': 'Man',
    'historique_cotisations': 'Cotisations yi dëkk',
    'taux_paiement': 'Cotisation rate',
    'partager': 'Yëgël',
    'partager_msg': 'Dugg sama tontine "{nom}" TontiLigdi ! 🌍\nhttps://tontiligdi.toeegdigital.com',
  },
};

String _t(String langue, String key) {
  final lang = _tr[langue] ?? _tr['fr']!;
  return lang[key] ?? _tr['fr']![key] ?? key;
}

class TontineDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const TontineDetailScreen({super.key, required this.id});

  @override
  ConsumerState<TontineDetailScreen> createState() =>
      _TontineDetailScreenState();
}

class _TontineDetailScreenState
    extends ConsumerState<TontineDetailScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _tontine;
  List<Map<String, dynamic>> _cotisations = [];
  bool _chargement = true;
  bool _demandeEnvoyee = false;
  late TabController _tabController;
  final VocalService _vocal = VocalService();
  final _telephoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _charger();
  }

  Future<void> _charger() async {
    try {
      final data = await ApiService.getTontine(widget.id);
      List<Map<String, dynamic>> cots = [];
      try {
        cots = await ApiService.getMesCotisations();
        cots = cots
            .where((c) => c['tontine_id']?.toString() == widget.id)
            .toList();
      } catch (_) {}
      setState(() {
        _tontine = data;
        _cotisations = cots;
        _chargement = false;
      });
    } catch (e) {
      setState(() => _chargement = false);
    }
  }

  bool get _estMembre {
    final user = StorageService.getUser();
    if (user == null || _tontine == null) return false;
    final userId = user['id']?.toString();
    final membres = List<Map<String, dynamic>>.from(
        _tontine!['membres'] as List? ?? []);
    return membres.any((m) => m['id']?.toString() == userId);
  }

  bool get _estResponsable {
    final user = StorageService.getUser();
    if (user == null || _tontine == null) return false;
    return _tontine!['responsable_id']?.toString() ==
        user['id']?.toString();
  }

  Future<void> _demanderAdhesion(String langue) async {
    try {
      await ApiService.demanderAdhesion(widget.id);
      setState(() => _demandeEnvoyee = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_t(langue, 'demande_envoyee')),
          backgroundColor: AppTheme.vert,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.rouge,
        ));
      }
    }
  }

 Future<void> _inviterMembre(String langue) async {
    final paysParDefaut = StorageService.getPays() ?? 'BF';
    Map<String, dynamic> paysChoisi =
        PaysData.getPays(paysParDefaut) ?? PaysData.pays.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text(_t(langue, 'inviter_membre'),
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700)),
          content: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  final resultat = await _choisirPays(context);
                  if (resultat != null) {
                    setDialogState(() => paysChoisi = resultat);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.vertClair,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(paysChoisi['drapeau'] ?? '🌍',
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(paysChoisi['indicatif'] ?? '+226',
                          style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.vertFonce)),
                      const Icon(Icons.arrow_drop_down,
                          size: 18, color: AppTheme.vertFonce),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _telephoneCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  decoration: InputDecoration(
                    hintText: '70 XX XX XX',
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(_t(langue, 'annuler'),
                  style: const TextStyle(
                      color: AppTheme.grisTexte)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_telephoneCtrl.text.length < 6) return;
                final indicatif = paysChoisi['indicatif'] ?? '+226';
                Navigator.pop(ctx);
                try {
                  await ApiService.inviterMembre(
                      widget.id, '$indicatif${_telephoneCtrl.text}');
                  _telephoneCtrl.clear();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invitation envoyée !'),
                        backgroundColor: AppTheme.vert,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: AppTheme.rouge,
                      ),
                    );
                  }
                }
              },
              child: Text(_t(langue, 'envoyer')),
            ),
          ],
        ),
      ),
    );
  }

  // ── SÉLECTEUR DE PAYS (recherche parmi les 65+ pays) ──
  Future<Map<String, dynamic>?> _choisirPays(BuildContext context) {
    String recherche = '';
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final resultats = PaysData.pays.where((p) {
            if (recherche.isEmpty) return true;
            final q = recherche.toLowerCase();
            return (p['nom'] as String).toLowerCase().contains(q) ||
                (p['indicatif'] as String).contains(q);
          }).toList();

          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              height: MediaQuery.of(ctx).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
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
                  const SizedBox(height: 16),
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un pays...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: AppTheme.fond,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) =>
                        setModalState(() => recherche = v),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: resultats.length,
                      itemBuilder: (ctx, i) {
                        final p = resultats[i];
                        return ListTile(
                          leading: Text(p['drapeau'] ?? '🌍',
                              style: const TextStyle(fontSize: 22)),
                          title: Text(p['nom'] ?? '',
                              style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w600)),
                          trailing: Text(p['indicatif'] ?? '',
                              style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  color: AppTheme.grisTexte)),
                          onTap: () => Navigator.pop(ctx, p),
                        );
                      },
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
  Future<void> _partager(String langue) async {
    final nom = _tontine?['nom'] ?? 'TontiLigdi';
    final montant = _tontine?['montant_cotisation']?.toString() ?? '0';
    final membres = ((_tontine?['membres'] as List?)?.length ?? 0).toString();
    final total = _tontine?['nombre_membres']?.toString() ?? '0';
    final message = _t(langue, 'partager_msg').replaceAll('{nom}', nom);
    final whatsappMsg = Uri.encodeComponent('$message\n\n📊 $montant F CFA\n👥 $membres/$total membres');
    final whatsappUrl = Uri.parse('whatsapp://send?text=$whatsappMsg');
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl);
      return;
    }
    final smsUrl = Uri.parse('sms:?body=$whatsappMsg');
    if (await canLaunchUrl(smsUrl)) {
      await launchUrl(smsUrl);
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(': $nom'),
          backgroundColor: AppTheme.vert,
        ),
      );
    }
  }

  String _typeEmoji(String? type) {
    const emojis = {
      'argent_liquide': '💰',
      'objet': '📦',
      'caisse_fixe': '🏦',
      'evenementielle': '🎉',
      'sante': '🏥',
      'education': '🎓',
      'agriculture': '🌾',
      'construction': '🏗️',
      'voyage': '✈️',
      'commerce': '🛒',
    };
    return emojis[type] ?? '💰';
  }

  String _periodiciteLabel(String? p, String langue) {
    switch (p) {
      case 'quotidien':
        return _t(langue, 'par_jour');
      case '2_jours':
        return _t(langue, 'par_2j');
      case 'hebdomadaire':
        return _t(langue, 'par_semaine');
      case '2_semaines':
        return _t(langue, 'par_2sem');
      case 'mensuel':
        return _t(langue, 'par_mois');
      case 'trimestriel':
        return _t(langue, 'par_trim');
      default:
        final jours = _tontine?['periodicite_jours'];
        if (jours != null) return 'tous les $jours jours';
        return p ?? '';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final d = DateTime.parse(dateStr);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final langue = ref.watch(langueProvider);
    final sw = MediaQuery.of(context).size.width;
    final isSmall = sw < 360;

    if (_chargement) {
      return const Scaffold(
          body: Center(
              child:
                  CircularProgressIndicator(color: AppTheme.vert)));
    }

    if (_tontine == null) {
      return Scaffold(
        appBar: AppBar(
            backgroundColor: AppTheme.vert,
            foregroundColor: Colors.white,
            title: Text(_t(langue, 'non_trouve'))),
        body: Center(child: Text(_t(langue, 'non_trouve'))),
      );
    }

    final t = _tontine!;
    final membres = List<Map<String, dynamic>>.from(
        t['membres'] as List? ?? []);
    final totalMembres = membres.length;
    final joursRestants = t['jours_restants'] as int? ?? 0;
    final couleur = joursRestants <= 1
        ? AppTheme.rouge
        : joursRestants <= 2
            ? AppTheme.orange
            : AppTheme.vert;
    final imageUrl = t['photo_tontine'] ?? t['image_url'];
    final soldeVirtuel =
        double.tryParse(t['solde_virtuel']?.toString() ?? '0') ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.fond,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, inner) => [
          SliverAppBar(
            expandedHeight: isSmall ? 160 : 200,
            pinned: true,
            backgroundColor: AppTheme.vert,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined,
                    color: Colors.white),
                onPressed: () => _partager(langue),
                tooltip: _t(langue, 'partager'),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up_rounded,
                    color: Colors.white70),
                onPressed: () => _vocal.parler(
                    '${_t(langue, 'vocal_detail')} ${t['nom']}. $totalMembres ${_t(langue, 'membres')}.'),
              ),
              if (_estMembre)
                IconButton(
                  icon: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white),
                  onPressed: () => context
                      .push('/tontine/${widget.id}/compte-virtuel'),
                ),
              if (_estResponsable)
                IconButton(
                  icon: const Icon(Icons.person_add_outlined,
                      color: Colors.white),
                  onPressed: () => _inviterMembre(langue),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 56),
              title: Text(
                t['nom'] ?? '',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: isSmall ? 12 : 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  shadows: const [Shadow(color: Colors.black38, blurRadius: 4)],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: imageUrl != null
                  ? Image.network(imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _buildEmojiHeader(t))
                  : _buildEmojiHeader(t),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              isScrollable: true,
              labelStyle: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
                fontSize: isSmall ? 11 : 13,
              ),
              tabs: [
                Tab(text: _t(langue, 'progression')),
                Tab(text: _t(langue, 'cotisations')),
                Tab(text: _t(langue, 'membres')),
                Tab(text: _t(langue, 'infos')),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOngletProgression(t, membres, totalMembres,
                joursRestants, couleur, langue, isSmall, soldeVirtuel),
            _buildOngletCotisations(langue, isSmall),
            _buildOngletMembres(membres, langue, isSmall),
            _buildOngletInfos(t, langue, isSmall),
          ],
        ),
      ),
      bottomNavigationBar:
          _buildBottomBar(t, langue, isSmall, couleur, soldeVirtuel),
    );
  }

  Widget _buildEmojiHeader(Map t) {
    return Container(
      color: AppTheme.vert,
      child: Center(
          child: Text(_typeEmoji(t['type']),
              style: const TextStyle(fontSize: 72))),
    );
  }

  // ── ONGLET PROGRESSION ────────────────────────────
  Widget _buildOngletProgression(
      Map t,
      List membres,
      int totalMembres,
      int joursRestants,
      Color couleur,
      String langue,
      bool isSmall,
      double soldeVirtuel) {
    final membresRecus =
        membres.where((m) => m['a_recu'] == true).length;
    final pct =
        totalMembres > 0 ? membresRecus / totalMembres : 0.0;

    return RefreshIndicator(
      color: AppTheme.vert,
      onRefresh: _charger,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (soldeVirtuel > 0 && _estMembre)
              GestureDetector(
                onTap: () => context
                    .push('/tontine/${widget.id}/compte-virtuel'),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(isSmall ? 14 : 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.vert, AppTheme.vertFonce],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Colors.white,
                          size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(_t(langue, 'solde'),
                                style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 12,
                                    color: Colors.white70)),
                            Text(
                              '${soldeVirtuel >= 1000 ? '${(soldeVirtuel / 1000).toStringAsFixed(0)}k' : soldeVirtuel.toStringAsFixed(0)} F CFA',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: isSmall ? 20 : 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: Colors.white70),
                    ],
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    '$joursRestants ${joursRestants > 1 ? _t(langue, 'jours') : _t(langue, 'jour')}',
                    _t(langue, 'prochain_tour'),
                    couleur.withOpacity(0.1),
                    couleur,
                    Icons.timer_outlined,
                    isSmall,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    '${t['montant_cotisation']} F',
                    _periodiciteLabel(t['periodicite'], langue),
                    AppTheme.vertClair,
                    AppTheme.vert,
                    Icons.payments_outlined,
                    isSmall,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmall ? 12 : 16),
            Container(
              padding: EdgeInsets.all(isSmall ? 14 : 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFFE8E8E5), width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_t(langue, 'progression'),
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: isSmall ? 13 : 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.texte,
                      )),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircularPercentIndicator(
                        radius: isSmall ? 30 : 40,
                        lineWidth: 6,
                        percent: pct.clamp(0.0, 1.0),
                        center: Text(
                          '${(pct * 100).toInt()}%',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: isSmall ? 11 : 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.vert,
                          ),
                        ),
                        progressColor: AppTheme.vert,
                        backgroundColor: AppTheme.vertClair,
                        circularStrokeCap:
                            CircularStrokeCap.round,
                        animation: true,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$membresRecus ${_t(langue, 'sur')} $totalMembres ${_t(langue, 'ont_recu')}',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: isSmall ? 12 : 13,
                                color: AppTheme.grisTexte,
                              ),
                            ),
                            if (t['prochain_beneficiaire'] !=
                                null) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppTheme.vertClair,
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_t(langue, 'prochain')} : ${t['prochain_beneficiaire']['prenom']} ${t['prochain_beneficiaire']['nom']}',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize:
                                        isSmall ? 11 : 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.vertFonce,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct.clamp(0.0, 1.0),
                      backgroundColor: AppTheme.vertClair,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.vert),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isSmall ? 12 : 16),
            _buildLigneTemps(membres, langue, isSmall),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildLigneTemps(
      List membres, String langue, bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFE8E8E5), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${_t(langue, 'tour')}s',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: isSmall ? 13 : 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.texte,
              )),
          const SizedBox(height: 12),
          ...membres.asMap().entries.map((e) {
            final i = e.key;
            final m = e.value;
            final aRecu = m['a_recu'] == true;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: isSmall ? 28 : 32,
                    height: isSmall ? 28 : 32,
                    decoration: BoxDecoration(
                      color: aRecu
                          ? AppTheme.vert
                          : AppTheme.grisClair,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: aRecu
                          ? Icon(Icons.check,
                              color: Colors.white,
                              size: isSmall ? 14 : 16)
                          : Text(
                              '${m['position_rotation'] ?? i + 1}',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: isSmall ? 10 : 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.grisTexte,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${m['prenom'] ?? ''} ${m['nom'] ?? ''}',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: isSmall ? 12 : 13,
                        fontWeight: aRecu
                            ? FontWeight.w700
                            : FontWeight.normal,
                        color:
                            aRecu ? AppTheme.vert : AppTheme.texte,
                      ),
                    ),
                  ),
                  if (aRecu)
                    const Text('✅',
                        style: TextStyle(fontSize: 16)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── ONGLET COTISATIONS ────────────────────────────
  Widget _buildOngletCotisations(String langue, bool isSmall) {
    if (!_estMembre) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔒', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(_t(langue, 'pas_membre'),
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: AppTheme.grisTexte)),
          ],
        ),
      );
    }

    if (_cotisations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📋', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(_t(langue, 'aucune_cotisation'),
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: AppTheme.grisTexte)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _charger,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualiser'),
            ),
          ],
        ),
      );
    }

    final totalCots = _cotisations.length;
    final payees =
        _cotisations.where((c) => c['statut'] == 'paye').length;
    final enRetard =
        _cotisations.where((c) => c['statut'] == 'en_retard').length;
    final taux = totalCots > 0 ? payees / totalCots : 0.0;

    final periodes = <int, List<Map<String, dynamic>>>{};
    for (final c in _cotisations) {
      final p = c['periode_numero'] as int? ?? 0;
      periodes.putIfAbsent(p, () => []).add(c);
    }
    final periodesSorted = periodes.keys.toList()..sort();

    return RefreshIndicator(
      color: AppTheme.vert,
      onRefresh: _charger,
      child: ListView(
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        children: [
          // Résumé global
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: EdgeInsets.all(isSmall ? 14 : 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.vert, AppTheme.vertFonce],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_t(langue, 'historique_cotisations'),
                    style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: Colors.white70)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                        child: _miniStatBlanche(
                            '$payees/$totalCots',
                            _t(langue, 'paye'),
                            isSmall)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _miniStatBlanche(
                            '$enRetard',
                            _t(langue, 'en_retard'),
                            isSmall)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _miniStatBlanche(
                            '${(taux * 100).toInt()}%',
                            _t(langue, 'taux_paiement'),
                            isSmall)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: taux.clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),

          // Liste par période
          ...periodesSorted.map((periode) {
            final items = periodes[periode]!;
            final toutPayes =
                items.every((c) => c['statut'] == 'paye');
            final nbrPayes =
                items.where((c) => c['statut'] == 'paye').length;
            final userId =
                StorageService.getUser()?['id']?.toString();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: toutPayes
                      ? AppTheme.vert.withOpacity(0.3)
                      : const Color(0xFFE8E8E5),
                  width: toutPayes ? 1.5 : 0.5,
                ),
              ),
              child: Column(
                children: [
                  // En-tête période
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmall ? 12 : 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: toutPayes
                          ? AppTheme.vertClair
                          : AppTheme.grisClair,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          toutPayes
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: toutPayes
                              ? AppTheme.vert
                              : AppTheme.grisTexte,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_t(langue, 'periode')} $periode',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: isSmall ? 13 : 14,
                            fontWeight: FontWeight.w700,
                            color: toutPayes
                                ? AppTheme.vertFonce
                                : AppTheme.texte,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$nbrPayes/${items.length}',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: isSmall ? 11 : 12,
                            fontWeight: FontWeight.w600,
                            color: toutPayes
                                ? AppTheme.vert
                                : AppTheme.grisTexte,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 50,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: items.isEmpty
                                  ? 0
                                  : nbrPayes / items.length,
                              backgroundColor: AppTheme.grisTexte
                                  .withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                toutPayes
                                    ? AppTheme.vert
                                    : AppTheme.orange,
                              ),
                              minHeight: 5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Cotisations de la période
                  ...items.asMap().entries.map((e) {
                    final idx = e.key;
                    final c = e.value;
                    final statut = c['statut'] ?? 'en_attente';
                    final isPaye = statut == 'paye';
                    final isRetard = statut == 'en_retard';
                    final estMoi =
                        c['membre_id']?.toString() == userId;

                    final couleurC = isPaye
                        ? AppTheme.vert
                        : isRetard
                            ? AppTheme.rouge
                            : AppTheme.grisTexte;

                    final icone = isPaye
                        ? Icons.check_circle
                        : isRetard
                            ? Icons.warning_amber_rounded
                            : Icons.radio_button_unchecked;

                    DateTime? dateEch;
                    try {
                      if (c['date_echeance'] != null) {
                        dateEch =
                            DateTime.parse(c['date_echeance']);
                      }
                    } catch (_) {}
                    final joursJ = dateEch != null
                        ? dateEch
                            .difference(DateTime.now())
                            .inDays
                        : 0;

                    return Column(
                      children: [
                        if (idx > 0)
                          const Divider(
                              height: 1,
                              color: Color(0xFFE8E8E5)),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmall ? 12 : 16,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Icon(icone,
                                  color: couleurC,
                                  size: isSmall ? 18 : 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      estMoi
                                          ? '${c['prenom'] ?? ''} ${c['nom'] ?? ''} (${_t(langue, 'moi')})'
                                          : '${c['prenom'] ?? ''} ${c['nom'] ?? ''}',
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize:
                                            isSmall ? 12 : 13,
                                        fontWeight: estMoi
                                            ? FontWeight.w700
                                            : FontWeight.normal,
                                        color: AppTheme.texte,
                                      ),
                                    ),
                                    Text(
                                      !isPaye && dateEch != null
                                          ? joursJ >= 0
                                              ? '${_t(langue, 'due_dans')} $joursJ ${_t(langue, 'jours')}'
                                              : _t(langue, 'en_retard')
                                          : _formatDate(
                                              c['date_echeance']),
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: isSmall ? 10 : 11,
                                        color: isPaye
                                            ? AppTheme.grisTexte
                                            : isRetard || joursJ < 0
                                                ? AppTheme.rouge
                                                : AppTheme.grisTexte,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${c['montant']} F',
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize:
                                          isSmall ? 12 : 13,
                                      fontWeight: FontWeight.w700,
                                      color: couleurC,
                                    ),
                                  ),
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2),
                                    decoration: BoxDecoration(
                                      color: couleurC
                                          .withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isPaye
                                          ? _t(langue, 'paye')
                                          : isRetard
                                              ? _t(langue, 'en_retard')
                                              : _t(langue, 'en_attente'),
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize:
                                            isSmall ? 8 : 9,
                                        fontWeight: FontWeight.w600,
                                        color: couleurC,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (estMoi && !isPaye) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => context.push(
                                      '/tontine/${widget.id}/compte-virtuel'),
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 7),
                                    decoration: BoxDecoration(
                                      color: isRetard || joursJ < 0
                                          ? AppTheme.rouge
                                          : AppTheme.vert,
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _t(langue, 'payer'),
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize:
                                            isSmall ? 10 : 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            );
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _miniStatBlanche(
      String valeur, String label, bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 8 : 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(valeur,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: isSmall ? 14 : 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              )),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 9,
                color: Colors.white70,
              )),
        ],
      ),
    );
  }

  // ── ONGLET MEMBRES ────────────────────────────────
  Widget _buildOngletMembres(
      List<Map<String, dynamic>> membres,
      String langue,
      bool isSmall) {
    if (membres.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👥', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(_t(langue, 'membres'),
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: AppTheme.grisTexte)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(isSmall ? 12 : 16),
      itemCount: membres.length,
      itemBuilder: (ctx, i) {
        final m = membres[i];
        final aRecu = m['a_recu'] == true;
        final score = m['score_fiabilite'] is int
            ? m['score_fiabilite'] as int
            : int.tryParse(
                    m['score_fiabilite']?.toString() ?? '100') ??
                100;
        final couleurScore = score >= 80
            ? AppTheme.vert
            : score >= 50
                ? AppTheme.orange
                : AppTheme.rouge;
        final photoUrl = m['photo_profil'] ?? m['photo_url'];

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: EdgeInsets.all(isSmall ? 12 : 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: aRecu
                  ? AppTheme.vert.withOpacity(0.3)
                  : const Color(0xFFE8E8E5),
              width: aRecu ? 1 : 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: isSmall ? 40 : 46,
                height: isSmall ? 40 : 46,
                decoration: BoxDecoration(
                  color:
                      aRecu ? AppTheme.vert : AppTheme.grisClair,
                  shape: BoxShape.circle,
                ),
                child: photoUrl != null
                    ? ClipOval(
                        child: Image.network(photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildInitiales(m, aRecu, isSmall)))
                    : _buildInitiales(m, aRecu, isSmall),
              ),
              SizedBox(width: isSmall ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${m['prenom'] ?? ''} ${m['nom'] ?? ''}',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: isSmall ? 13 : 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.texte,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(m['telephone'] ?? '',
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: isSmall ? 11 : 12,
                            color: AppTheme.grisTexte)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.vertClair,
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_t(langue, 'tour')} ${m['position_rotation'] ?? i + 1}',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: isSmall ? 9 : 10,
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
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_t(langue, 'score')} $score%',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: isSmall ? 9 : 10,
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
              aRecu
                  ? const Icon(Icons.check_circle,
                      color: AppTheme.vert, size: 24)
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.orangeClair,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _t(langue, 'en_attente'),
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: isSmall ? 10 : 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.orangeFonce,
                        ),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInitiales(Map m, bool aRecu, bool isSmall) {
    final p = (m['prenom'] ?? '?');
    final n = (m['nom'] ?? '');
    return Center(
      child: Text(
        '${p.isNotEmpty ? p[0] : '?'}${n.isNotEmpty ? n[0] : ''}',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: isSmall ? 12 : 14,
          fontWeight: FontWeight.w700,
          color: aRecu ? Colors.white : AppTheme.grisTexte,
        ),
      ),
    );
  }

  // ── ONGLET INFOS ──────────────────────────────────
  Widget _buildOngletInfos(Map t, String langue, bool isSmall) {
    final statut = t['statut'] ?? 'active';
    final couleurStatut = statut == 'active'
        ? AppTheme.vert
        : statut == 'terminee'
            ? AppTheme.grisTexte
            : AppTheme.orange;

    final responsablePrenom = t['responsable_prenom'] ??
        t['responsable']?['prenom'] ??
        '';
    final responsableNom =
        t['responsable_nom'] ?? t['responsable']?['nom'] ?? '';
    final responsableTel = t['responsable_telephone'] ??
        t['responsable']?['telephone'] ??
        '';

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmall ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isSmall ? 14 : 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFFE8E8E5), width: 0.5),
            ),
            child: Column(
              children: [
                _buildInfoLigne(
                    Icons.category_outlined,
                    _t(langue, 'type'),
                    '${_typeEmoji(t['type'])} ${t['type']?.toString().replaceAll('_', ' ') ?? ''}',
                    isSmall),
                _buildDivider(),
                _buildInfoLigne(
                    Icons.payments_outlined,
                    _t(langue, 'montant'),
                    '${t['montant_cotisation']} F ${_periodiciteLabel(t['periodicite'], langue)}',
                    isSmall),
                _buildDivider(),
                _buildInfoLigne(
                    Icons.people_outline,
                    _t(langue, 'total_membres'),
                    '${(t['membres'] as List?)?.length ?? 0} / ${t['nombre_membres'] ?? '-'}',
                    isSmall),
                _buildDivider(),
                _buildInfoLigne(
                    Icons.calendar_today_outlined,
                    _t(langue, 'date_debut'),
                    _formatDate(t['date_debut']),
                    isSmall),
                _buildDivider(),
                _buildInfoLigne(
                    Icons.event_outlined,
                    _t(langue, 'date_fin'),
                    _formatDate(t['date_fin']),
                    isSmall),
                _buildDivider(),
                _buildInfoLigneStatut(
                    couleurStatut,
                    _t(langue, 'statut'),
                    statut == 'active'
                        ? _t(langue, 'actif')
                        : statut == 'terminee'
                            ? _t(langue, 'termine')
                            : _t(langue, 'en_attente'),
                    isSmall),
              ],
            ),
          ),
          SizedBox(height: isSmall ? 12 : 16),
          if (responsablePrenom.isNotEmpty)
            Container(
              padding: EdgeInsets.all(isSmall ? 14 : 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFFE8E8E5), width: 0.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: isSmall ? 40 : 46,
                    height: isSmall ? 40 : 46,
                    decoration: const BoxDecoration(
                      color: AppTheme.vertClair,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        responsablePrenom.isNotEmpty
                            ? responsablePrenom[0]
                            : 'R',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: isSmall ? 16 : 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.vert,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isSmall ? 10 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(_t(langue, 'responsable'),
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: isSmall ? 10 : 11,
                                color: AppTheme.grisTexte)),
                        Text(
                          '$responsablePrenom $responsableNom',
                          style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: isSmall ? 13 : 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.texte),
                        ),
                        if (responsableTel.isNotEmpty)
                          Text(responsableTel,
                              style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: isSmall ? 11 : 12,
                                  color: AppTheme.grisTexte)),
                      ],
                    ),
                  ),
                  const Text('👑',
                      style: TextStyle(fontSize: 20)),
                ],
              ),
            ),
          SizedBox(height: isSmall ? 12 : 16),
          if (t['description'] != null &&
              t['description'].toString().isNotEmpty)
            Container(
              padding: EdgeInsets.all(isSmall ? 14 : 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFFE8E8E5), width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_t(langue, 'description'),
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: isSmall ? 11 : 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.grisTexte)),
                  const SizedBox(height: 8),
                  Text(t['description'],
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: isSmall ? 13 : 14,
                          color: AppTheme.texte,
                          height: 1.5)),
                ],
              ),
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildInfoLigne(
      IconData icon, String label, String valeur, bool isSmall) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon,
              size: isSmall ? 18 : 20, color: AppTheme.grisTexte),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: isSmall ? 12 : 13,
                      color: AppTheme.grisTexte))),
          Text(valeur,
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: isSmall ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.texte)),
        ],
      ),
    );
  }

  Widget _buildInfoLigneStatut(
      Color couleur, String label, String valeur, bool isSmall) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(Icons.circle,
              size: isSmall ? 14 : 16, color: couleur),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: isSmall ? 12 : 13,
                      color: AppTheme.grisTexte))),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: couleur.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(valeur,
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: isSmall ? 11 : 12,
                    fontWeight: FontWeight.w700,
                    color: couleur)),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() =>
      const Divider(height: 1, color: Color(0xFFE8E8E5));

  Widget _statCard(String valeur, String label, Color bg,
      Color couleur, IconData icon, bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 12 : 14),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: couleur, size: isSmall ? 18 : 22),
          SizedBox(height: isSmall ? 4 : 6),
          Text(valeur,
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: isSmall ? 14 : 16,
                  fontWeight: FontWeight.w700,
                  color: couleur)),
          Text(label,
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: isSmall ? 9 : 11,
                  color: AppTheme.grisTexte)),
        ],
      ),
    );
  }

  // ── BOTTOM BAR ────────────────────────────────────
  Widget _buildBottomBar(Map t, String langue, bool isSmall,
      Color couleur, double soldeVirtuel) {
    final nombreMembres =
        int.tryParse(t['nombre_membres']?.toString() ?? '0') ?? 0;
    final totalMembres = (t['membres'] as List?)?.length ?? 0;
    final estComplet =
        totalMembres >= nombreMembres && nombreMembres > 0;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, isSmall ? 16 : 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
            top: BorderSide(color: Color(0xFFE8E8E5), width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_estMembre) ...[
            if (_demandeEnvoyee)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.vertClair,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppTheme.vert, size: 20),
                    const SizedBox(width: 8),
                    Text(_t(langue, 'demande_envoyee'),
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: isSmall ? 13 : 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.vertFonce)),
                  ],
                ),
              )
            else if (estComplet)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: AppTheme.grisClair,
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.group_off_outlined,
                        color: AppTheme.grisTexte, size: 20),
                    const SizedBox(width: 8),
                    Text(_t(langue, 'complet'),
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: isSmall ? 13 : 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.grisTexte)),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: isSmall ? 46 : 52,
                child: ElevatedButton.icon(
                  onPressed: () => _demanderAdhesion(langue),
                  icon: const Icon(Icons.group_add_outlined),
                  label: Text(_t(langue, 'rejoindre'),
                      style:
                          TextStyle(fontSize: isSmall ? 14 : 16)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.vert),
                ),
              ),
          ] else ...[
            FutureBuilder<Map<String, dynamic>?>(
              future: ApiService.getCotisationEnCours(t['id']),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const SizedBox(
                    height: 48,
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.vert, strokeWidth: 2),
                    ),
                  );
                }
                final cotisation = snapshot.data;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: isSmall ? 46 : 52,
                      child: ElevatedButton.icon(
                        onPressed: () => context.push(
                            '/tontine/${widget.id}/compte-virtuel'),
                        icon: const Icon(Icons
                            .account_balance_wallet_outlined),
                        label: Text(
                          cotisation != null
                              ? '${_t(langue, 'deposer')} ${cotisation['montant']} F'
                              : _t(langue, 'compte_virtuel'),
                          style: TextStyle(
                              fontSize: isSmall ? 14 : 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cotisation != null
                              ? AppTheme.orange
                              : AppTheme.vert,
                        ),
                      ),
                    ),
                    if (cotisation == null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.vertClair,
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle,
                                color: AppTheme.vert, size: 16),
                            const SizedBox(width: 6),
                            Text(_t(langue, 'a_jour'),
                                style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize:
                                        isSmall ? 12 : 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.vertFonce)),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _telephoneCtrl.dispose();
    _vocal.stop();
    super.dispose();
  }
}
