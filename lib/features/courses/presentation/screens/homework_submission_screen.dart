
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';
import 'package:nexora_academy/core/widgets/shimmer_loaders.dart';
import 'package:nexora_academy/l10n/app_localizations.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../domain/models/home_assignment_model.dart';

import '../providers/home_assignments_provider.dart';

import '../providers/storage_provider.dart';

class HomeworkSubmissionScreen extends ConsumerStatefulWidget {
  final String assignmentId;
  final String levelId;
  final String subjectId;

  const HomeworkSubmissionScreen({
    super.key,
    required this.assignmentId,
    required this.levelId,
    required this.subjectId,
  });

  @override
  ConsumerState<HomeworkSubmissionScreen> createState() =>
      _HomeworkSubmissionScreenState();
}

class _HomeworkSubmissionScreenState
    extends ConsumerState<HomeworkSubmissionScreen> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final localeCode = ref.watch(localeProvider).languageCode;
    final assignmentAsync =
        ref.watch(homeAssignmentsProvider(widget.subjectId));
    return AppScaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, loc),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: assignmentAsync.when(
                loading: () => const ShimmerListLoader(
                    itemCount: 2, itemHeight: 120),
                error: (e, _) => Center(
                    child: Text('Failed to load: $e',
                        style: const TextStyle(color: Colors.red))),
                data: (assignments) {
                  final assignment = assignments.isEmpty
                      ? null
                      : assignments.firstWhere(
                          (a) => a.id == widget.assignmentId,
                          orElse: () => assignments.first);

                  if (assignment == null) {
                    return const Center(child: Text('Assignment not found'));
                  }

                  return Column(
                    children: [
                      _AssignmentInfoCard(
                        assignment: assignment,
                        localeCode: localeCode,
                        onOpenPdf: () =>
                            _openPdf(context, assignment, localeCode),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPdf(BuildContext context, HomeAssignmentModel assignment,
      String localeCode) async {
    final title = assignment.getTitle(localeCode);
    try {
      final signedUrl =
          await ref.read(lessonMediaUrlProvider(assignment.pdfUrl).future);
      if (signedUrl.isEmpty) return;
      if (mounted) {
        context.push('/pdf-viewer', extra: {
          'pdfUrl': signedUrl,
          'title': title,
          'lessonId': 'assignment_${assignment.id}',
        });
      }
    } catch (_) {}
  }

  Widget _buildHeader(BuildContext context, AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Text(
              loc.sectionHomeAssignments,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 20),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _AssignmentInfoCard extends StatelessWidget {
  final HomeAssignmentModel assignment;
  final String localeCode;
  final VoidCallback? onOpenPdf;

  const _AssignmentInfoCard({
    required this.assignment,
    required this.localeCode,
    this.onOpenPdf,
  });

  @override
  Widget build(BuildContext context) {
    final title = assignment.getTitle(localeCode);
    final description = assignment.getDescription(localeCode);

    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.home_work_rounded,
                  color: Color(0xFF6366F1), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title.isNotEmpty ? title : 'Assignment',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(description,
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5),
                maxLines: 4,
                overflow: TextOverflow.ellipsis),
          ],
          if (assignment.hasPdf && onOpenPdf != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenPdf,
                icon: const Icon(Icons.picture_as_pdf_rounded,
                    color: Color(0xFFF97316), size: 20),
                label: const Text('Open PDF',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B))),
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
    );
  }
}
