import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/groups/ui/groups_screen.dart';
import '../../features/help/ui/help_screen.dart';
import '../../features/home/ui/home_screen.dart';
import '../../features/navigation/ui/navigation_screen.dart';
import '../../features/navigation/ui/shortcut_screen.dart';
import '../../features/offline/ui/my_tours_screen.dart';
import '../../features/search/data/start_point_store.dart';
import '../../features/search/ui/question_screen.dart';
import '../../features/search/ui/results_screen.dart';
import '../../features/search/ui/start_point_screen.dart';
import '../../features/tour/ui/day_plan_screen.dart';
import '../../features/tour/ui/tour_detail_screen.dart';
import '../widgets/main_shell.dart';
import 'app_routes.dart';

GoRoute _route(String path, GoRouterWidgetBuilder builder) =>
    GoRoute(path: path.substring(1), builder: builder);

/// [needsStartPoint]: `true`, solange noch kein Startpunkt gewählt ist. Dann
/// führt die Startseite zur Startpunkt-Wahl (SPEC 5.2, allererster Start).
GoRouter createAppRouter({
  String initialLocation = AppRoutes.home,
  bool Function()? needsStartPoint,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    redirect: (context, state) {
      if (state.matchedLocation == AppRoutes.home &&
          (needsStartPoint?.call() ?? false)) {
        return AppRoutes.startPoint;
      }
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(navigationShell: shell),
        branches: [
          // ANNAHME: Die Startseite ist der Anfang des Bereichs
          // „Wanderungen“ (siehe DECISIONS.md).
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
                routes: [
                  _route(
                    AppRoutes.startPoint,
                    (c, s) => const StartPointScreen(),
                  ),
                  _route(AppRoutes.search, (c, s) => const TourTypeQuestion()),
                  _route(
                    AppRoutes.searchDuration,
                    (c, s) => const DurationQuestion(),
                  ),
                  _route(
                    AppRoutes.searchEffort,
                    (c, s) => const EffortQuestion(),
                  ),
                  _route(AppRoutes.searchFood, (c, s) => const FoodQuestion()),
                  _route(AppRoutes.searchRide, (c, s) => const RideQuestion()),
                  _route(
                    AppRoutes.suggestions,
                    (c, s) => const SuggestionsScreen(),
                  ),
                  _route(AppRoutes.allTours, (c, s) => const AllToursScreen()),
                  GoRoute(
                    path: 'tour/:id',
                    builder: (c, s) =>
                        TourDetailScreen(tourId: s.pathParameters['id']!),
                    routes: [
                      GoRoute(
                        path: 'ablauf',
                        builder: (c, s) =>
                            DayPlanScreen(tourId: s.pathParameters['id']!),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.groups,
                builder: (context, state) => const GroupsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.myTours,
                builder: (context, state) => const MyToursScreen(),
                routes: [
                  GoRoute(
                    path: 'tour/:id',
                    builder: (c, s) =>
                        TourDetailScreen(tourId: s.pathParameters['id']!),
                  ),
                  GoRoute(
                    path: 'navigation/:id',
                    builder: (c, s) =>
                        NavigationScreen(tourId: s.pathParameters['id']!),
                    routes: [
                      GoRoute(
                        path: 'abkuerzen',
                        builder: (c, s) =>
                            ShortcutScreen(tourId: s.pathParameters['id']!),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.help,
                builder: (context, state) => const HelpScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = createAppRouter(
    needsStartPoint: () => ref.read(startPointProvider) == null,
  );
  ref.onDispose(router.dispose);
  return router;
});
