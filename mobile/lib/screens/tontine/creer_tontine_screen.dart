import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/vocal_service.dart';
import '../../widgets/media_picker_widget.dart';

class CreerTontineScreen extends StatefulWidget {
  const CreerTontineScreen({super.key});

  @override
  State<CreerTontineScreen> createState() => _CreerTontineScreenState();
}

class _CreerTontineScreenState extends State<CreerTontineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _montantCtrl = TextEditingController();
  final _membresCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final VocalService _vocal = VocalService();

  String _type = 'argent_liquide';
  String _periodicite = 'hebdomadaire';
  int _periodicitejours = 7;
  DateTime _dateDebut = DateTime.now().add(const Duration(days: 1));
  bool _chargement = false;
  String? _mediaImagePath;
  String? _mediaVideoPath;

  final List<Map<String, dynamic>> _types = [
    {
      'code': 'argent_liquide',
      'label': 'Argent liquide',
      'emoji': '💰',
      'description': 'Chaque membre reçoit la cagnotte à son tour',
      'couleur': const Color(0xFF1D9E75),
    },
    {
      'code': 'objet',
      'label': 'Objet / Bien',
      'emoji': '📦',
      'description': 'Choisissez un objet dans le catalogue',
      'couleur': const Color(0xFF378ADD),
    },
    {
      'code': 'caisse_fixe',
      'label': 'Caisse commune',
      'emoji': '🏦',
      'description': 'Épargne collective avec emprunts possibles',
      'couleur': const Color(0xFFBA7517),
    },
    {
      'code': 'evenementielle',
      'label': 'Événement',
      'emoji': '🎉',
      'description': 'Mariage, baptême, funérailles',
      'couleur': const Color(0xFFD4537E),
    },
    {
      'code': 'sante',
      'label': 'Santé',
      'emoji': '🏥',
      'description': 'Fonds d\'urgence médicale pour le groupe',
      'couleur': const Color(0xFFE24B4A),
    },
    {
      'code': 'education',
      'label': 'Éducation',
      'emoji': '🎓',
      'description': 'Scolarité et fournitures scolaires',
      'couleur': const Color(0xFF534AB7),
    },
    {
      'code': 'agriculture',
      'label': 'Agriculture',
      'emoji': '🌾',
      'description': 'Semences, engrais, équipements agricoles',
      'couleur': const Color(0xFF639922),
    },
    {
      'code': 'construction',
      'label': 'Construction',
      'emoji': '🏗️',
      'description': 'Matériaux de construction et rénovation',
      'couleur': const Color(0xFF888780),
    },
    {
      'code': 'voyage',
      'label': 'Voyage',
      'emoji': '✈️',
      'description': 'Transport et déplacements',
      'couleur': const Color(0xFF0F6E56),
    },
    {
      'code': 'commerce',
      'label': 'Commerce',
      'emoji': '🛒',
      'description': 'Fonds de roulement pour petits commerces',
      'couleur': const Color(0xFFD85A30),
    },
  ];

  final List<Map<String, dynamic>> _periodicites = [
    {'code': 'quotidien', 'label': 'Chaque jour', 'jours': 1},
    {'code': '2_jours', 'label': 'Tous les 2 jours', 'jours': 2},
    {'code': 'hebdomadaire', 'label': 'Chaque semaine', 'jours': 7},
    {'code': '2_semaines', 'label': 'Toutes les 2 semaines', 'jours': 14},
    {'code': 'mensuel', 'label': 'Chaque mois', 'jours': 30},
  ];

  double get _cotisationParMembre {
    final montant = double.tryParse(_montantCtrl.text) ?? 0;
    final membres = int.tryParse(_membresCtrl.text) ?? 1;
    return membres > 0 ? montant / membres : 0;
  }

  DateTime get _dateFin {
    final membres = int.tryParse(_membresCtrl.text) ?? 1;
    return _dateDebut.add(Duration(days: _periodicitejours * membres));
  }

  Map<String, dynamic> get _typeSelectionne =>
      _types.firstWhere((t) => t['code'] == _type);

  Future<void> _creer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _chargement = true);

    try {
      await ApiService.creerTontine({
        'nom': _nomCtrl.text.trim(),
        'type': _type,
        'description': _descriptionCtrl.text.trim(),
        'montant_cotisation': double.parse(_montantCtrl.text),
        'periodicite': _periodicite,
        'periodicite_jours': _periodicitejours,
        'nombre_membres': int.parse(_membresCtrl.text),
        'date_debut': _dateDebut.toIso8601String().split('T')[0],
        'ordre_rotation': 'tirage_sort',
      });

      _vocal.parlerMultilingue(
        fr: 'Tontine créée avec succès !',
        moore: 'Tontine sɩnga sɩda !',
        dioula: 'Tontine daminɛna ka kɛ sɛbɛn !',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tontine créée avec succès !'),
            backgroundColor: AppTheme.vert,
          ),
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppTheme.rouge),
        );
      }
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fond,
      appBar: AppBar(
        backgroundColor: AppTheme.vert,
        foregroundColor: Colors.white,
        title: const Text('Nouvelle tontine',
            style: TextStyle(fontFamily: 'Nunito', color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded, color: Colors.white70),
            onPressed: () => _vocal.parler(
                'Remplissez le nom, le type, le montant total, le nombre de membres et la périodicité.'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection('Nom de la tontine'),
              TextFormField(
                controller: _nomCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Ex: Tontine des amis du quartier',
                  prefixIcon: Icon(Icons.group_outlined),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 20),

              _buildSection('Type de tontine'),
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _types.length,
                  itemBuilder: (ctx, i) {
                    final t = _types[i];
                    final selected = _type == t['code'];
                    return GestureDetector(
                      onTap: () {
                        setState(() => _type = t['code']);
                        _vocal.parler(
                            '${t['label']}. ${t['description']}');
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 120,
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selected
                              ? (t['couleur'] as Color).withOpacity(0.15)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? t['couleur'] as Color
                                : const Color(0xFFE8E8E5),
                            width: selected ? 2 : 0.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(t['emoji'],
                                style: const TextStyle(fontSize: 32)),
                            const SizedBox(height: 8),
                            Text(
                              t['label'],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? t['couleur'] as Color
                                    : AppTheme.texte,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t['description'],
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 9,
                                color: AppTheme.grisTexte,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),

              // Affiche le type sélectionné
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: (_typeSelectionne['couleur'] as Color)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text(_typeSelectionne['emoji'],
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _typeSelectionne['description'],
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          color: _typeSelectionne['couleur'] as Color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _buildSection('Montant total (F CFA)'),
              TextFormField(
                controller: _montantCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: 'Ex: 150000',
                  prefixIcon: Icon(Icons.attach_money),
                  suffixText: 'F CFA',
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requis';
                  if (double.tryParse(v) == null) return 'Montant invalide';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              _buildSection('Nombre de membres'),
              TextFormField(
                controller: _membresCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: 'Ex: 10',
                  prefixIcon: Icon(Icons.people_outline),
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requis';
                  final n = int.tryParse(v);
                  if (n == null || n < 2) return 'Minimum 2 membres';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              _buildSection('Périodicité des cotisations'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _periodicites.map((p) {
                  final selected = _periodicite == p['code'];
                  return GestureDetector(
                    onTap: () => setState(() {
                      _periodicite = p['code'];
                      _periodicitejours = p['jours'];
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.vert : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppTheme.vert
                              : const Color(0xFFE8E8E5),
                        ),
                      ),
                      child: Text(
                        p['label'],
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : AppTheme.texte,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              _buildSection('Date de début'),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dateDebut,
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 365)),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: const ColorScheme.light(
                            primary: AppTheme.vert),
                      ),
                      child: child!,
                    ),
                  );
                  if (date != null) setState(() => _dateDebut = date);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD3D1C7)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: AppTheme.grisTexte),
                      const SizedBox(width: 10),
                      Text(
                        '${_dateDebut.day}/${_dateDebut.month}/${_dateDebut.year}',
                        style: const TextStyle(
                            fontFamily: 'Nunito', fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _buildSection('Description (optionnel)'),
              TextFormField(
                controller: _descriptionCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Décrivez votre tontine en quelques mots...',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 20),

              _buildSection('Image ou vidéo (optionnel)'),
              MediaPickerWidget(
                onMediaSelected: (imagePath, videoPath) {
                  setState(() {
                    _mediaImagePath = imagePath;
                    _mediaVideoPath = videoPath;
                  });
                },
              ),
              const SizedBox(height: 20),

              if (_montantCtrl.text.isNotEmpty &&
                  _membresCtrl.text.isNotEmpty)
                _buildRecapitulatif(),
              const SizedBox(height: 24),

              _chargement
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.vert))
                  : ElevatedButton.icon(
                      onPressed: _creer,
                      icon: const Icon(Icons.check),
                      label: const Text('Créer la tontine'),
                    ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String titre) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        titre,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.grisTexte,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildRecapitulatif() {
    final membres = int.tryParse(_membresCtrl.text) ?? 1;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.vertClair,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_typeSelectionne['emoji'],
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              const Text('Récapitulatif',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      color: AppTheme.vertFonce)),
            ],
          ),
          const SizedBox(height: 10),
          _buildRecapLigne(
            'Cotisation par membre',
            '${_cotisationParMembre.toStringAsFixed(0)} F / ${_periodicites.firstWhere((p) => p['code'] == _periodicite)['label']}',
          ),
          _buildRecapLigne(
              'Durée totale', '${membres * _periodicitejours} jours'),
          _buildRecapLigne('Date de fin',
              '${_dateFin.day}/${_dateFin.month}/${_dateFin.year}'),
          _buildRecapLigne('Nombre de tours', '$membres tours'),
        ],
      ),
    );
  }

  Widget _buildRecapLigne(String label, String valeur) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  color: AppTheme.grisTexte)),
          Text(valeur,
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.vertFonce)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _montantCtrl.dispose();
    _membresCtrl.dispose();
    _descriptionCtrl.dispose();
    _vocal.stop();
    super.dispose();
  }
}