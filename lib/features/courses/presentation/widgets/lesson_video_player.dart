import 'dart:async';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/fullscreen_provider.dart';

/// Stable storage path or unique id for the media (not the signed URL).
/// When set, the player only reloads when this changes — not when the signed URL token rotates.
typedef LessonVideoSourceIdentity = String;

class LessonVideoPlayer extends ConsumerStatefulWidget {
  final String videoUrl;

  /// Storage path / logical key (e.g. `lessons/foo.mp4`). Keeps the player alive across rebuilds
  /// when only the signed [videoUrl] query string changes.
  final LessonVideoSourceIdentity? sourceIdentity;

  /// The saved position to seek to on init (network videos only).
  final double startPositionSeconds;

  /// Called periodically with (currentPosition, totalDuration) in seconds.
  final void Function(double position, double duration)? onPositionChanged;

  const LessonVideoPlayer({
    super.key,
    required this.videoUrl,
    this.sourceIdentity,
    this.startPositionSeconds = 0,
    this.onPositionChanged,
  });

  @override
  ConsumerState<LessonVideoPlayer> createState() => _LessonVideoPlayerState();
}

class _LessonVideoPlayerState extends ConsumerState<LessonVideoPlayer> {
  // ── Controllers ──────────────────────────────────────────────────────
  BetterPlayerController? _betterPlayerController;
  YoutubePlayerController? _youtubeController;

  bool _isInitialized = false;
  bool _isYouTube = false;
  double _youtubeDuration = 0.0;

  /// Timer that fires every 3 seconds to persist progress.
  Timer? _progressTimer;

  // ── Local position tracking (always up-to-date) ─────────────────────
  double _lastKnownPositionSec = 0.0;
  double _lastKnownDurationSec = 0.0;

  // ── Fullscreen state ─────────────────────────────────────────────────
  bool _isFullScreen = false;
  OverlayEntry? _fullscreenOverlay;

  /// Saved playback position (seconds) so the overlay player can resume
  /// from exactly where the inline player left off.
  double _savedPositionSec = 0.0;

  /// Avoid repeated seeks when [startPositionSeconds] arrives after first frame.
  bool _appliedInitialResumeSeek = false;

  // ────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ────────────────────────────────────────────────────────────────────

  /// Public method: saves the current playback position immediately.
  /// Returns a Future so callers can AWAIT the save before navigating.
  Future<void> saveCurrentProgress() async {
    double pos = _lastKnownPositionSec;
    double dur = _lastKnownDurationSec;

    if (_isYouTube) {
      if (_youtubeController != null && _youtubeController!.value.isReady) {
        pos = _youtubeController!.value.position.inMilliseconds / 1000.0;
        double d = _youtubeController!.metadata.duration.inMilliseconds / 1000.0;
        if (d <= 0) d = _youtubeDuration;
        if (d > 0) dur = d;
      }
    } else {
      final vpc = _betterPlayerController?.videoPlayerController;
      if (vpc != null) {
        final cPos = vpc.value.position.inMilliseconds / 1000.0;
        final cDur = (vpc.value.duration?.inMilliseconds ?? 0) / 1000.0;
        if (cDur > 0 && cPos >= 0) {
          pos = cPos;
          dur = cDur;
        }
      }
    }

    debugPrint('[VideoProgress] saveCurrentProgress() → pos=${pos.toStringAsFixed(1)}s  dur=${dur.toStringAsFixed(1)}s');

    if (dur > 0 && widget.onPositionChanged != null) {
      // Await so the Supabase upsert completes before we pop
      await Future(() => widget.onPositionChanged!(pos, dur));
      debugPrint('[VideoProgress] saveCurrentProgress() → DONE');
    }
  }

