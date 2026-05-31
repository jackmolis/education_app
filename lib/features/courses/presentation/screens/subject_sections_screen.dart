import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';
import 'package:nexora_academy/l10n/app_localizations.dart';
import '../../domain/models/subject_model.dart';
import '../../../../core/providers/locale_provider.dart';

/// Intermediate screen shown after picking a subject:
///   Level → Subject → SubjectSectionsScreen → Content
///
/// Presents the 4 study sections of a subject. The "Lessons" card routes to
/// the existing lessons screen; the other three open localized placeholders
/// until their content pipelines exist.
class SubjectSectionsScreen extends ConsumerWidget {
  final String levelId;
  final String levelName;
  final String subjectId;
  final SubjectModel? subject;

  const SubjectSectionsScreen({
    super.key,
    required this.levelId,
    required this.levelName,
    required this.subjectId,
    this.subject,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final localeCode = ref.watch(localeProvider).languageCode;
    final subjectName =
        subject != null ? subject!.getName(localeCode) : loc.selectSubject;

    final sections = <_SectionData>[
      _SectionData(
        kind: _SectionKind.lessons,
        label: loc.sectionLessons,
        icon: Icons.play_circle_fill_rounded,
        gradient: const [Color(0xFF4A6CF7), Color(0xFF819DF9)],
      ),
      _SectionData(
        kind: _SectionKind.solvedExercises,
        label: loc.sectionSolvedExercises,
        icon: Icons.checklist_rtl_rounded,
        gradient: const [Color(0xFF10B981), Color(0xFF6EE7B7)],
      ),
      _SectionData(
        kind: _SectionKind.examsSemester1,
        label: loc.sectionExamsSemester1,
        icon: Icons.assignment_rounded,
        gradient: const [Color(0xFFF59E0B), Color(0xFFFCD34D)],
      ),
      _SectionData(
        kind: _SectionKind.examsSemester2,
        label: loc.sectionExamsSemester2,
        icon: Icons.assignment_turned_in_rounded,
        gradient: const [Color(0xFFEC4899), Color(0xFFF9A8D4)],
      ),
    ];

    return AppScaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => context.pop(),
                ),
                Expanded(
                  child: Text(
                    subjectName,
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
              loc.selectSection,
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
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              itemCount: sections.length,
              itemBuilder: (context, index) {
                final section = sections[index];
                return _SectionCard(
                  label: section.label,
                  icon: section.icon,
                  gradient: section.gradient,
                  index: index,
                  onTap: () => _onSectionTap(context, section.kind),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onSectionTap(BuildContext context, _SectionKind kind) {
    if (kind == _SectionKind.lessons) {
      // Route to the EXISTING lessons screen, preserving its expected params.
      context.push(
        '/levels/${Uri.encodeComponent(levelId)}/subjects/${Uri.encodeComponent(subjectId)}/lessons',
        extra: {
          'levelName': levelName,
          'subject': subject,
        },
      );
      return;
    }

    if (kind == _SectionKind.solvedExercises) {
      // Solved Exercises → lesson list (then exercises per lesson).
      context.push(
        '/levels/${Uri.encodeComponent(levelId)}/subjects/${Uri.encodeComponent(subjectId)}/solved-exercises',
        extra: {
          'levelName': levelName,
          'subject': subject,
        },
      );
      return;
    }

    if (kind == _SectionKind.examsSemester1 ||
        kind == _SectionKind.examsSemester2) {
      final semester = kind == _SectionKind.examsSemester1 ? 1 : 2;
      context.push(
        '/levels/${Uri.encodeComponent(levelId)}/subjects/${Uri.encodeComponent(subjectId)}/exams?semester=$semester',
        extra: {
          'levelName': levelName,
          'subject': subject,
        },
      );
      return;
    }

    // Fallback (should not occur) — show placeholder.
    final loc = AppLocalizations.of(context)!;
    context.push(
      '/section-placeholder',
      extra: {'title': loc.sectionLessons},
    );
  }
}

enum _SectionKind { lessons, solvedExercises, examsSemester1, examsSemester2 }

class _SectionData {
  final _SectionKind kind;
  final String label;
  final IconData icon;
  final List<Color> gradient;

  const _SectionData({
    required this.kind,
    required this.label,
    required this.icon,
    required this.gradient,
  });
}

// ══════════════════════════════════════════
// _SectionCard — animated section selector card
// (mirrors the design language of OptionSelectionScreen)
// ══════════════════════════════════════════

class _SectionCard extends StatefulWidget {
  final String label;
  final IconData icon;
  final List<Color> gradient;
  final int index;
  final VoidCallback onTap;

  const _SectionCard({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.index,
    required this.onTap,
  });

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovering = true),
            onExit: (_) => setState(() => _hovering = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _hovering
                        ? widget.gradient[0].withValues(alpha: 0.22)
                        : Colors.black.withValues(alpha: 0.06),
                    blurRadius: _hovering ? 18 : 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: widget.onTap,
                  splashColor: widget.gradient[0].withValues(alpha: 0.12),
                  highlightColor: widget.gradient[0].withValues(alpha: 0.06),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Icon bubble
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: widget.gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Center(
                            child: Icon(
                              widget.icon,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        // Text
                        Expanded(
                          child: Text(
                            widget.label,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        // Arrow
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _hovering
                                ? widget.gradient[0].withValues(alpha: 0.12)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: _hovering
                                ? widget.gradient[0]
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
