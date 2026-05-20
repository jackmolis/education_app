import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global provider that tracks whether the YouTube player is currently in fullscreen.
/// Used by [MainShellScreen] to hide the BottomNavigationBar during fullscreen playback.
final youtubeFullScreenProvider = StateProvider<bool>((ref) => false);
