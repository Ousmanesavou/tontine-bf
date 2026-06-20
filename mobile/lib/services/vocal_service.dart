import 'package:flutter_tts/flutter_tts.dart';
import 'storage_service.dart';

class VocalService {
  static final VocalService _instance = VocalService._internal();
  factory VocalService() => _instance;
  VocalService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _initialise = false;

  Future<void> _init() async {
    if (_initialise) return;
    await _tts.setLanguage('fr-FR');
    await _tts.setSpeechRate(0.85);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _initialise = true;
  }

  Future<void> parler(String texte) async {
    await _init();
    await _tts.stop();
    await _tts.speak(texte);
  }

  Future<void> parlerMultilingue({
    required String fr,
    String? moore,
    String? dioula,
  }) async {
    final langue = StorageService.getLangue() ?? 'fr';
    String message = fr;
    if (langue == 'moore' && moore != null) message = moore;
    if (langue == 'dioula' && dioula != null) message = dioula;
    await parler(message);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  // Messages prédéfinis
  Future<void> annoncerPaiementReussi(String montant, String tontine) async {
    await parlerMultilingue(
      fr: 'Paiement de $montant francs réussi pour la tontine $tontine. Merci !',
      moore: 'Paiement $montant franc tontine $tontine yaa sɩda. A barka !',
      dioula: 'Sarali $montant faranka tontine $tontine bɛn. I ni ce !',
    );
  }

  Future<void> annoncerRappelCotisation(String montant, int jours) async {
    await parlerMultilingue(
      fr: 'Rappel : votre cotisation de $montant francs est due dans $jours jour${jours > 1 ? 's' : ''}.',
      moore: 'Sõsg : f cotisation $montant franc yaa wa doge $jours pʋgẽ.',
      dioula: 'Hakili : i ka musaka $montant faranka bɛna wa tile $jours kɔnɔ.',
    );
  }

  Future<void> annoncerTourProchain(String tontine) async {
    await parlerMultilingue(
      fr: 'Félicitations ! C\'est bientôt votre tour de recevoir dans la tontine $tontine.',
      moore: 'Barka ! F yɩɩr yaa wa tontine $tontine pʋgẽ.',
      dioula: 'I ni ce ! I sisan bɛ se ka tontine $tontine sɔrɔ.',
    );
  }
}
