import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';
import 'package:nexora_academy/l10n/app_localizations.dart';
import '../widgets/level_item_widget.dart';

class StreamsScreen extends StatelessWidget {
  final String levelId;
  final String levelName;

  const StreamsScreen({
    super.key,
    required this.levelId,
    required this.levelName,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    List<Map<String, String>> streams = [];

    if (levelId == 'tc') {
      streams = [
        {'title': loc.scientific, 'id': 'scientific'},
        {'title': loc.literary, 'id': 'literary'},
        {'title': loc.technological, 'id': 'technological'},
        {'title': loc.original, 'id': 'original'},
      ];
    } else {
      // 1bac or 2bac
      streams = [
        {'title': loc.sciMath, 'id': 'science_math'},
        {'title': loc.physics, 'id': 'physics'},
        {'title': loc.svt, 'id': 'svt'},
        {'title': loc.economics, 'id': 'economics'},
        {'title': loc.humanities, 'id': 'humanities'},
        {'title': loc.literature, 'id': 'literature'},
        {'title': loc.electricalTech, 'id': 'electrical_tech'},
        {'title': loc.mechanicalTech, 'id': 'mechanical_tech'},
        {'title': loc.original, 'id': 'original'},
      ];
    }

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
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              itemCount: streams.length,
              itemBuilder: (context, index) {
                final stream = streams[index];
                return LevelItemWidget(
                  title: stream['title']!,
                  subtitle: loc.tapToExplore,
                  icon: Icons.account_tree_rounded,
                  color: const Color(0xFF4A90E2),
                  index: index,
                  onTap: () {
                    context.push(
                      '/level-subjects',
                      extra: {
                        'levelId': levelId,
                        'levelName': '$levelName - ${stream['title']}',
                        'streamId': stream['id'],
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
