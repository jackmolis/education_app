import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';
import 'package:nexora_academy/core/providers/locale_provider.dart';
import 'package:nexora_academy/core/widgets/empty_state_widget.dart';
import 'package:nexora_academy/l10n/app_localizations.dart';
import 'package:nexora_academy/features/courses/presentation/widgets/level_item_widget.dart';
import '../providers/streams_provider.dart';

/// Stream selection screen for High School levels.
/// Fetches streams by level_id and navigates to Option Selection.
class StreamSelectionScreen extends ConsumerWidget {
  final String levelId;
  final String levelName;

  const StreamSelectionScreen({
    super.key,
    required this.levelId,
    required this.levelName,
  });

  // Color palette for stream cards
  static const _streamColors = <Color>[
    Color(0xFF9333EA),
    Color(0xFF4A6CF7),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
    Color(0xFFEF4444),
  ];

  // Icons for stream cards
  static const _streamIcons = <IconData>[
    Icons.science_rounded,
    Icons.calculate_rounded,
    Icons.biotech_rounded,
    Icons.auto_stories_rounded,
    Icons.psychology_rounded,
    Icons.engineering_rounded,
    Icons.account_balance_rounded,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamsAsync = ref.watch(streamsByLevelProvider(levelId));
    final loc = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);

    return AppScaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => context.pop(),
                ),
                Expanded(
                  child: Text(
                    levelName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // ── Subtitle ──
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
            child: Text(
              loc.chooseStream,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // ── Body ──
          Expanded(
            child: streamsAsync.when(
              loading: () => ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                itemCount: 4,
                itemBuilder: (context, index) => const _StreamSkeleton(),
              ),
              error: (err, _) => CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateWidget(
                      icon: Icons.error_outline,
                      title: loc.failedToLoadStreams,
                      actionLabel: loc.tryAgain,
                      onAction: () => ref.invalidate(streamsByLevelProvider(levelId)),
                    ),
                  ),
                ],
              ),
              data: (streams) {
                if (streams.isEmpty) {
                  // If no streams, skip directly to option selection without streamId
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    context.pushReplacement(
                      '/option-selection',
                      extra: {
                        'levelId': levelId,
                        'levelName': levelName,
                      },
                    );
                  });
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4A6CF7)),
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  itemCount: streams.length,
                  itemBuilder: (context, index) {
                    final stream = streams[index];
                    final streamName = stream.getName(locale.languageCode);
                    final color = _streamColors[index % _streamColors.length];
                    final icon = _streamIcons[index % _streamIcons.length];

                    return LevelItemWidget(
                      title: streamName,
                      subtitle: loc.tapToExplore,
                      icon: icon,
                      color: color,
                      index: index,
                      onTap: () {
                        context.push(
                          '/option-selection',
                          extra: {
                            'levelId': levelId,
                            'levelName': '$levelName - $streamName',
                            'streamId': stream.id,
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton placeholder ──
class _StreamSkeleton extends StatelessWidget {
  const _StreamSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
