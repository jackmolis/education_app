import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';
import 'package:nexora_academy/core/widgets/shimmer_loaders.dart';
import 'package:nexora_academy/l10n/app_localizations.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../domain/models/home_assignment_model.dart';
import '../../domain/models/homework_submission_model.dart';
import '../providers/home_assignments_provider.dart';
import '../providers/homework_provider.dart';
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
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  String? _selectedFileExt;
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.bytes == null) return;
    setState(() {
      _selectedFileBytes = file.bytes;
      _selectedFileName = file.name;
      final ext = file.name.contains('.')
          ? file.name.split('.').last
          : 'pdf';
      _selectedFileExt = ext;
    });
  }

  Future<void> _submit() async {
    if (_selectedFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file first.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(submitHomeworkControllerProvider.notifier).submit(
            fileBytes: _selectedFileBytes!,
            extension: _selectedFileExt ?? 'pdf',
            assignmentId: widget.assignmentId,
            notes: _notesController.text.trim(),
          );
      if (mounted) {
        ref.invalidate(studentSubmissionProvider(widget.assignmentId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final localeCode = ref.watch(localeProvider).languageCode;
    final assignmentAsync =
        ref.watch(homeAssignmentsProvider(widget.subjectId));
    final submissionAsync =
        ref.watch(studentSubmissionProvider(widget.assignmentId));

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
                      const SizedBox(height: 16),
                      submissionAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                        error: (e, _) => Text('Error: $e'),
                        data: (submission) =>
                            _buildSubmissionPanel(submission, loc),
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

  Widget _buildSubmissionPanel(
      HomeworkSubmissionModel? submission, AppLocalizations loc) {
    if (submission == null || submission.isPending) {
      return _buildSubmitForm(submission, loc);
    }

    return _buildGradedView(submission, loc);
  }

  Widget _buildSubmitForm(
      HomeworkSubmissionModel? submission, AppLocalizations loc) {
    final isEditing = submission != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusBadge(
          status: isEditing ? 'pending' : 'not_submitted',
          label: isEditing ? 'Submitted - Pending Grade' : 'Not Submitted',
        ),
        const SizedBox(height: 16),
        if (isEditing) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF0284C7), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You have already submitted a file. Upload again to update your submission.',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey[700], height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        GestureDetector(
          onTap: _isSubmitting ? null : _pickFile,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _selectedFileBytes != null
                    ? const Color(0xFF10B981)
                    : const Color(0xFFE2E8F0),
                width: 2,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _selectedFileBytes != null
                      ? Icons.description_rounded
                      : Icons.upload_file_rounded,
                  size: 48,
                  color: _selectedFileBytes != null
                      ? const Color(0xFF10B981)
                      : const Color(0xFF6366F1),
                ),
                const SizedBox(height: 12),
                Text(
                  _selectedFileName ?? 'Tap to select PDF or image',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _selectedFileBytes != null
                        ? const Color(0xFF1E293B)
                        : const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'PDF, JPG, PNG supported',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Add a note to your teacher (optional)',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 54,
          child: FilledButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.cloud_upload_rounded),
            label: Text(
              _isSubmitting
                  ? 'Uploading...'
                  : isEditing
                      ? 'Update Submission'
                      : 'Upload & Submit',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradedView(HomeworkSubmissionModel submission,
      AppLocalizations loc) {
    // grade is double? — display with one decimal if non-integer
    final gradeDisplay = submission.grade == null
        ? '-'
        : submission.grade! % 1 == 0
            ? submission.grade!.toInt().toString()
            : submission.grade!.toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusBadge(status: 'graded', label: 'Graded'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF6EE7B7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              const Text('Your Grade',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    gradeDisplay,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10, left: 4),
                    child: Text('/ 20',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
        if ((submission.feedback ?? '').isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.feedback_rounded,
                      size: 18, color: Color(0xFF6366F1)),
                  SizedBox(width: 8),
                  Text('Teacher Feedback',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                ]),
                const SizedBox(height: 10),
                Text(submission.feedback!,
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ],
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

class _StatusBadge extends StatelessWidget {
  final String status;
  final String label;

  const _StatusBadge({required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case 'graded':
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF065F46);
        icon = Icons.check_circle_rounded;
      case 'pending':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFF92400E);
        icon = Icons.schedule_rounded;
      default:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF475569);
        icon = Icons.radio_button_unchecked_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
        ],
      ),
    );
  }
}
