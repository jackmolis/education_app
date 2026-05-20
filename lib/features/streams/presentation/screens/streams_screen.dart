import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';
import 'package:nexora_academy/core/providers/locale_provider.dart';
import 'package:nexora_academy/l10n/app_localizations.dart';

import 'package:nexora_academy/features/courses/presentation/widgets/level_item_widget.dart';
import '../providers/streams_provider.dart';

class StreamsScreen extends ConsumerWidget {
  final String levelId;
  final String levelName;

  const StreamsScreen({
    super.key,
    required this.levelId,
    required this.levelName,
  });

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
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48), // Balance for back button
              ],
            ),
          ),
          
          Expanded(
            child: streamsAsync.when(
              loading: () => ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                itemCount: 4,
                itemBuilder: (context, index) => const _StreamItemSkeleton(),
              ),
              error: (err, stack) => Center(
                child: Text('Error loading streams: $err'),
              ),
              data: (streams) {
                // FALLBACK: If there are no streams configured for this level,
                // bounce directly to SubjectsPage natively.
                if (streams.isEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    context.replace(
                      '/level-subjects',
                      extra: {
                        'levelId': levelId,
                        'levelName': levelName,
                      },
                    );
                  });
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  itemCount: streams.length,
                  itemBuilder: (context, index) {
                    final stream = streams[index];
                    final streamName = stream.getName(locale.languageCode);
                    
                    return LevelItemWidget(
                      title: streamName,
                      subtitle: loc.tapToExplore, 
                      icon: Icons.account_tree_rounded, // Specific icon for streams
                      color: Colors.blueAccent,
                      index: index,
                      onTap: () {
                        context.push(
                          '/level-subjects',
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

class _StreamItemSkeleton extends StatelessWidget {
  const _StreamItemSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
