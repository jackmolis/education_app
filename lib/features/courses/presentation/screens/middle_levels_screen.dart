import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';
import 'package:nexora_academy/l10n/app_localizations.dart';
import '../widgets/level_item_widget.dart';

class MiddleLevelsScreen extends StatelessWidget {
  const MiddleLevelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final levels = [
      {'title': loc.middleGrade1, 'id': 'middle_1'},
      {'title': loc.middleGrade2, 'id': 'middle_2'},
      {'title': loc.middleGrade3, 'id': 'middle_3'},
    ];

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
                    loc.middleSchool,
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
              itemCount: levels.length,
              itemBuilder: (context, index) {
                final level = levels[index];
                return LevelItemWidget(
                  title: level['title']!,
                  subtitle: loc.tapToExplore,
                  icon: Icons.school_rounded,
                  color: Colors.blueAccent,
                  index: index,
                  onTap: () {
                    context.push(
                      '/option-selection',
                      extra: {
                        'levelId': level['id'],
                        'levelName': level['title'],
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
