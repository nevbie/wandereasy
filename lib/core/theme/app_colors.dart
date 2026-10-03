import 'package:flutter/material.dart';

/// Farbwerte als austauschbare Konstanten (SPEC 4 „Theme“).
// ANNAHME: Grünton an NaturFreunde-Grün angelehnt, nicht die offizielle
// Markenfarbe. Endgültige Farben klärt der Verein (SPEC 16).
abstract final class AppColors {
  /// Markengrün – Hauptfarbe für Hauptknöpfe und Hervorhebungen.
  static const Color brandGreen = Color(0xFF1E6B34);

  /// Notruf-Rot (Hilfe-Bereich).
  static const Color emergencyRed = Color(0xFFB3261E);

  /// Schwierigkeitsgrade – immer zusammen mit Text verwenden.
  static const Color difficultyEasy = Color(0xFF2E7D32);
  static const Color difficultyMedium = Color(0xFF9A5B00);
  static const Color difficultyHard = Color(0xFFB3261E);
}
