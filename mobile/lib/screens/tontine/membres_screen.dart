import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/vocal_service.dart';
import '../../services/storage_service.dart';
import '../../utils/pays_data.dart';
import '../../main.dart';

// ── TRADUCTIONS ───────────────────────────────────────
const Map<String, Map<String, String>> _tr = {
  'fr': {
    'titre': 'Membres',
    'inviter': 'Inviter',
    'inviter_titre': 'Inviter un membre',
    'inviter_desc': 'La personne recevra un SMS même sans smartphone.',
    'telephone': 'Numéro de téléphone',
    'envoyer': 'Envoyer l\'invitation',
    'invitation_envoyee': 'Invitation envoyée par SMS !',
    'aucun': 'Aucun membre pour l\'instant',
    'aucun_desc': 'Invitez des membres pour démarrer votre tontine',
    'inviter_membre': 'Inviter un membre',
    'tour': 'Tour',
    'fiabilite': 'Fiabilité',
    'en_attente': 'En attente',
    'recu': 'A reçu',
    'responsable': 'Responsable',
    'membre': 'Membre',
    'vocal': 'membres dans cette tontine.',
    'min_tel': 'Numéro trop court',
  },
  'en': {
    'titre': 'Members',
    'inviter': 'Invite',
    'inviter_titre': 'Invite a member',
    'inviter_desc': 'The person will receive an SMS even without a smartphone.',
    'telephone': 'Phone number',
    'envoyer': 'Send invitation',
    'invitation_envoyee': 'Invitation sent by SMS!',
    'aucun': 'No members yet',
    'aucun_desc': 'Invite members to start your tontine',
    'inviter_membre': 'Invite a member',
    'tour': 'Round',
    'fiabilite': 'Reliability',
    'en_attente': 'Pending',
    'recu': 'Received',
    'responsable': 'Manager',
    'membre': 'Member',
    'vocal': 'members in this tontine.',
    'min_tel': 'Number too short',
  },
  'mos': {
    'titre': 'Neb',
    'inviter': 'Bool',
    'inviter_titre': 'Bool ned',
    'inviter_desc': 'Ned kõ SMS bɩɩ a ka smartphone ye.',
    'telephone': 'Tɛlɛfõ nimero',
    'envoyer': 'Tɩ tɩɩm',
    'invitation_envoyee': 'Bool-kõo tɩɩmame SMS zugu !',
    'aucun': 'Ned ka be tɩ ta',
    'aucun_desc': 'Bʋg neb n sɩng f tontine',
    'inviter_membre': 'Bool ned',
    'tour': 'Tɩɩs',
    'fiabilite': 'Kaseto',
    'en_attente': 'Rog-m-tɩɩg',
    'recu': 'Paam',
    'responsable': 'Naab',
    'membre': 'Ned',
    'vocal': 'neb tontine pʋgẽ.',
    'min_tel': 'Nimero pɛɛg',
  },
  'bm': {
    'titre': 'Mɔgɔw',
    'inviter': 'Wele',
    'inviter_titre': 'Mɔgɔ wele',
    'inviter_desc': 'Mɔgɔ bɛ SMS sɔrɔ smartphone tɛ ni.',
    'telephone': 'Telefɔni nimɔrɔ',
    'envoyer': 'Ci',
    'invitation_envoyee': 'Weleya tɔgɔlen SMS la !',
    'aucun': 'Mɔgɔ si be fɔlɔ',
    'aucun_desc': 'Mɔgɔw wele ka tontine daminɛ',
    'inviter_membre': 'Mɔgɔ wele',
    'tour': 'Yɔrɔ',
    'fiabilite': 'Danbe',
    'en_attente': 'Kɔnɔ',
    'recu': 'Sɔrɔla',
    'responsable': 'Kuntigui',
    'membre': 'Mɔgɔ',
    'vocal': 'mɔgɔw tontine kɔnɔ.',
    'min_tel': 'Nimɔrɔ diman',
  },
  'wo': {
    'titre': 'Nit yi',
    'inviter': 'Wele',
    'inviter_titre': 'Wele ab nit',
    'inviter_desc': 'Nit bi dina jot SMS benn smartphone amul ni.',
    'telephone': 'Nimero bu telefon',
    'envoyer': 'Yónn',
    'invitation_envoyee': 'Wele yi yónnee na ci SMS !',
    'aucun': 'Nit amul ci kanam',
    'aucun_desc': 'Wele nit yi ngir dëkk sa tontine',
    'inviter_membre': 'Wele nit',
    'tour': 'Yoon',
    'fiabilite': 'Diggante',
    'en_attente': 'Xaaraan',
    'recu': 'Jotoon',
    'responsable': 'Boroom',
    'membre': 'Nit',
    'vocal': 'nit yi ci tontine bii.',
    'min_tel': 'Nimero bu mën',
  },
};

String _t(String langue, String key) {
  final lang = _tr[langue] ?? _tr['fr']!;
  return lang[key] ?? _tr['fr']![key] ?? key;
}

class MembresScreen extends ConsumerStatefulWidget {
  final String tontineId;
  const MembresScreen({super.key, required this.tontineId});

  @override
  ConsumerState<MembresScreen> createState() => _MembresScreenState();
}

