import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../utils/app_theme.dart';

class MediaPickerWidget extends StatefulWidget {
  final Function(String? imagePath, String? videoPath) onMediaSelected;
  final String? initialImage;

  const MediaPickerWidget({
    super.key,
    required this.onMediaSelected,
    this.initialImage,
  });

  @override
  State<MediaPickerWidget> createState() => _MediaPickerWidgetState();
}

class _MediaPickerWidgetState extends State<MediaPickerWidget> {
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

  // Exemples préchargés
  final List<Map<String, dynamic>> _exemplesImages = [
    {'emoji': '💰', 'label': 'Argent', 'couleur': const Color(0xFF1D9E75)},
    {'emoji': '🛋️', 'label': 'Meuble', 'couleur': const Color(0xFF378ADD)},
    {'emoji': '❄️', 'label': 'Frigo', 'couleur': const Color(0xFF534AB7)},
    {'emoji': '📺', 'label': 'TV', 'couleur': const Color(0xFFD85A30)},
    {'emoji': '🏥', 'label': 'Santé', 'couleur': const Color(0xFFE24B4A)},
    {'emoji': '🎓', 'label': 'École', 'couleur': const Color(0xFF534AB7)},
    {'emoji': '🌾', 'label': 'Champ', 'couleur': const Color(0xFF639922)},
    {'emoji': '🏗️', 'label': 'Construction', 'couleur': const Color(0xFF888780)},
    {'emoji': '✈️', 'label': 'Voyage', 'couleur': const Color(0xFF0F6E56)},
    {'emoji': '🛒', 'label': 'Commerce', 'couleur': const Color(0xFFBA7517)},
    {'emoji': '💊', 'label': 'Médicament', 'couleur': const Color(0xFFD4537E)},
    {'emoji': '🎉', 'label': 'Fête', 'couleur': const Color(0xFFD4537E)},
  ];

  String? _exempleSelectionne;

  Future<void> _prendrePhoto() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 600,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _imagePath = image.path;
        _exempleSelectionne = null;
      });
      widget.onMediaSelected(image.path, null);
    }
  }

  Future<void> _choisirDepuisGalerie() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 600,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _imagePath = image.path;
        _exempleSelectionne = null;
      });
      widget.onMediaSelected(image.path, null);
    }
  }

  Future<void> _choisirVideo() async {
    final video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 2),
    );
    if (video != null) {
      setState(() {
        _imagePath = null;
        _exempleSelectionne = null;
      });
      widget.onMediaSelected(null, video.path);
    }
  }

  void _afficherOptions() {
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
            const Text('Choisir une image',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 16),

            // Options de source
            Row(
              children: [
                Expanded(child: _buildSourceBtn(
                  Icons.camera_alt_outlined,
                  'Prendre une photo',
                  AppTheme.vert,
                  () { Navigator.pop(ctx); _prendrePhoto(); },
                )),
                const SizedBox(width: 10),
                Expanded(child: _buildSourceBtn(
                  Icons.photo_library_outlined,
                  'Ma galerie',
                  AppTheme.vert,
                  () { Navigator.pop(ctx); _choisirDepuisGalerie(); },
                )),
                const SizedBox(width: 10),
                Expanded(child: _buildSourceBtn(
                  Icons.videocam_outlined,
                  'Vidéo',
                  const Color(0xFF378ADD),
                  () { Navigator.pop(ctx); _choisirVideo(); },
                )),
              ],
            ),
            const SizedBox(height: 20),

            const Text('Ou choisir un exemple',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.grisTexte,
                )),
            const SizedBox(height: 12),

            // Galerie d'exemples
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: _exemplesImages.map((ex) {
                final selected = _exempleSelectionne == ex['emoji'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _exempleSelectionne = ex['emoji'];
                      _imagePath = null;
                    });
                    widget.onMediaSelected(null, null);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: (ex['couleur'] as Color).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? ex['couleur'] as Color
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(ex['emoji'],
                            style: const TextStyle(fontSize: 24)),
                        const SizedBox(height: 2),
                        Text(ex['label'],
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 9,
                              color: AppTheme.grisTexte,
                            )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceBtn(
      IconData icon, String label, Color couleur, VoidCallback onTap) {
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
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: couleur,
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _afficherOptions,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (_imagePath != null || _exempleSelectionne != null)
                ? AppTheme.vert
                : const Color(0xFFD3D1C7),
            width: (_imagePath != null || _exempleSelectionne != null) ? 2 : 1,
          ),
        ),
        child: _imagePath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(_imagePath!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
            : _exempleSelectionne != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_exempleSelectionne!,
                            style: const TextStyle(fontSize: 56)),
                        const SizedBox(height: 8),
                        const Text('Appuyez pour changer',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              color: AppTheme.grisTexte,
                            )),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_photo_alternate_outlined,
                          size: 40, color: AppTheme.grisTexte),
                      const SizedBox(height: 8),
                      const Text('Ajouter une image ou vidéo',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.grisTexte,
                          )),
                      const SizedBox(height: 4),
                      const Text('Ou choisir parmi nos exemples',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 11,
                            color: AppTheme.gris,
                          )),
                    ],
                  ),
      ),
    );
  }
}
