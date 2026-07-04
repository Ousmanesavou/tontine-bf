import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_theme.dart';
import '../../utils/pays_data.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/vocal_service.dart';
import '../../main.dart';

// ── TRADUCTIONS ───────────────────────────────────────
const Map<String, Map<String, String>> _tr = {
  'fr': {
    'titre': 'Payer ma cotisation',
    'montant': 'Montant à payer',
    'periode': 'Période en cours',
    'methode': 'Moyen de paiement',
    'telephone': 'Numéro de paiement',
    'tel_hint': 'Numéro Mobile Money',
    'confirmer': 'Confirmer le paiement',
    'info': 'Après le paiement, tous les membres recevront une notification de confirmation.',
    'succes': 'Paiement effectué avec succès !',
    'securise': '🔒 Paiement sécurisé',
    'securise_desc': 'Vos données sont protégées et chiffrées.',
    'vocal': 'Choisissez votre moyen de paiement et confirmez.',
    'depot_physique': 'Dépôt physique',
    'depot_desc': 'Remettez l\'argent directement au responsable',
    'numero_requis': 'Entrez votre numéro Mobile Money',
    'echeance': 'Date d\'échéance',
    'tontine': 'Tontine',
    'recap': 'Récapitulatif',
    'annuler': 'Annuler',
  },
  'en': {
    'titre': 'Pay my contribution',
    'montant': 'Amount to pay',
    'periode': 'Current period',
    'methode': 'Payment method',
    'telephone': 'Payment number',
    'tel_hint': 'Mobile Money number',
    'confirmer': 'Confirm payment',
    'info': 'After payment, all members will receive a confirmation notification.',
    'succes': 'Payment successful!',
    'securise': '🔒 Secure payment',
    'securise_desc': 'Your data is protected and encrypted.',
    'vocal': 'Choose your payment method and confirm.',
    'depot_physique': 'Physical deposit',
    'depot_desc': 'Hand the money directly to the manager',
    'numero_requis': 'Enter your Mobile Money number',
    'echeance': 'Due date',
    'tontine': 'Tontine',
    'recap': 'Summary',
    'annuler': 'Cancel',
  },
  'mos': {
    'titre': 'Kõ m cotisation',
    'montant': 'Ligdi f kõdame',
    'periode': 'Kõ-wakatã',
    'methode': 'Kõ-noor',
    'telephone': 'Tɛlɛfõ nimero',
    'tel_hint': 'Mobile Money nimero',
    'confirmer': 'Sɩng kõ-rɛɛgã',
    'info': 'Kõ yɩɩba poor, neb fãa kõ-kaas paamda.',
    'succes': 'Kõ sɩnga sɩda !',
    'securise': '🔒 Kõ zɩɩlame',
    'securise_desc': 'F yɛla maana sɩda.',
    'vocal': 'Tɩ yãk kõ-noor la sɩng.',
    'depot_physique': 'Kõ noor seko',
    'depot_desc': 'Kõ ligdi naab nengẽ',
    'numero_requis': 'Sɩbg f Mobile Money nimero',
    'echeance': 'Tɩɩm-dãmba',
    'tontine': 'Tontine',
    'recap': 'Fãa-wilgr',
    'annuler': 'Bas',
  },
  'bm': {
    'titre': 'N ka sarali sara',
    'montant': 'Wari sarali kama',
    'periode': 'Sara waati',
    'methode': 'Sara laɲini',
    'telephone': 'Telefɔni nimɔrɔ',
    'tel_hint': 'Mobile Money nimɔrɔ',
    'confirmer': 'Sara sɛbɛn',
    'info': 'Sara kɛ kɔ, mɔgɔw bɛɛ kibaru sɔrɔ.',
    'succes': 'Sarali kɛra ka ɲɛ !',
    'securise': '🔒 Sara dɔnni',
    'securise_desc': 'I ka kunnafoni kɔlɔsi.',
    'vocal': 'Sara laɲini sugandi ka sɛbɛn.',
    'depot_physique': 'Wari di woloko',
    'depot_desc': 'Wari di kuntigui ma',
    'numero_requis': 'I ka Mobile Money nimɔrɔ sɛbɛn',
    'echeance': 'Laban tile',
    'tontine': 'Tontine',
    'recap': 'Jɛnsɛgɛli',
    'annuler': 'Datan',
  },
  'wo': {
    'titre': 'Fay sa cotisation',
    'montant': 'Xaalis bu fay',
    'periode': 'Waxt bi',
    'methode': 'Laaj bu fay',
    'telephone': 'Nimero bu telefon',
    'tel_hint': 'Nimero Mobile Money',
    'confirmer': 'Seytaan ay fay',
    'info': 'Fay bi jeex, nit yi bɛɛ dina jot xibaar.',
    'succes': 'Fay bi def naa ko !',
    'securise': '🔒 Fay bu dëgër',
    'securise_desc': 'Say données yi dëgër na.',
    'vocal': 'Tann sa laaj bu fay ci kanam.',
    'depot_physique': 'Jox ci loxo',
    'depot_desc': 'Jox xaalis bi boroom bi',
    'numero_requis': 'Bind sa nimero Mobile Money',
    'echeance': 'Bët ci dëkk',
    'tontine': 'Tontine',
    'recap': 'Jot ak jot',
    'annuler': 'Dëkk du',
  },
};

