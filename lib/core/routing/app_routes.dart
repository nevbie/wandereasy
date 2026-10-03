/// Pfade aller Bildschirme an einer Stelle.
abstract final class AppRoutes {
  static const String home = '/';
  static const String startPoint = '/startpunkt';

  // Fragen-Suche (SPEC 5.2), je Frage ein Bildschirm.
  static const String search = '/suche';
  static const String searchDuration = '/suche/dauer';
  static const String searchEffort = '/suche/anstrengung';
  static const String searchFood = '/suche/einkehr';
  static const String searchRide = '/suche/fahrzeit';
  static const String suggestions = '/suche/vorschlaege';
  static const String allTours = '/touren';

  static String tour(String id) => '/tour/$id';
  static String dayPlan(String id) => '/tour/$id/ablauf';

  static const String groups = '/gruppen';
  static const String myTours = '/meine-touren';
  static const String help = '/hilfe';
}