  bool _checkIsYouTubeUrl(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  String get _logicalSourceKey =>
      widget.sourceIdentity?.isNotEmpty == true ? widget.sourceIdentity! : widget.videoUrl;

  static bool _isHlsUrl(String url) {
    final u = url.toLowerCase();
    return u.contains('.m3u8') || u.contains('application/x-mpegurl');
  }

  BetterPlayerDataSource _networkDataSource(String url) {
    final isHls = _isHlsUrl(url);
    // Stable cache key across signed URL refreshes (Android disk cache).
    final cacheKey = widget.sourceIdentity?.isNotEmpty == true
        ? widget.sourceIdentity
        : Uri.tryParse(url)?.path;

    return BetterPlayerDataSource.network(
      url,
      videoFormat: isHls ? BetterPlayerVideoFormat.hls : null,
      useAsmsTracks: isHls,
      useAsmsSubtitles: true,
      useAsmsAudioTracks: true,
      liveStream: false,
      cacheConfiguration: BetterPlayerCacheConfiguration(
        useCache: true,
        maxCacheSize: 500 * 1024 * 1024,
        maxCacheFileSize: 200 * 1024 * 1024,
        preCacheSize: 10 * 1024 * 1024,
        key: cacheKey,
      ),
      // Tuned for VOD streaming: fewer rebuffers, caps max buffer to limit bandwidth (Android ExoPlayer).
      bufferingConfiguration: const BetterPlayerBufferingConfiguration(
        minBufferMs: 15000,
        maxBufferMs: 50000,
        bufferForPlaybackMs: 2500,
        bufferForPlaybackAfterRebufferMs: 5000,
      ),
      notificationConfiguration: const BetterPlayerNotificationConfiguration(
        showNotification: false,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _isYouTube = _checkIsYouTubeUrl(widget.videoUrl);

    if (_isYouTube) {
      _initYouTubePlayer();
    } else {
      _initBetterPlayer();
    }
  }

  @override
  void didUpdateWidget(covariant LessonVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    final wasYouTube = _checkIsYouTubeUrl(oldWidget.videoUrl);
    final nowYouTube = _checkIsYouTubeUrl(widget.videoUrl);

    if (wasYouTube != nowYouTube) {
      _progressTimer?.cancel();
      _betterPlayerController?.dispose();
      _betterPlayerController = null;
      _youtubeController?.dispose();
      _youtubeController = null;
      _isInitialized = false;
      _isYouTube = nowYouTube;
      if (nowYouTube) {
        _initYouTubePlayer();
      } else {
        _initBetterPlayer();
      }
      return;
    }

    if (_isYouTube) {
      if (oldWidget.videoUrl != widget.videoUrl) {
        _youtubeController?.dispose();
        _youtubeController = null;
        _isInitialized = false;
        _initYouTubePlayer();
      }
      return;
    }

    // Same non-YouTube lesson: avoid full reload when only parent rebuilds.
    final oldKey = oldWidget.sourceIdentity?.isNotEmpty == true
        ? oldWidget.sourceIdentity!
        : oldWidget.videoUrl;
    final newKey = _logicalSourceKey;

    if (oldKey != newKey) {
      _progressTimer?.cancel();
      _betterPlayerController?.dispose();
      _betterPlayerController = null;
      _isInitialized = false;
      _appliedInitialResumeSeek = false;
      _initBetterPlayer();
      return;
    }

    // Signed URL rotation for the same file: swap data source, keep playback position.
    if (oldWidget.videoUrl != widget.videoUrl) {
      _swapNetworkUrlPreservePosition();
    }

    // Resume progress loaded after first build (Supabase).
    if (!_isYouTube &&
        _betterPlayerController != null &&
        _isInitialized &&
        !_appliedInitialResumeSeek &&
        oldWidget.startPositionSeconds < 1 &&
        widget.startPositionSeconds > 3) {
      _appliedInitialResumeSeek = true;
      _seekResume(widget.startPositionSeconds);
    }
  }

  Future<void> _swapNetworkUrlPreservePosition() async {
    final c = _betterPlayerController;
    if (c == null) return;

    double posSec = 0;
    final vpc = c.videoPlayerController;
    if (vpc != null) {
      posSec = vpc.value.position.inMilliseconds / 1000.0;
    }

    final ds = _networkDataSource(widget.videoUrl);
    try {
      await c.setupDataSource(ds);
      if (posSec > 0.5 && mounted) {
        await c.seekTo(Duration(milliseconds: (posSec * 1000).round()));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isInitialized = false);
      }
    }
  }

  Future<void> _seekResume(double seconds) async {
    final c = _betterPlayerController;
    if (c == null) return;
    await c.seekTo(Duration(milliseconds: (seconds * 1000).round()));
  }

  @override
  void dispose() {
    _exitFullScreen(restoreUI: false); // clean up overlay if still open
    _progressTimer?.cancel();

    // Save final position on dispose — try reading directly from the
    // controller first (most accurate). Fall back to locally tracked
    // values only if the controller is already torn down.
    double finalPos = _lastKnownPositionSec;
    double finalDur = _lastKnownDurationSec;

    if (_isYouTube) {
      if (_youtubeController != null && _youtubeController!.value.isReady) {
        finalPos = _youtubeController!.value.position.inMilliseconds / 1000.0;
        double dur = _youtubeController!.metadata.duration.inMilliseconds / 1000.0;
        if (dur <= 0) dur = _youtubeDuration;
        if (dur > 0) finalDur = dur;
      }
    } else {
      final vpc = _betterPlayerController?.videoPlayerController;
      if (vpc != null) {
        final controllerPos = vpc.value.position.inMilliseconds / 1000.0;
        final controllerDur = (vpc.value.duration?.inMilliseconds ?? 0) / 1000.0;
        // Only use controller values if they look valid (not zeroed out)
        if (controllerDur > 0 && controllerPos >= 0) {
          finalPos = controllerPos;
          finalDur = controllerDur;
        }
      }
    }

    debugPrint('[VideoProgress] dispose() → saving position: ${finalPos.toStringAsFixed(1)}s / ${finalDur.toStringAsFixed(1)}s');

    if (finalDur > 0) {
      widget.onPositionChanged?.call(finalPos, finalDur);
    }

    // Always restore normal UI on dispose
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    _betterPlayerController?.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }

  // ────────────────────────────────────────────────────────────────────
  // YouTube init
  // ────────────────────────────────────────────────────────────────────
  void _initYouTubePlayer() {
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
    if (videoId != null) {
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
      );
      setState(() => _isInitialized = true);
    }
  }

  // ────────────────────────────────────────────────────────────────────
  // BetterPlayer init (storage / HLS / progressive)
  // ────────────────────────────────────────────────────────────────────
  void _initBetterPlayer() {
    final startAt = widget.startPositionSeconds > 0
        ? Duration(milliseconds: (widget.startPositionSeconds * 1000).round())
        : null;

    if (widget.startPositionSeconds > 3) {
      _appliedInitialResumeSeek = true;
    }

    final controlsConfig = BetterPlayerControlsConfiguration(
      enablePlaybackSpeed: true,
      enableFullscreen: true,
      enableProgressBar: true,
      enableProgressText: true,
      enableSkips: false,
      playbackSpeedIcon: Icons.speed,
      controlBarColor: Colors.black.withValues(alpha: 0.7),
      iconsColor: Colors.white,
      progressBarPlayedColor: const Color(0xFF6C63FF),
      progressBarHandleColor: const Color(0xFF6C63FF),
      progressBarBufferedColor: Colors.white30,
      progressBarBackgroundColor: Colors.black38,
    );

    final configuration = BetterPlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
      autoPlay: false,
      looping: false,
      startAt: startAt,
      fullScreenByDefault: false,
      allowedScreenSleep: false,
      autoDetectFullscreenAspectRatio: true,
      autoDetectFullscreenDeviceOrientation: true,
      deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
      controlsConfiguration: controlsConfig,
      // Reduces flicker when the same widget subtree rebuilds.
      handleLifecycle: true,
    );

    final dataSource = _networkDataSource(widget.videoUrl);

    _betterPlayerController = BetterPlayerController(configuration);

    // Add event listener to track position in real-time
    _betterPlayerController!.addEventsListener((event) {
      if (event.betterPlayerEventType == BetterPlayerEventType.progress) {
        final vpc = _betterPlayerController?.videoPlayerController;
        if (vpc != null) {
          final pos = vpc.value.position.inMilliseconds / 1000.0;
          final dur = vpc.value.duration?.inMilliseconds ?? 0;
          if (dur > 0) {
            _lastKnownPositionSec = pos;
            _lastKnownDurationSec = dur / 1000.0;
          }
        }
      }
    });

    _betterPlayerController!.setupDataSource(dataSource).then((_) {
      if (mounted) {
        setState(() => _isInitialized = true);
        _startProgressTimer();
      }
    });
  }

