import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/fullscreen_provider.dart';
import '../../../../core/providers/connectivity_provider.dart';
import 'package:nexora_academy/l10n/app_localizations.dart';

class MainShellScreen extends ConsumerWidget {
  const MainShellScreen({
    super.key,
    required this.navigationShell,
  });

  /// The navigation shell and container for the branch Navigators.
  final StatefulNavigationShell navigationShell;

  void _onTap(BuildContext context, int index) {
    // Navigate to the current location of the branch at the provided index
    navigationShell.goBranch(
      index,
      // A common pattern when using bottom navigation bars is to support
      // navigating to the initial location when tapping the item that is
      // already active.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(syncOfflineProgressProvider);
    final isYouTubeFullScreen = ref.watch(youtubeFullScreenProvider);
    final isOffline = ref.watch(isOfflineProvider);
    final loc = AppLocalizations.of(context)!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        // 1. Maintain clean Scaffold structure
        // Removed extendBody: true to prevent body content from underlapping the NavigationBar
        body: Column(
          children: [
            // 2. Safely render the offline banner at the top
            if (isOffline)
              SafeArea(
                bottom: false,
                child: Container(
                  width: double.infinity,
                  color: Colors.orange.shade800,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: const Text(
                    'Offline Mode - Viewing cached content',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            // 3. Expanded body automatically accommodates StatefulNavigationShell tabs without Stack/Column misuse
            Expanded(child: navigationShell),
          ],
        ),
        // 4. Wrap Bottom Navigation properly with SafeArea to support Android system gestures and diverse screen aspects
        bottomNavigationBar: isYouTubeFullScreen 
          ? null 
          : SafeArea(
              child: NavigationBar(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: (index) => _onTap(context, index),
                // Material 3 styling
                indicatorColor: Theme.of(context).colorScheme.primaryContainer,
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon: const Icon(Icons.home_rounded),
                    label: loc.home,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.quiz_outlined),
                    selectedIcon: const Icon(Icons.quiz_rounded),
                    label: loc.quizzes,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.person_outline_rounded),
                    selectedIcon: const Icon(Icons.person_rounded),
                    label: loc.profile,
                  ),
                ],
              ),
            ),
      ),
    );
  }
}
