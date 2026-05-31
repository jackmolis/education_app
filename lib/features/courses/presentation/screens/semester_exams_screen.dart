import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';
import 'package:nexora_academy/core/widgets/shimmer_loaders.dart';
import 'package:nexora_academy/core/widgets/empty_state_widget.dart';
import 'package:nexora_academy/core/widgets/tap_scale_wrapper.dart';
import 'package:nexora_academy/l10n/app_localizations.dart';
import '../../domain/models/subject_model.dart';
import '../../../../core/providers/locale_provider.dart';
import '../providers/exams_provider.dart';

/// Exam list for a subject in a given semester (1 or 2).
/// Level → Subject → Sections → SemesterExamsScreen → ExamDetailsScreen
class SemesterExamsScreen extends ConsumerWidget {
  final String levelId;
  final String levelName;
  final String subjectId;
  final int semester;
  final SubjectModel? subject;

  const SemesterExamsScreen({
    super.key,
    required this.levelId,
    required this.levelName,
    required this.subjectId,
    required this.semester,
    this.subject,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final localeCode = ref.watch(localeProvider).languageCode;
    final args = (subjectId: subjectId, semester: semester);
    final examsAsync = ref.watch(examsProvider(args));

    final sectionTitle = semester == 1
        ? loc.sectionExamsSemester1
        : loc.sectionExamsSemester2;
    final subjectName =
        subject != null ? subject!.getName(localeCode) : sectionTitle;

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
                  child: Column(
                    children: [
                      Text(
                        subjectName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sectionTitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // ── Body ──
          Expanded(
            child: examsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(20.0),
                child: ShimmerListLoader(itemCount: 5, itemHeight: 96),
              ),
              error: (e, _) => CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateWidget(
                      icon: Icons.error_outline,
                      title: loc.failedToLoadExams,
                      actionLabel: loc.tryAgain,
                      onAction: () => ref.invalidate(examsProvider(args)),
                    ),
                  ),
                ],
              ),
              data: (exams) {
                if (exams.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.assignment_outlined,
                    title: loc.noExamsYet,
                    subtitle: loc.examsAppearHere,
                    actionLabel: loc.refresh,
                    onAction: () => ref.invalidate(examsProvider(args)),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(examsProvider(args));
                    await ref.read(examsProvider(args).future);
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    itemCount: exams.length,
                    itemBuilder: (context, index) {
                      final exam = exams[index];
                      final title = exam.getTitle(localeCode);
                      final description = exam.getDescription(localeCode);

                      return _ExamCard(
                        index: index,
                        title: title.isNotEmpty
                            ? title
                            : loc.examNumber(exam.orderNumber),
                        description: description,
                        examNumberLabel: loc.examNumber(
                            exam.orderNumber > 0 ? exam.orderNumber : index + 1),
                        onTap: () {
                          context.push(
                            '/levels/${Uri.encodeComponent(levelId)}/subjects/${Uri.encodeComponent(subjectId)}/exams/${Uri.encodeComponent(exam.id)}',
                            extra: {'exam': exam},
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final int index;
  final String title;
  final String description;
  final String examNumberLabel;
  final VoidCallback onTap;

  const _ExamCard({
    required this.index,
    required this.title,
    required this.description,
    required this.examNumberLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFEC4899);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TapScaleWrapper(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(Icons.assignment_rounded,
                      color: accent, size: 22),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      examNumberLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.grey[300], size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
