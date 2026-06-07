import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';
import 'package:nexora_academy/core/widgets/shimmer_loaders.dart';
import 'package:nexora_academy/core/widgets/empty_state_widget.dart';
import 'package:nexora_academy/core/widgets/tap_scale_wrapper.dart';
import 'package:nexora_academy/l10n/app_localizations.dart';
import '../../domain/models/subject_model.dart';
import '../../domain/models/home_assignment_model.dart';
import '../../../../core/providers/locale_provider.dart';
import '../providers/home_assignments_provider.dart';
import '../providers/homework_provider.dart';
import '../providers/storage_provider.dart';

/// Home Assignments list for a subject.
/// Level → Subject → Sections → HomeAssignmentsScreen
class HomeAssignmentsScreen extends ConsumerWidget {
  final String levelId;
  final String levelName;
  final String subjectId;
  final SubjectModel? subject;

  const HomeAssignmentsScreen({
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
    final assignmentsAsync = ref.watch(homeAssignmentsProvider(subjectId));

    final subjectName =
        subject != null ? subject!.getName(localeCode) : loc.sectionHomeAssignments;

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
                  child: Column(
                    children: [
                      Text(
                        subjectName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 20),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        loc.sectionHomeAssignments,
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

          Expanded(
            child: assignmentsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(20.0),
                child: ShimmerListLoader(itemCount: 5, itemHeight: 110),
              ),
              error: (e, _) => CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateWidget(
                      icon: Icons.error_outline,
                      title: loc.failedToLoadAssignments,
                      actionLabel: loc.tryAgain,
                      onAction: () =>
                          ref.invalidate(homeAssignmentsProvider(subjectId)),
                    ),
                  ),
                ],
              ),
              data: (assignments) {
                if (assignments.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.home_work_outlined,
                    title: loc.noAssignmentsYet,
                    subtitle: loc.assignmentsAppearHere,
                    actionLabel: loc.refresh,
                    onAction: () =>
                        ref.invalidate(homeAssignmentsProvider(subjectId)),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(homeAssignmentsProvider(subjectId));
                    await ref.read(homeAssignmentsProvider(subjectId).future);
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    itemCount: assignments.length,
                    itemBuilder: (context, index) {
                      final a = assignments[index];
                      return _AssignmentCardWithStatus(
                        index: index,
                        assignment: a,
                        levelId: levelId,
                        subjectId: subjectId,
                        localeCode: localeCode,
                        openPdfLabel: loc.openPdf,
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

class _AssignmentCardWithStatus extends ConsumerWidget {
  final int index;
  final HomeAssignmentModel assignment;
  final String levelId;
  final String subjectId;
  final String localeCode;
  final String openPdfLabel;

  const _AssignmentCardWithStatus({
    required this.index,
    required this.assignment,
    required this.levelId,
    required this.subjectId,
    required this.localeCode,
    required this.openPdfLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionAsync =
        ref.watch(studentSubmissionProvider(assignment.id));

    final status = submissionAsync.valueOrNull;
    final String statusLabel;
    final Color statusColor;
    final IconData statusIcon;

    if (status == null) {
      statusLabel = '';
      statusColor = Colors.transparent;
      statusIcon = Icons.circle;
    } else if (status.isGraded) {
      statusLabel = 'Graded';
      statusColor = const Color(0xFF10B981);
      statusIcon = Icons.check_circle_rounded;
    } else {
      statusLabel = 'Pending';
      statusColor = const Color(0xFFF59E0B);
      statusIcon = Icons.schedule_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TapScaleWrapper(
        onTap: () {
          context.push(
            '/levels/${Uri.encodeComponent(levelId)}/subjects/${Uri.encodeComponent(subjectId)}/assignments/${Uri.encodeComponent(assignment.id)}/submit',
          );
        },
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      assignment.getTitle(localeCode).isNotEmpty
                          ? assignment.getTitle(localeCode)
                          : 'Assignment ${index + 1}',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (statusLabel.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon,
                              size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (assignment.getDescription(localeCode).isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  assignment.getDescription(localeCode),
                  style: TextStyle(
                      fontSize: 14, color: Colors.grey[700], height: 1.5),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (assignment.hasPdf) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        final signedUrl = await ref
                            .read(lessonMediaUrlProvider(
                                    assignment.pdfUrl)
                                .future);
                        if (signedUrl.isEmpty) return;
                        context.push('/pdf-viewer', extra: {
                          'pdfUrl': signedUrl,
                          'title': assignment.getTitle(localeCode),
                          'lessonId':
                              'assignment_${assignment.id}',
                        });
                      } catch (_) {}
                    },
                    icon: const Icon(Icons.picture_as_pdf_rounded,
                        color: Color(0xFFF97316), size: 20),
                    label: Text(
                      openPdfLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B)),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