class _MembresScreenState extends ConsumerState<MembresScreen> {
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
        _membres = List<Map<String, dynamic>>.from(
            tontine['membres'] ?? []);
        _chargement = false;
      });
    } catch (e) {
      setState(() => _chargement = false);
    }
  }

  Future<void> _inviter(String langue) async {
    final pays = StorageService.getPays() ?? 'BF';
    final paysInfo = PaysData.getPays(pays);
    final indicatif = paysInfo?['indicatif'] ?? '+226';

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
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.grisClair,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _t(langue, 'inviter_titre'),
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _t(langue, 'inviter_desc'),
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  color: AppTheme.grisTexte,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _telCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly
                ],
                decoration: InputDecoration(
                  labelText: _t(langue, 'telephone'),
                  prefixIcon: const Icon(Icons.phone_outlined),
                  prefixText: '$indicatif ',
                  hintText: '70 XX XX XX',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  if (_telCtrl.text.length >= 8) {
                    try {
                      await ApiService.inviterMembre(
                          widget.tontineId,
                          '$indicatif${_telCtrl.text}');
                      _telCtrl.clear();
                      if (mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                _t(langue, 'invitation_envoyee')),
                            backgroundColor: AppTheme.vert,
                          ),
                        );
                        _vocal.parler(
                            _t(langue, 'invitation_envoyee'));
                        _charger();
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
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_t(langue, 'min_tel')),
                        backgroundColor: AppTheme.orange,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.send_outlined),
                label: Text(_t(langue, 'envoyer')),
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
    final langue = ref.watch(langueProvider);
    final sw = MediaQuery.of(context).size.width;
    final isSmall = sw < 360;

    return Scaffold(
      backgroundColor: AppTheme.fond,
      appBar: AppBar(
        backgroundColor: AppTheme.vert,
        foregroundColor: Colors.white,
        title: Text(
          '${_t(langue, 'titre')} (${_membres.length})',
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
                '${_membres.length} ${_t(langue, 'vocal')}'),
          ),
          IconButton(
            icon: const Icon(Icons.person_add_outlined,
                color: Colors.white),
            onPressed: () => _inviter(langue),
          ),
        ],
      ),
      body: _chargement
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppTheme.vert))
          : _membres.isEmpty
              ? _buildEtatVide(langue, isSmall)
              : RefreshIndicator(
                  color: AppTheme.vert,
                  onRefresh: _charger,
                  child: ListView.builder(
                    padding: EdgeInsets.all(isSmall ? 12 : 16),
                    itemCount: _membres.length,
                    itemBuilder: (ctx, i) =>
                        _buildCarteMembre(
                            _membres[i], i, langue, isSmall),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _inviter(langue),
        backgroundColor: AppTheme.vert,
        icon: const Icon(Icons.person_add_outlined,
            color: Colors.white),
        label: Text(
          _t(langue, 'inviter'),
          style: const TextStyle(
            fontFamily: 'Nunito',
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCarteMembre(Map<String, dynamic> membre, int index,
      String langue, bool isSmall) {
    final aRecu = membre['a_recu'] == true;
    final score =
        membre['score_fiabilite'] is int
            ? membre['score_fiabilite'] as int
            : int.tryParse(
                    membre['score_fiabilite']?.toString() ?? '100') ??
                100;
    final estResponsable = membre['role'] == 'responsable';
    final couleurScore = score >= 80
        ? AppTheme.vert
        : score >= 50
            ? AppTheme.orange
            : AppTheme.rouge;
    final photoUrl = membre['photo_url'];

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
          // Avatar
          Container(
            width: isSmall ? 40 : 46,
            height: isSmall ? 40 : 46,
            decoration: BoxDecoration(
              color: aRecu ? AppTheme.vert : AppTheme.grisClair,
              shape: BoxShape.circle,
            ),
            child: photoUrl != null
                ? ClipOval(
                    child: Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _buildInitiales(membre, aRecu, isSmall),
                    ),
                  )
                : _buildInitiales(membre, aRecu, isSmall),
          ),
          SizedBox(width: isSmall ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${membre['prenom'] ?? ''} ${membre['nom'] ?? ''}',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: isSmall ? 13 : 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.texte,
                        ),
                      ),
                    ),
                    if (estResponsable)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.vertClair,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _t(langue, 'responsable'),
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: isSmall ? 8 : 9,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.vertFonce,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  membre['telephone'] ?? '',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: isSmall ? 11 : 12,
                    color: AppTheme.grisTexte,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmall ? 6 : 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.vertClair,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_t(langue, 'tour')} ${membre['position_rotation'] ?? index + 1}',
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
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmall ? 6 : 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: couleurScore.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_t(langue, 'fiabilite')} $score%',
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
          const SizedBox(width: 8),
          // Statut
          aRecu
              ? Column(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppTheme.vert, size: 24),
                    const SizedBox(height: 2),
                    Text(
                      _t(langue, 'recu'),
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: isSmall ? 8 : 9,
                        color: AppTheme.vert,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmall ? 8 : 10,
                    vertical: isSmall ? 4 : 6,
                  ),
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
  }

  Widget _buildInitiales(Map<String, dynamic> membre,
      bool aRecu, bool isSmall) {
    return Center(
      child: Text(
        '${(membre['prenom'] ?? '?')[0]}${(membre['nom'] ?? '')[0]}',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: isSmall ? 12 : 14,
          fontWeight: FontWeight.w700,
          color: aRecu ? Colors.white : AppTheme.grisTexte,
        ),
      ),
    );
  }

  Widget _buildEtatVide(String langue, bool isSmall) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👥', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            _t(langue, 'aucun'),
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: isSmall ? 14 : 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.texte,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _t(langue, 'aucun_desc'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              color: AppTheme.grisTexte,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _inviter(langue),
            icon: const Icon(Icons.person_add_outlined),
            label: Text(_t(langue, 'inviter_membre')),
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