  // ────────────────────────────────────────────────────────────────────
  // Progress timer
  // ────────────────────────────────────────────────────────────────────
  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_isYouTube) {
        if (_youtubeController == null || !_youtubeController!.value.isReady) return;

        final pos = _youtubeController!.value.position.inMilliseconds / 1000.0;
        double dur = _youtubeController!.metadata.duration.inMilliseconds / 1000.0;
        if (dur <= 0) dur = _youtubeDuration;

        // Always update local tracking (even when paused)
        if (dur > 0) {
          _lastKnownPositionSec = pos;
          _lastKnownDurationSec = dur;
        }

        // Only persist to Supabase when actually playing
        if (_youtubeController!.value.isPlaying && (pos > 0 || dur > 0)) {
          widget.onPositionChanged?.call(pos, dur > 0 ? dur : pos);
        }
      } else {
        if (_betterPlayerController == null) return;

        final pos = _betterPlayerController!.videoPlayerController?.value.position.inMilliseconds ?? 0;
        final dur = _betterPlayerController!.videoPlayerController?.value.duration?.inMilliseconds ?? 0;

        // Always update local tracking (even when paused)
        if (dur > 0) {
          _lastKnownPositionSec = pos / 1000.0;
          _lastKnownDurationSec = dur / 1000.0;
        }

        // Only persist to Supabase when actually playing
        final isPlaying = _betterPlayerController!.isPlaying() ?? false;
        if (isPlaying && dur > 0) {
          widget.onPositionChanged?.call(pos / 1000.0, dur / 1000.0);
        }
      }
    });
  }

  // ────────────────────────────────────────────────────────────────────
  // Fullscreen — enter / exit
  // ────────────────────────────────────────────────────────────────────
  void _toggleFullScreen() {
    if (_isFullScreen) {
      _exitFullScreen();
    } else {
      _enterFullScreen();
    }
  }

  void _enterFullScreen() {
    if (_youtubeController == null) return;

    // Snapshot the current playback position so the overlay player can
    // seek to it once the WebView is ready.
    if (_youtubeController!.value.isReady) {
      _savedPositionSec =
          _youtubeController!.value.position.inMilliseconds / 1000.0;
    }

    // Force landscape + hide system UI
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Notify MainShellScreen to hide BottomNavigationBar.
    // Uses ref.read (not ref.watch) so THIS widget is not rebuilt.
    ref.read(youtubeFullScreenProvider.notifier).state = true;

    setState(() => _isFullScreen = true);

    // Insert an overlay that covers the entire screen.
    // The overlay uses the SAME _youtubeController so video state is shared.
    _fullscreenOverlay = OverlayEntry(
      builder: (overlayContext) => PopScope(
        // Intercept back button → exit fullscreen instead of popping route.
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _exitFullScreen();
        },
        child: Material(
          color: Colors.black,
          child: Stack(
            children: [
              // Centered YouTube player (same controller)
              Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: YoutubePlayer(
                    controller: _youtubeController!,
                    showVideoProgressIndicator: true,
                    progressIndicatorColor: const Color(0xFF6C63FF),
                    progressColors: const ProgressBarColors(
                      playedColor: Color(0xFF6C63FF),
                      handleColor: Color(0xFF8B83FF),
                    ),
                    onReady: () {
                      // Resume from the saved position
                      if (_savedPositionSec > 0) {
                        _youtubeController!.seekTo(
                          Duration(
                            milliseconds:
                                (_savedPositionSec * 1000).round(),
                          ),
                          allowSeekAhead: true,
                        );
                      }
                      _youtubeController!.play();
                    },
                  ),
                ),
              ),

              // Exit‑fullscreen button (top-left)
              Positioned(
                top: 16,
                left: 16,
                child: SafeArea(
                  child: _buildFullScreenButton(
                    icon: Icons.fullscreen_exit,
                    onTap: _exitFullScreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_fullscreenOverlay!);
  }

  void _exitFullScreen({bool restoreUI = true}) {
    // Snapshot position from the overlay player before removing it.
    if (_youtubeController != null && _youtubeController!.value.isReady) {
      _savedPositionSec =
          _youtubeController!.value.position.inMilliseconds / 1000.0;
    }

    _fullscreenOverlay?.remove();
    _fullscreenOverlay = null;

    if (restoreUI) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      ref.read(youtubeFullScreenProvider.notifier).state = false;
      if (mounted) setState(() => _isFullScreen = false);
    }
  }

  // ────────────────────────────────────────────────────────────────────
  // UI builders
  // ────────────────────────────────────────────────────────────────────

  /// Rounded, semi-transparent fullscreen toggle button.
  Widget _buildFullScreenButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildBetterPlayer() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: BetterPlayer(
          key: ValueKey(_logicalSourceKey),
          controller: _betterPlayerController!,
        ),
      ),
    );
  }

  Widget _buildYouTubePlayer() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: YoutubePlayer(
            controller: _youtubeController!,
            showVideoProgressIndicator: true,
            progressIndicatorColor: const Color(0xFF6C63FF),
            progressColors: const ProgressBarColors(
              playedColor: Color(0xFF6C63FF),
              handleColor: Color(0xFF8B83FF),
            ),
            onReady: () {
              setState(() {
                _youtubeDuration =
                    _youtubeController!.metadata.duration.inMilliseconds /
                        1000.0;
              });
              // Seek to saved position (either from initial prop or from
              // returning from fullscreen).
              final seekTo = _savedPositionSec > 0
                  ? _savedPositionSec
                  : widget.startPositionSeconds;
              if (seekTo > 0) {
                _youtubeController!.seekTo(
                  Duration(milliseconds: (seekTo * 1000).round()),
                  allowSeekAhead: true,
                );
              }
              _startProgressTimer();
            },
          ),
        ),

        // Enter-fullscreen button (bottom-right)
        Positioned(
          bottom: 12,
          right: 12,
          child: _buildFullScreenButton(
            icon: Icons.fullscreen,
            onTap: _toggleFullScreen,
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────
  // Build
  // ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_isYouTube && _youtubeController != null) {
      // While the overlay is showing the fullscreen player, keep a
      // black placeholder in the inline slot so the parent layout
      // remains stable (no jump on exit).
      if (_isFullScreen) {
        return Container(
          height: 220,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
          ),
        );
      }
      return _buildYouTubePlayer();
    } else if (!_isYouTube && _betterPlayerController != null) {
      return _buildBetterPlayer();
    } else {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'Failed to load video.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }
}
