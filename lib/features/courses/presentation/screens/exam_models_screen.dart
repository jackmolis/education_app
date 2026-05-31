import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';
import 'package:nexora_academy/core/widgets/shimmer_loaders.dart';
import 'package:nexora_academy/core/widgets/empty_state_widget.dart';
import 'package:nexora_academy/l10n/app_localizations.dart';
import '../../domain/models/exam_model.dart';
import '../../../../core/providers/locale_provider.dart';
import '../providers/exams_provider.dart';
import '../providers/storage_provider.dart';

/// Models (Modèles / النماذج) list for a single exam.
/// Subject → Semester Exams → ExamModelsScreen → Open Exam/Correction PDF
class ExamModelsScreen extends ConsumerWidget {
  final ExamModel exam;

  const ExamModelsScreen({super.key, required this.exam});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final localeCode = ref.watch(localeProvider).languageCode;
    final modelsAsync = ref.watch(examModelsProvider(exam.id));

    final examTitle = exam.getTitle(localeCode);

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
                        examTitle.isNotEmpty
                            ? examTitle
                            : loc.examNumber(exam.orderNumber),
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
                        loc.examModels,
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
            child: modelsAsync.when(
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
                      title: loc.failedToLoadExamModels,
                      actionLabel: loc.tryAgain,
                      onAction: () =>
                          ref.invalidate(examModelsProvider(exam.id)),
                    ),
                  ),
                ],
              ),
              data: (models) {
                if (models.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.folder_open_outlined,
                    title: loc.noExamModelsYet,
                    subtitle: loc.examModelsAppearHere,
                    actionLabel: loc.refresh,
                    onAction: () =>
                        ref.invalidate(examModelsProvider(exam.id)),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(examModelsProvider(exam.id));
                    await ref.read(examModelsProvider(exam.id).future);
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    itemCount: models.length,
                    itemBuilder: (context, index) {
                      final model = models[index];
                      final number =
                          model.modelNumber > 0 ? model.modelNumber : index + 1;
                      final modelTitle = model.getTitle(localeCode);
                      final displayTitle = modelTitle.isNotEmpty
                          ? modelTitle
                          : loc.modelNumber(number);
                      return _ExamModelCard(
                        number: number,
                        title: displayTitle,
                        hasExamPdf: model.hasExamPdf,
                        hasCorrectionPdf: model.hasCorrectionPdf,
                        openExamLabel: loc.openExamPdf,
                        openCorrectionLabel: loc.openCorrectionPdf,
                        noResourcesLabel: loc.noResourcesAvailable,
                        onOpenExam: model.hasExamPdf
                            ? () => _openPdf(
                                  context,
                                  ref,
                                  path: model.examPdfUrl,
                                  title: displayTitle,
                                  tag: 'exam_model_${model.id}',
                                )
                            : null,
                        onOpenCorrection: model.hasCorrectionPdf
                            ? () => _openPdf(
                                  context,
                                  ref,
                                  path: model.correctionPdfUrl,
                                  title: loc.openCorrectionPdf,
                                  tag: 'exam_model_corr_${model.id}',
                                )
                            : null,
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

  Future<void> _openPdf(
    BuildContext context,
    WidgetRef ref, {
    required String path,
    required String title,
    required String tag,
  }) async {
    final router = GoRouter.of(context);
    try {
      final signedUrl = await ref.read(lessonMediaUrlProvider(path).future);
      if (signedUrl.isEmpty) return;
      router.push(
        '/pdf-viewer',
        extra: {
          'pdfUrl': signedUrl,
          'title': title,
          'lessonId': tag,
        },
      );
    } catch (_) {
      // Silently ignore — the button stays interactive for a retry.
    }
  }
}

class _ExamModelCard extends StatelessWidget {
  final int number;
  final String title;
  final bool hasExamPdf;
  final bool hasCorrectionPdf;
  final String openExamLabel;
  final String openCorrectionLabel;
  final String noResourcesLabel;
  final VoidCallback? onOpenExam;
  final VoidCallback? onOpenCorrection;

  const _ExamModelCard({
    required this.number,
    required this.title,
    required this.hasExamPdf,
    required this.hasCorrectionPdf,
    required this.openExamLabel,
    required this.openCorrectionLabel,
    required this.noResourcesLabel,
    required this.onOpenExam,
    required this.onOpenCorrection,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFEC4899);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (hasExamPdf)
              _PdfActionButton(
                label: openExamLabel,
                icon: Icons.description_rounded,
                color: const Color(0xFF4A6CF7),
                onTap: onOpenExam!,
              ),
            if (hasCorrectionPdf) ...[
              if (hasExamPdf) const SizedBox(height: 10),
              _PdfActionButton(
                label: openCorrectionLabel,
                icon: Icons.fact_check_rounded,
                color: const Color(0xFF10B981),
                onTap: onOpenCorrection!,
              ),
            ],
            if (!hasExamPdf && !hasCorrectionPdf)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  noResourcesLabel,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PdfActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PdfActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              Icon(Icons.open_in_new_rounded,
                  color: Colors.grey[400], size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