String _t(String langue, String key) {
  final lang = _tr[langue] ?? _tr['fr']!;
  return lang[key] ?? _tr['fr']![key] ?? key;
}

class PaiementScreen extends ConsumerStatefulWidget {
  final String cotisationId;
  const PaiementScreen({super.key, required this.cotisationId});

  @override
  ConsumerState<PaiementScreen> createState() => _PaiementScreenState();
}

class _PaiementScreenState extends ConsumerState<PaiementScreen> {
  String _methode = '';
  bool _chargement = false;
  bool _chargementCotisation = true;
  Map<String, dynamic>? _cotisation;
  final VocalService _vocal = VocalService();
  final TextEditingController _telCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chargerCotisation();
    // Pré-remplir avec le numéro de l'utilisateur
    final user = StorageService.getUser();
    if (user?['telephone'] != null) {
      _telCtrl.text = user!['telephone']
          .toString()
          .replaceAll('+226', '')
          .replaceAll('+221', '')
          .replaceAll('+225', '');
    }
  }

  Future<void> _chargerCotisation() async {
    try {
      final cotisations = await ApiService.getMesCotisations();
      final cotisation = cotisations.firstWhere(
        (c) => c['id'].toString() == widget.cotisationId,
        orElse: () => {},
      );
      if (mounted) {
        setState(() {
          _cotisation = cotisation.isEmpty ? null : cotisation;
          _chargementCotisation = false;
        });
        // Définir méthode par défaut selon pays
        final pays = StorageService.getPays() ?? 'BF';
        final mm = PaysData.getMobileMoney(pays);
        if (mm.isNotEmpty) {
          _methode = mm.first.toLowerCase().replaceAll(' ', '_');
        } else {
          _methode = 'orange_money';
        }
      }
    } catch (e) {
      if (mounted) setState(() => _chargementCotisation = false);
    }
  }

  List<Map<String, dynamic>> _getMethodes(String pays) {
    final mm = PaysData.getMobileMoney(pays);
    final methodes = mm.map((m) {
      final code = m.toLowerCase().replaceAll(' ', '_');
      Color couleur = AppTheme.vert;
      String initiales = m.split(' ').map((w) => w[0]).take(2).join();

      if (m.toLowerCase().contains('orange')) {
        couleur = const Color(0xFFFF6600);
      } else if (m.toLowerCase().contains('moov')) {
        couleur = const Color(0xFF0066CC);
      } else if (m.toLowerCase().contains('mtn')) {
        couleur = const Color(0xFFFFCC00);
      } else if (m.toLowerCase().contains('wave')) {
        couleur = const Color(0xFF1DC1C8);
      } else if (m.toLowerCase().contains('airtel')) {
        couleur = const Color(0xFFE40000);
      } else if (m.toLowerCase().contains('free')) {
        couleur = const Color(0xFF8B1A1A);
      }

      return {
        'code': code,
        'label': m,
        'couleur': couleur,
        'initiales': initiales,
        'isMobileMoney': true,
      };
    }).toList();

    // Ajouter dépôt physique toujours
    methodes.add({
      'code': 'depot_physique',
      'label': 'depot_physique',
      'couleur': AppTheme.gris,
      'initiales': 'DP',
      'isMobileMoney': false,
    });

    return methodes;
  }

  Future<void> _payer(String langue) async {
    if (_methode.isEmpty) return;
    setState(() => _chargement = true);
    try {
      final user = StorageService.getUser();
      final indicatif = PaysData.getPays(
              StorageService.getPays() ?? 'BF')?['indicatif'] ??
          '+226';
      final tel = _telCtrl.text.isNotEmpty
          ? '$indicatif${_telCtrl.text}'
          : user?['telephone'];

      await ApiService.initierPaiement(
        cotisationId: widget.cotisationId,
        methodePaiement: _methode,
        telephone: tel,
      );

      _vocal.parler(_t(langue, 'succes'));

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
    final langue = ref.watch(langueProvider);
    final pays = ref.watch(paysProvider);
    final sw = MediaQuery.of(context).size.width;
    final isSmall = sw < 360;
    final methodes = _getMethodes(pays);
    final methodSelectionne = methodes.firstWhere(
      (m) => m['code'] == _methode,
      orElse: () => methodes.isNotEmpty ? methodes.first : {},
    );

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
            icon: const Icon(Icons.volume_up_rounded,
                color: Colors.white70),
            onPressed: () => _vocal.parler(_t(langue, 'vocal')),
          ),
        ],
      ),
      body: _chargementCotisation
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.vert))
          : SingleChildScrollView(
              padding: EdgeInsets.all(isSmall ? 14 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── CARTE MONTANT ─────────────────────
                  _buildCarteMontant(langue, isSmall),
                  SizedBox(height: isSmall ? 16 : 24),

                  // ── MÉTHODE DE PAIEMENT ───────────────
                  Text(
                    _t(langue, 'methode'),
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: isSmall ? 12 : 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.grisTexte,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...methodes.map((m) =>
                      _buildMethodeCard(m, langue, isSmall)),
                  SizedBox(height: isSmall ? 14 : 20),

                  // ── NUMÉRO MOBILE MONEY ───────────────
                  if (_methode != 'depot_physique' &&
                      methodSelectionne['isMobileMoney'] == true)
                    _buildChampTelephone(langue, pays, isSmall),

                  SizedBox(height: isSmall ? 14 : 20),

                  // ── INFO ──────────────────────────────
                  _buildInfoBox(langue, isSmall),
                  SizedBox(height: isSmall ? 14 : 20),

                  // ── SÉCURITÉ ──────────────────────────
                  _buildSecuriteBox(langue, isSmall),
                  SizedBox(height: isSmall ? 20 : 28),

                  // ── BOUTON PAYER ──────────────────────
                  _chargement
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.vert))
                      : SizedBox(
                          width: double.infinity,
                          height: isSmall ? 48 : 54,
                          child: ElevatedButton.icon(
                            onPressed: () => _payer(langue),
                            icon: const Icon(Icons.lock_outline),
                            label: Text(
                              _t(langue, 'confirmer'),
                              style: TextStyle(
                                  fontSize: isSmall ? 14 : 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: methodSelectionne[
                                          'couleur'] !=
                                      null
                                  ? methodSelectionne['couleur']
                                      as Color
                                  : AppTheme.vert,
                            ),
                          ),
                        ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: isSmall ? 44 : 48,
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: AppTheme.grisTexte),
                        foregroundColor: AppTheme.grisTexte,
                      ),
                      child: Text(
                        _t(langue, 'annuler'),
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: isSmall ? 14 : 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildCarteMontant(String langue, bool isSmall) {
    final montant = _cotisation?['montant']?.toString() ?? '-';
    final nomTontine = _cotisation?['tontine_nom'] ?? '-';
    final echeance = _cotisation?['date_echeance'];
    final jours = echeance != null
        ? DateTime.parse(echeance).difference(DateTime.now()).inDays
        : null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmall ? 18 : 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.vert, AppTheme.vertFonce],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.vert.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _t(langue, 'montant'),
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: isSmall ? 12 : 13,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: isSmall ? 6 : 8),
          Text(
            '$montant F CFA',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: isSmall ? 28 : 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_t(langue, 'tontine')} · $nomTontine',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: isSmall ? 11 : 12,
              color: Colors.white60,
            ),
          ),
          if (jours != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '${_t(langue, 'echeance')}: $jours j',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMethodeCard(Map<String, dynamic> methode,
      String langue, bool isSmall) {
    final selected = _methode == methode['code'];
    final couleur = methode['couleur'] as Color;
    final isDepot = methode['code'] == 'depot_physique';
    final label = isDepot
        ? _t(langue, 'depot_physique')
        : methode['label'] as String;
    final desc = isDepot ? _t(langue, 'depot_desc') : null;

    return GestureDetector(
      onTap: () => setState(() => _methode = methode['code']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(isSmall ? 12 : 14),
        decoration: BoxDecoration(
          color: selected
              ? couleur.withOpacity(0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? couleur : const Color(0xFFE8E8E5),
            width: selected ? 2 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: isSmall ? 38 : 44,
              height: isSmall ? 38 : 44,
              decoration: BoxDecoration(
                color: selected
                    ? couleur
                    : couleur.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: isDepot
                    ? Icon(Icons.handshake_outlined,
                        color: selected
                            ? Colors.white
                            : couleur,
                        size: isSmall ? 18 : 20)
                    : Text(
                        methode['initiales'],
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : couleur,
                          fontWeight: FontWeight.w800,
                          fontSize: isSmall ? 11 : 13,
                        ),
                      ),
              ),
            ),
            SizedBox(width: isSmall ? 10 : 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: isSmall ? 14 : 15,
                      fontWeight: FontWeight.w600,
                      color: selected ? couleur : AppTheme.texte,
                    ),
                  ),
                  if (desc != null)
                    Text(
                      desc,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: isSmall ? 10 : 11,
                        color: AppTheme.grisTexte,
                      ),
                    ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: couleur,
                  size: isSmall ? 20 : 22),
          ],
        ),
      ),
    );
  }

  Widget _buildChampTelephone(
      String langue, String pays, bool isSmall) {
    final paysInfo = PaysData.getPays(pays);
    final indicatif = paysInfo?['indicatif'] ?? '+226';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t(langue, 'telephone'),
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: isSmall ? 12 : 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.grisTexte,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _telCtrl,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly
          ],
          decoration: InputDecoration(
            hintText: _t(langue, 'tel_hint'),
            prefixIcon: const Icon(Icons.phone_outlined),
            prefixText: '$indicatif ',
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBox(String langue, bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 12 : 14),
      decoration: BoxDecoration(
        color: AppTheme.vertClair,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              color: AppTheme.vert, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _t(langue, 'info'),
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: isSmall ? 11 : 12,
                color: AppTheme.vertFonce,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuriteBox(String langue, bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 12 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFDDE3F8), width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined,
              color: Color(0xFF5B6FBE), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t(langue, 'securise'),
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: isSmall ? 12 : 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5B6FBE),
                  ),
                ),
                Text(
                  _t(langue, 'securise_desc'),
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: isSmall ? 10 : 11,
                    color: const Color(0xFF5B6FBE),
                  ),
                ),
              ],
            ),
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
