import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';
import 'package:image_picker/image_picker.dart';

class _MediaItem {
  final File? file; // null si déjà en ligne (pré-rempli à l'édition)
  final String type; // 'image' ou 'video'
  bool uploading;
  String? url;
  bool erreur;

  _MediaItem({
    this.file,
    required this.type,
    this.uploading = true,
    this.url,
    this.erreur = false,
  });
}

class MediaPickerWidget extends StatefulWidget {
  /// Appelée à chaque changement (ajout, suppression, upload terminé) avec
  /// la liste à jour des médias déjà uploadés — chaque élément :
  /// {'url': String, 'type': 'image'|'video'}
  final Function(List<Map<String, dynamic>> medias) onMediaChanged;

  /// Médias déjà en ligne à pré-remplir (édition d'un produit existant).
  final List<Map<String, dynamic>>? initialMedias;

  const MediaPickerWidget({
    super.key,
    required this.onMediaChanged,
    this.initialMedias,
  });

  @override
  State<MediaPickerWidget> createState() => _MediaPickerWidgetState();
}

class _MediaPickerWidgetState extends State<MediaPickerWidget> {
  final List<_MediaItem> _items = [];
  final ImagePicker _picker = ImagePicker();

  static const int _maxFichiers = 10;
  static const int _maxImageOctets = 10 * 1024 * 1024; // 10 Mo
  static const int _maxVideoOctets = 50 * 1024 * 1024; // 50 Mo

  @override
  void initState() {
    super.initState();
    if (widget.initialMedias != null) {
      for (final m in widget.initialMedias!) {
        _items.add(_MediaItem(
          type: m['type'] ?? 'image',
          url: m['url'],
          uploading: false,
        ));
      }
    }
  }


  void _notifierParent() {
    widget.onMediaChanged(
      _items
          .where((i) => i.url != null)
          .map((i) => {'url': i.url, 'type': i.type})
          .toList(),
    );
  }

  void _snack(String msg, Color couleur) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: couleur));
  }

  Future<void> _ajouterFichier(File file, String type) async {
    if (_items.length >= _maxFichiers) {
      _snack('Maximum $_maxFichiers fichiers par tontine', AppTheme.rouge);
      return;
    }

    final taille = await file.length();
    final limite = type == 'image' ? _maxImageOctets : _maxVideoOctets;
    if (taille > limite) {
      final limiteAffichee = type == 'image' ? '10 Mo' : '50 Mo';
      _snack(
        '${type == 'image' ? 'Photo' : 'Vidéo'} trop volumineuse — $limiteAffichee maximum',
        AppTheme.rouge,
      );
      return;
    }

    final item = _MediaItem(file: file, type: type);
    setState(() => _items.add(item));

    try {
      final resultat = await ApiService.uploaderMediaTontine(file);
      setState(() {
        item.url = resultat['url'];
        item.uploading = false;
      });
      _notifierParent();
    } catch (e) {
      setState(() {
        item.erreur = true;
        item.uploading = false;
      });
      _snack('Échec de l\'envoi — réessayez', AppTheme.rouge);
    }
  }

  void _supprimer(_MediaItem item) {
    setState(() => _items.remove(item));
    _notifierParent();
  }

  Future<void> _prendrePhoto() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera, imageQuality: 80,
    );
    if (image != null) await _ajouterFichier(File(image.path), 'image');
  }

  Future<void> _choisirGalerie() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery, imageQuality: 80,
    );
    if (image != null) await _ajouterFichier(File(image.path), 'image');
  }

  Future<void> _choisirVideo() async {
    final video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 3),
    );
    if (video != null) await _ajouterFichier(File(video.path), 'video');
  }

  void _afficherOptions() {
    if (_items.length >= _maxFichiers) {
      _snack('Maximum $_maxFichiers fichiers par tontine', AppTheme.orange);
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.grisClair,
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Ajouter un média',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w700)),
            Text('${_items.length}/$_maxFichiers fichiers · 10 Mo max/photo, 50 Mo max/vidéo',
                style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, color: AppTheme.grisTexte)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _sourceBtn(Icons.camera_alt_outlined, 'Photo', AppTheme.vert,
                    () { Navigator.pop(ctx); _prendrePhoto(); })),
                const SizedBox(width: 10),
                Expanded(child: _sourceBtn(Icons.photo_library_outlined, 'Galerie', AppTheme.vert,
                    () { Navigator.pop(ctx); _choisirGalerie(); })),
                const SizedBox(width: 10),
                Expanded(child: _sourceBtn(Icons.videocam_outlined, 'Vidéo', const Color(0xFF378ADD),
                    () { Navigator.pop(ctx); _choisirVideo(); })),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sourceBtn(IconData icon, String label, Color couleur, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: couleur.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: couleur.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: couleur, size: 24),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w600, color: couleur)),
          ],
        ),
      ),
    );
  }

  Widget _tuile(_MediaItem item) {
    return Container(
      width: 100, height: 100,
      margin: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: item.type == 'image'
                ? (item.file != null
                    ? Image.file(item.file!, width: 100, height: 100, fit: BoxFit.cover)
                    : Image.network(item.url ?? '', width: 100, height: 100, fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(color: AppTheme.grisClair,
                            child: const Icon(Icons.broken_image_outlined, color: AppTheme.grisTexte))))
                : Container(
                    width: 100, height: 100,
                    color: AppTheme.texte,
                    child: const Center(
                      child: Icon(Icons.play_circle_fill, color: Colors.white, size: 36),
                    ),
                  ),
          ),
          if (item.uploading)
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: SizedBox(width: 24, height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
              ),
            ),
          if (item.erreur)
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: AppTheme.rouge.withOpacity(0.7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(child: Icon(Icons.error_outline, color: Colors.white, size: 28)),
            ),
          Positioned(
            top: 4, right: 4,
            child: GestureDetector(
              onTap: () => _supprimer(item),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
          if (item.type == 'video' && !item.uploading && !item.erreur)
            const Positioned(
              bottom: 4, left: 4,
              child: Text('🎬', style: TextStyle(fontSize: 14)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._items.map(_tuile),
              if (_items.length < _maxFichiers)
                GestureDetector(
                  onTap: _afficherOptions,
                  child: Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFD3D1C7), width: 1.5,
                          style: BorderStyle.solid),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 28, color: AppTheme.grisTexte),
                        SizedBox(height: 4),
                        Text('Ajouter', style: TextStyle(
                            fontFamily: 'Nunito', fontSize: 11, color: AppTheme.grisTexte)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text('${_items.length}/$_maxFichiers · photos et vidéos mélangées possibles',
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 11, color: AppTheme.grisTexte)),
      ],
    );
  }
}
