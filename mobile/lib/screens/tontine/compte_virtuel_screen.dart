import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/vocal_service.dart';
import '../../main.dart';

// ── TRADUCTIONS ───────────────────────────────────────
const Map<String, Map<String, String>> _tr = {
  'fr': {
    'titre': 'Compte virtuel',
    'solde': 'Solde disponible',
    'total_depots': 'Total dépôts',
    'total_retraits': 'Total retraits',
    'mon_depot': 'Mes dépôts',
    'depot': 'Déposer',
    'retrait': 'Retirer',
    'voter': 'Voter',
    'transactions': 'Transactions',
    'aucune_transaction': 'Aucune transaction',
    'periode_terminee': 'Période terminée',
    'periode_en_cours': 'Période en cours',
    'retrait_possible': 'Retrait possible',
    'retrait_impossible': 'Retrait impossible avant fin de période',
    'vote_retrait': 'Vote retrait en cours',
    'votes_pour': 'votes pour',
    'approuver': 'Approuver',
    'refuser': 'Refuser',
    'confirmer_depot': 'Confirmer le dépôt',
    'confirmer_retrait': 'Confirmer le retrait',
    'montant': 'Montant',
    'methode': 'Méthode de paiement',
    'telephone': 'Numéro de paiement',
    'motif': 'Motif du retrait',
    'succes_depot': 'Dépôt effectué avec succès !',
    'succes_vote': 'Vote enregistré !',
    'retrait_approuve': 'Retrait approuvé !',
    'retrait_refuse': 'Retrait refusé.',
    'annuler': 'Annuler',
    'vous': 'Vous',
    'depot_label': 'Dépôt',
    'retrait_label': 'Retrait',
    'approuve': 'Approuvé',
    'refuse': 'Refusé',
    'en_attente': 'En attente',
    'confirme': 'Confirmé',
    'seul_createur': 'Seul le créateur peut initier un retrait',
    'fin_periode': 'Fin de période',
    'membres_votes': 'membres doivent voter',
  },
  'en': {
    'titre': 'Virtual account',
    'solde': 'Available balance',
    'total_depots': 'Total deposits',
    'total_retraits': 'Total withdrawals',
    'mon_depot': 'My deposits',
    'depot': 'Deposit',
    'retrait': 'Withdraw',
    'voter': 'Vote',
    'transactions': 'Transactions',
    'aucune_transaction': 'No transactions',
    'periode_terminee': 'Period ended',
    'periode_en_cours': 'Period in progress',
    'retrait_possible': 'Withdrawal possible',
    'retrait_impossible': 'Withdrawal not possible before end of period',
    'vote_retrait': 'Withdrawal vote in progress',
    'votes_pour': 'votes for',
    'approuver': 'Approve',
    'refuser': 'Refuse',
    'confirmer_depot': 'Confirm deposit',
    'confirmer_retrait': 'Confirm withdrawal',
    'montant': 'Amount',
    'methode': 'Payment method',
    'telephone': 'Payment number',
    'motif': 'Withdrawal reason',
    'succes_depot': 'Deposit successful!',
    'succes_vote': 'Vote recorded!',
    'retrait_approuve': 'Withdrawal approved!',
    'retrait_refuse': 'Withdrawal refused.',
    'annuler': 'Cancel',
    'vous': 'You',
    'depot_label': 'Deposit',
    'retrait_label': 'Withdrawal',
    'approuve': 'Approved',
    'refuse': 'Refused',
    'en_attente': 'Pending',
    'confirme': 'Confirmed',
    'seul_createur': 'Only the creator can initiate a withdrawal',
    'fin_periode': 'End of period',
    'membres_votes': 'members must vote',
  },
  'mos': {
    'titre': 'Kaont virtuel',
    'solde': 'Ligdi bee',
    'total_depots': 'Kõ-dãmba fãa',
    'total_retraits': 'Yiis-dãmba fãa',
    'mon_depot': 'M kõ-dãmba',
    'depot': 'Kõ',
    'retrait': 'Yiis',
    'voter': 'Voet',
    'transactions': 'Toeeg-dãmba',
    'aucune_transaction': 'Toeeg ka be',
    'periode_terminee': 'Wakatã tɩɩmame',
    'periode_en_cours': 'Wakatã bee',
    'retrait_possible': 'Yiis tõe',
    'retrait_impossible': 'Yiis ka tõe tɩ wakatã ta',
    'vote_retrait': 'Yiis voet bee',
    'votes_pour': 'voet yĩnga',
    'approuver': 'Basem',
    'refuser': 'Kɩtg',
    'confirmer_depot': 'Sɩng kõ',
    'confirmer_retrait': 'Sɩng yiis',
    'montant': 'Ligdi',
    'methode': 'Kõ-noor',
    'telephone': 'Tɛlɛfõ nimero',
    'motif': 'Yiis yĩnga',
    'succes_depot': 'Kõ sɩnga sɩda !',
    'succes_vote': 'Voet sɩbgame !',
    'retrait_approuve': 'Yiis basame !',
    'retrait_refuse': 'Yiis kɩtgame.',
    'annuler': 'Bas',
    'vous': 'Fo',
    'depot_label': 'Kõ',
    'retrait_label': 'Yiis',
    'approuve': 'Basame',
    'refuse': 'Kɩtgame',
    'en_attente': 'Rog-m-tɩɩg',
    'confirme': 'Sɩngsame',
    'seul_createur': 'Ned ning bʋga tontine yã tõe n yiis',
    'fin_periode': 'Wakatã tɩɩm',
    'membres_votes': 'neb tõnd n voet',
  },
  'bm': {
    'titre': 'Konto virtuel',
    'solde': 'Wari be yen',
    'total_depots': 'Sara bɛɛ',
    'total_retraits': 'Bɔ bɛɛ',
    'mon_depot': 'N ka saraw',
    'depot': 'Sara',
    'retrait': 'Bɔ',
    'voter': 'Vote',
    'transactions': 'Kɛtaw',
    'aucune_transaction': 'Kɛta si be',
    'periode_terminee': 'Waati bannana',
    'periode_en_cours': 'Waati kɔnɔ',
    'retrait_possible': 'Bɔ Se',
    'retrait_impossible': 'Bɔ tɛ Se waati ban kɔ',
    'vote_retrait': 'Bɔ vote kɔnɔ',
    'votes_pour': 'vote yɛrɛ',
    'approuver': 'Dɔn',
    'refuser': 'Bali',
    'confirmer_depot': 'Sara sɛbɛn',
    'confirmer_retrait': 'Bɔ sɛbɛn',
    'montant': 'Wari',
    'methode': 'Sara laɲini',
    'telephone': 'Telefɔni nimɔrɔ',
    'motif': 'Bɔ kama',
    'succes_depot': 'Sara kɛra !',
    'succes_vote': 'Vote sɛbɛnna !',
    'retrait_approuve': 'Bɔ dɔnna !',
    'retrait_refuse': 'Bɔ balinna.',
    'annuler': 'Datan',
    'vous': 'I',
    'depot_label': 'Sara',
    'retrait_label': 'Bɔ',
    'approuve': 'Dɔnna',
    'refuse': 'Balinna',
    'en_attente': 'Kɔnɔ',
    'confirme': 'Sɛbɛnna',
    'seul_createur': 'Tontine daminɛbaga dɔrɔn bɛ se ka bɔ',
    'fin_periode': 'Waati laban',
    'membres_votes': 'mɔgɔw ka vote',
  },
  'wo': {
    'titre': 'Kont virtuel',
    'solde': 'Xaalis bu am',
    'total_depots': 'Fay yi bɛɛ',
    'total_retraits': 'Jël yi bɛɛ',
    'mon_depot': 'Sam fay yi',
    'depot': 'Fay',
    'retrait': 'Jël',
    'voter': 'Voté',
    'transactions': 'Kɛf yi',
    'aucune_transaction': 'Kɛf amul',
    'periode_terminee': 'Waxt bi jeex na',
    'periode_en_cours': 'Waxt bi am na',
    'retrait_possible': 'Jël mën na',
    'retrait_impossible': 'Jël du mën waxt bi jeex',
    'vote_retrait': 'Vote jël bi am na',
    'votes_pour': 'vote ngir',
    'approuver': 'Seytaan',
    'refuser': 'Bëgg du',
    'confirmer_depot': 'Seytaan fay bi',
    'confirmer_retrait': 'Seytaan jël bi',
    'montant': 'Xaalis',
    'methode': 'Laaj bu fay',
    'telephone': 'Nimero bu telefon',
    'motif': 'Jël ngir',
    'succes_depot': 'Fay bi def na ko !',
    'succes_vote': 'Vote bi bind na !',
    'retrait_approuve': 'Jël bi seytaan na !',
    'retrait_refuse': 'Jël bi bëgg doo.',
    'annuler': 'Dëkk du',
    'vous': 'Yow',
    'depot_label': 'Fay',
    'retrait_label': 'Jël',
    'approuve': 'Seytaan na',
    'refuse': 'Bëgg doo',
    'en_attente': 'Xaaraan',
    'confirme': 'Dëgg na',
    'seul_createur': 'Boroom tontine rekk mën a jël',
    'fin_periode': 'Waxt bu jeex',
    'membres_votes': 'nit yi dafa voté',
  },
};

