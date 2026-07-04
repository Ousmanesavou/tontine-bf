import 'package:flutter/material.dart';

class Responsive {
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static double w(BuildContext context, double percent) =>
      screenWidth(context) * percent / 100;

  static double h(BuildContext context, double percent) =>
      screenHeight(context) * percent / 100;

  // Taille de police adaptative
  static double fontSize(BuildContext context, double size) {
    final width = screenWidth(context);
    if (width < 360) return size * 0.85; // Petit écran
    if (width < 480) return size; // Écran normal
    if (width < 720) return size * 1.1; // Grand écran
    return size * 1.2; // Très grand écran (tablette)
  }

  // Padding adaptatif
  static double padding(BuildContext context) {
    final width = screenWidth(context);
    if (width < 360) return 12.0;
    if (width < 480) return 16.0;
    return 20.0;
  }

  // Vérifier si c'est une tablette
  static bool isTablet(BuildContext context) =>
      screenWidth(context) >= 720;

  // Vérifier si c'est un petit écran
  static bool isSmallScreen(BuildContext context) =>
      screenWidth(context) < 360;

  // Hauteur adaptative pour les cartes
  static double cardHeight(BuildContext context) {
    final width = screenWidth(context);
    if (width < 360) return 100.0;
    if (width < 480) return 120.0;
    return 140.0;
  }

  // Nombre de colonnes pour les grilles
  static int gridColumns(BuildContext context) {
    final width = screenWidth(context);
    if (width < 480) return 2;
    if (width < 720) return 3;
    return 4;
  }
}