String _t(String langue, String key) {
  final lang = _tr[langue] ?? _tr['fr']!;
  return lang[key] ?? _tr['fr']![key] ?? key;
}

class CompteVirtuelScreen extends ConsumerStatefulWidget {
  final String tontineId;
  const CompteVirtuelScreen({super.key, required this.tontineId});

  @override
  ConsumerState<CompteVirtuelScreen> createState() =>
      _CompteVirtuelScreenState();
}

class _CompteVirtuelScreenState
    extends ConsumerState<CompteVirtuelScreen> {
  Map<String, dynamic>? _compte;
  bool _chargement = true;
  final VocalService _vocal = VocalService();

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final data =
          await ApiService.getCompteVirtuel(widget.tontineId);
      setState(() {
        _compte = data;
        _chargement = false;
      });
    } catch (e) {
      setState(() => _chargement = false);
    }
  }

  bool get _estCreateur {
    final user = StorageService.getUser();
    return _compte?['responsable_id']?.toString() ==
        user?['id']?.toString();
  }

  bool get _periodeTerminee =>
      _compte?['periode_terminee'] == true;

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
            icon: const Icon(Icons.volume_up_rounded,
                color: Colors.white70),
            onPressed: () => _vocal.parler(
                '${_t(langue, 'solde')}: ${_compte?['solde'] ?? 0} F'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _charger,
          ),
        ],
      ),
      body: _chargement
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppTheme.vert))
          : _compte == null
              ? _buildErreur(langue)
              : RefreshIndicator(
                  color: AppTheme.vert,
                  onRefresh: _charger,
                  child: SingleChildScrollView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding:
                        EdgeInsets.all(isSmall ? 14 : 16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _buildCartesolde(langue, isSmall),
                        SizedBox(height: isSmall ? 14 : 16),
                        _buildStatCards(langue, isSmall),
                        SizedBox(height: isSmall ? 14 : 16),
                        _buildBoutonsAction(
                            langue, isSmall),
                        SizedBox(height: isSmall ? 14 : 16),
                        _buildVoteEnCours(langue, isSmall),
                        SizedBox(height: isSmall ? 14 : 16),
                        _buildTransactions(langue, isSmall),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  // ── CARTE SOLDE ───────────────────────────────────
  Widget _buildCartesolde(String langue, bool isSmall) {
    final solde =
        double.tryParse(_compte?['solde']?.toString() ?? '0') ?? 0;
    final periodeTerminee = _periodeTerminee;
    final dateFin = _compte?['date_fin'];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmall ? 20 : 24),
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
            _t(langue, 'solde'),
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: isSmall ? 12 : 13,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${solde.toStringAsFixed(0)} F CFA',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: isSmall ? 28 : 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: periodeTerminee
                  ? Colors.green.withOpacity(0.3)
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  periodeTerminee
                      ? Icons.check_circle
                      : Icons.timer_outlined,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  periodeTerminee
                      ? _t(langue, 'periode_terminee')
                      : '${_t(langue, 'fin_periode')}: ${_formatDate(dateFin)}',
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
      ),
    );
  }

  // ── STAT CARDS ────────────────────────────────────
  Widget _buildStatCards(String langue, bool isSmall) {
    final totalDepots = double.tryParse(
            _compte?['total_depots']?.toString() ?? '0') ??
        0;
    final totalRetraits = double.tryParse(
            _compte?['total_retraits']?.toString() ?? '0') ??
        0;
    final monDepot = double.tryParse(
            _compte?['mon_depot_total']?.toString() ?? '0') ??
        0;

    return Row(
      children: [
        Expanded(
          child: _statCard(
            _t(langue, 'total_depots'),
            '${totalDepots.toStringAsFixed(0)} F',
            AppTheme.vertClair,
            AppTheme.vert,
            Icons.arrow_downward_rounded,
            isSmall,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            _t(langue, 'total_retraits'),
            '${totalRetraits.toStringAsFixed(0)} F',
            AppTheme.orangeClair,
            AppTheme.orange,
            Icons.arrow_upward_rounded,
            isSmall,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            _t(langue, 'mon_depot'),
            '${monDepot.toStringAsFixed(0)} F',
            const Color(0xFFEDE7F6),
            const Color(0xFF7B1FA2),
            Icons.person_outline,
            isSmall,
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String valeur, Color bg,
      Color couleur, IconData icon, bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 10 : 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: couleur, size: isSmall ? 16 : 18),
          const SizedBox(height: 6),
          Text(
            valeur,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: isSmall ? 12 : 14,
              fontWeight: FontWeight.w700,
              color: couleur,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: isSmall ? 9 : 10,
              color: couleur.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  // ── BOUTONS ACTION ────────────────────────────────
  Widget _buildBoutonsAction(String langue, bool isSmall) {
    final pays = StorageService.getPays() ?? 'BF';

    return Row(
      children: [
        // Bouton Dépôt — tous les membres
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showDepotSheet(langue, pays),
            icon: const Icon(Icons.arrow_downward_rounded,
                size: 18),
            label: Text(
              _t(langue, 'depot'),
              style: TextStyle(fontSize: isSmall ? 13 : 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.vert,
              padding: EdgeInsets.symmetric(
                  vertical: isSmall ? 12 : 14),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Bouton Retrait — créateur seulement + période terminée
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _estCreateur && _periodeTerminee
                ? () => _showRetraitSheet(langue, pays)
                : null,
            icon: const Icon(Icons.arrow_upward_rounded,
                size: 18),
            label: Text(
              _t(langue, 'retrait'),
              style: TextStyle(fontSize: isSmall ? 13 : 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _estCreateur && _periodeTerminee
                  ? AppTheme.orange
                  : AppTheme.grisClair,
              padding: EdgeInsets.symmetric(
                  vertical: isSmall ? 12 : 14),
            ),
          ),
        ),
      ],
    );
  }

  // ── VOTE EN COURS ─────────────────────────────────
  Widget _buildVoteEnCours(String langue, bool isSmall) {
    final transactions = List<Map<String, dynamic>>.from(
        _compte?['transactions'] ?? []);
    final retraitEnCours = transactions
        .where((t) => t['statut'] == 'en_attente_vote')
        .toList();

    if (retraitEnCours.isEmpty) return const SizedBox();

    final retrait = retraitEnCours.first;
    final votes =
        List<Map<String, dynamic>>.from(retrait['votes'] ?? []);
    final votesOui =
        votes.where((v) => v['vote'] == 'oui').length;
    final nbMembres =
        int.tryParse(_compte?['nb_membres']?.toString() ?? '0') ??
            0;
    final userId = StorageService.getUser()?['id']?.toString();
    final dejaVote =
        votes.any((v) => v['utilisateur_id']?.toString() == userId);
    final estCreateur = retrait['utilisateur_id']?.toString() == userId;

    return Container(
      padding: EdgeInsets.all(isSmall ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.orange, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.how_to_vote_outlined,
                  color: AppTheme.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _t(langue, 'vote_retrait'),
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: isSmall ? 13 : 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${retrait['montant']} F CFA',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: isSmall ? 20 : 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.texte,
            ),
          ),
          const SizedBox(height: 8),
          // Barre de progression votes
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: nbMembres > 1
                        ? votesOui / (nbMembres - 1)
                        : 0,
                    backgroundColor: AppTheme.grisClair,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(
                            AppTheme.vert),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$votesOui/${nbMembres - 1} ${_t(langue, 'votes_pour')}',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: isSmall ? 11 : 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.grisTexte,
                ),
              ),
            ],
          ),
          // Boutons vote — seulement si pas créateur et pas encore voté
          if (!estCreateur && !dejaVote) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _voter(
                        langue, retrait['id'].toString(), 'non'),
                    icon: const Icon(Icons.close,
                        color: AppTheme.rouge, size: 16),
                    label: Text(
                      _t(langue, 'refuser'),
                      style: const TextStyle(
                          color: AppTheme.rouge),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: AppTheme.rouge),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _voter(
                        langue, retrait['id'].toString(), 'oui'),
                    icon: const Icon(Icons.check, size: 16),
                    label: Text(_t(langue, 'approuver')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.vert,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (dejaVote && !estCreateur)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppTheme.vert, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Vous avez voté',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: isSmall ? 11 : 12,
                      color: AppTheme.vert,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── TRANSACTIONS ──────────────────────────────────
  Widget _buildTransactions(String langue, bool isSmall) {
    final transactions = List<Map<String, dynamic>>.from(
        _compte?['transactions'] ?? []);
    final visibles = transactions
        .where((t) => t['statut'] != 'en_attente_vote')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t(langue, 'transactions'),
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: isSmall ? 13 : 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.texte,
          ),
        ),
        const SizedBox(height: 10),
        if (visibles.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                _t(langue, 'aucune_transaction'),
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: AppTheme.grisTexte),
              ),
            ),
          )
        else
          ...visibles.map((t) =>
              _buildTransactionCard(t, langue, isSmall)),
      ],
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> t,
      String langue, bool isSmall) {
    final isDepot = t['type'] == 'depot';
    final statut = t['statut'];
    final montant =
        double.tryParse(t['montant']?.toString() ?? '0') ?? 0;
    final userId = StorageService.getUser()?['id']?.toString();
    final estMoi = t['utilisateur_id']?.toString() == userId;

    Color couleur = isDepot ? AppTheme.vert : AppTheme.orange;
    if (statut == 'approuve') couleur = AppTheme.vert;
    if (statut == 'refuse') couleur = AppTheme.rouge;

    String statutLabel = statut == 'confirme'
        ? _t(langue, 'confirme')
        : statut == 'approuve'
            ? _t(langue, 'approuve')
            : statut == 'refuse'
                ? _t(langue, 'refuse')
                : _t(langue, 'en_attente');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(isSmall ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFE8E8E5), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: isSmall ? 36 : 40,
            height: isSmall ? 36 : 40,
            decoration: BoxDecoration(
              color: couleur.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDepot
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: couleur,
              size: isSmall ? 18 : 20,
            ),
          ),
          SizedBox(width: isSmall ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDepot
                      ? _t(langue, 'depot_label')
                      : _t(langue, 'retrait_label'),
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: isSmall ? 13 : 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.texte,
                  ),
                ),
                Text(
                  estMoi
                      ? _t(langue, 'vous')
                      : '${t['prenom'] ?? ''} ${t['nom'] ?? ''}',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: isSmall ? 11 : 12,
                    color: AppTheme.grisTexte,
                  ),
                ),
                Text(
                  _formatDate(t['created_at']),
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: isSmall ? 9 : 10,
                    color: AppTheme.grisTexte,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isDepot ? '+' : '-'}${montant.toStringAsFixed(0)} F',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: isSmall ? 13 : 15,
                  fontWeight: FontWeight.w700,
                  color: couleur,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: couleur.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statutLabel,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: isSmall ? 8 : 9,
                    fontWeight: FontWeight.w600,
                    color: couleur,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── SHEET DÉPÔT ───────────────────────────────────
  void _showDepotSheet(String langue, String pays) {
    final montantCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    String methode = 'orange_money';

    // Pré-remplir numéro
    final user = StorageService.getUser();
    // Pré-remplir avec le montant de cotisation
    final cotisation = _compte?['montant_cotisation'];
    if (cotisation != null) {
    montantCtrl.text = cotisation.toString();
    }
    if (user?['telephone'] != null) {
      telCtrl.text = user!['telephone']
          .toString()
          .replaceAll(RegExp(r'^\+\d{3}'), '');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (ctx, setModal) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
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
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _t(langue, 'confirmer_depot'),
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: montantCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _t(langue, 'montant'),
                    prefixIcon: const Icon(Icons.attach_money),
                    suffixText: 'F CFA',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: telCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: _t(langue, 'telephone'),
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                // Méthodes Mobile Money
                Text(_t(langue, 'methode'),
                    style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: AppTheme.grisTexte)),
                const SizedBox(height: 8),
                _buildMethodesSheet(methode, pays, (m) {
                  setModal(() => methode = m);
                }),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final montant =
                          double.tryParse(montantCtrl.text);
                      if (montant == null || montant <= 0) return;
                      final montantVal = double.tryParse(montantCtrl.text) ?? 0.0;
                      final methodVal = methode;
                      Navigator.pop(ctx);
if (mounted) {
                          GoRouter.of(context).push(
                            '/paiement/capture/${widget.tontineId}',
                            extra: {
                              'montant': montantVal,
                              'numeroOrganisateur': _compteVirtuel?['numero_mobile_money'] ?? '',
                              'operateur': methodVal,
                              'nomTontine': _compteVirtuel?['nom'] ?? 'Tontine',
                            },
                          );
                        }
                    },
                    child: Text(_t(langue, 'confirmer_depot')),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── SHEET RETRAIT ─────────────────────────────────
  void _showRetraitSheet(String langue, String pays) {
    final montantCtrl = TextEditingController();
        // Pré-remplir avec le solde total
    final solde = _compte?['solde']?.toString() ?? '0';
    montantCtrl.text = solde;
    final telCtrl = TextEditingController();
    final motifCtrl = TextEditingController();
    String methode = 'orange_money';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (ctx, setModal) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
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
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _t(langue, 'confirmer_retrait'),
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                // Info sécurité
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.orangeClair,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.security,
                          color: AppTheme.orangeFonce, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tous les membres doivent approuver ce retrait.',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            color: AppTheme.orangeFonce,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: montantCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _t(langue, 'montant'),
                    prefixIcon: const Icon(Icons.attach_money),
                    suffixText: 'F CFA',
                    helperText:
                        'Solde: ${_compte?['solde'] ?? 0} F',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: telCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: _t(langue, 'telephone'),
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: motifCtrl,
                  decoration: InputDecoration(
                    labelText: _t(langue, 'motif'),
                    prefixIcon:
                        const Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                Text(_t(langue, 'methode'),
                    style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: AppTheme.grisTexte)),
                const SizedBox(height: 8),
                _buildMethodesSheet(methode, pays, (m) {
                  setModal(() => methode = m);
                }),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final montant =
                          double.tryParse(montantCtrl.text);
                      if (montant == null || montant <= 0) return;
                      Navigator.pop(ctx);
                      await _initierRetrait(langue, montant,
                          methode, telCtrl.text, motifCtrl.text);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.orange),
                    child: Text(_t(langue, 'confirmer_retrait')),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodesSheet(String methodeSelectionnee,
    String pays, Function(String) onSelect) {
  final methodes = <Map<String, dynamic>>[
    {'code': 'orange_money', 'label': 'Orange Money',
     'couleur': const Color(0xFFFF6600)},
    {'code': 'moov_money', 'label': 'Moov Money',
     'couleur': const Color(0xFF0066CC)},
    {'code': 'wave', 'label': 'Wave',
     'couleur': const Color(0xFF1DC1C8)},
    if (pays == 'SN' || pays == 'CI' || pays == 'ML')
      {'code': 'free_money', 'label': 'Free Money',
       'couleur': const Color(0xFF00A651)},
    if (pays == 'CM' || pays == 'CD' || pays == 'GH')
      {'code': 'mtn_money', 'label': 'MTN Money',
       'couleur': const Color(0xFFFFCC00)},
  ];

  return Wrap(
    spacing: 8,
    runSpacing: 8,
    children: methodes.map((m) {
      final selected = methodeSelectionnee == m['code'];
      final couleur = m['couleur'] as Color;
      return GestureDetector(
        onTap: () => onSelect(m['code'] as String),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? couleur.withOpacity(0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? couleur : AppTheme.grisClair,
                width: selected ? 2 : 1),
          ),
          child: Text(
            m['label'] as String,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? couleur : AppTheme.texte,
            ),
          ),
        ),
      );
    }).toList(),
  );
}
  // ── ACTIONS API ───────────────────────────────────
  Future<void> _effectuerDepot(String langue, double montant,
      String methode, String telephone) async {
    try {
      await ApiService.effectuerDepotVirtuel(
        tontineId: widget.tontineId,
        montant: montant,
        methodePaiement: methode,
        telephonePaiement: telephone,
      );
      _vocal.parler(_t(langue, 'succes_depot'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t(langue, 'succes_depot')),
            backgroundColor: AppTheme.vert,
          ),
        );
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

  Future<void> _initierRetrait(String langue, double montant,
      String methode, String telephone, String motif) async {
    try {
      await ApiService.initierRetraitVirtuel(
        tontineId: widget.tontineId,
        montant: montant,
        methodeRetrait: methode,
        telephoneRetrait: telephone,
        motif: motif,
      );
      _vocal.parler('Demande de retrait envoyée aux membres');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande envoyée. En attente des votes.'),
            backgroundColor: AppTheme.orange,
          ),
        );
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

  Future<void> _voter(
      String langue, String retraitId, String vote) async {
    try {
      final result = await ApiService.voterRetrait(
        tontineId: widget.tontineId,
        retraitId: retraitId,
        vote: vote,
      );
      final approuve = result['approuve'] == true;
      _vocal.parler(approuve
          ? _t(langue, 'retrait_approuve')
          : _t(langue, 'succes_vote'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approuve
                ? _t(langue, 'retrait_approuve')
                : _t(langue, 'succes_vote')),
            backgroundColor:
                approuve ? AppTheme.vert : AppTheme.orange,
          ),
        );
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

  Widget _buildErreur(String langue) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(_t(langue, 'aucune_transaction'),
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  color: AppTheme.grisTexte)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _charger,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
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
  void dispose() {
    _vocal.stop();
    super.dispose();
  }
}
