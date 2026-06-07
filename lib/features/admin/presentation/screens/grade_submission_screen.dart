import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';
import '../providers/admin_assignments_provider.dart';
import '../../../courses/presentation/providers/homework_provider.dart';

const _kAccentA = Color(0xFF6366F1);
const _kAccentADark = Color(0xFF4338CA);

class GradeSubmissionScreen extends ConsumerStatefulWidget {
  final String submissionId;
  final Map<String, dynamic> submissionData;

  const GradeSubmissionScreen({
    super.key,
    required this.submissionId,
    required this.submissionData,
  });

  @override
  ConsumerState<GradeSubmissionScreen> createState() =>
      _GradeSubmissionScreenState();
}

class _GradeSubmissionScreenState
    extends ConsumerState<GradeSubmissionScreen> {
  final _gradeController = TextEditingController();
  final _feedbackController = TextEditingController();
  bool _isSaving = false;
  bool _isGraded = false;

  @override
  void initState() {
    super.initState();
    final existingGrade = widget.submissionData['grade'];
    if (existingGrade != null) {
      _gradeController.text = existingGrade.toString();
    }
    final existingFeedback = widget.submissionData['feedback'] as String?;
    if (existingFeedback != null && existingFeedback.isNotEmpty) {
      _feedbackController.text = existingFeedback;
    }
    _isGraded = widget.submissionData['status'] == 'graded';
  }

  @override
  void dispose() {
    _gradeController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitGrade() async {
    final gradeText = _gradeController.text.trim();
    final feedback = _feedbackController.text.trim();

    if (gradeText.isEmpty) {
      _snack('Please enter a grade.');
      return;
    }

    final grade = double.tryParse(gradeText);
    if (grade == null || grade < 0 || grade > 20) {
      _snack('Grade must be a number between 0 and 20.');
      return;
    }

    if (feedback.isEmpty) {
      _snack('Please provide feedback.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(homeworkRepositoryProvider);
      await repo.gradeSubmission(
        widget.submissionId,
        grade: grade,
        feedback: feedback,
      );

      if (mounted) {
        final assignmentId =
            widget.submissionData['assignment_id']?.toString() ?? '';
        ref.invalidate(adminSubmissionsProvider(assignmentId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grade submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final profile =
        widget.submissionData['profiles'] as Map<String, dynamic>?;
    final studentName =
        profile?['full_name'] as String? ??
        profile?['email'] as String? ??
        'Unknown Student';
    final notes = widget.submissionData['note'] as String?;
    final submissionUrl =
        widget.submissionData['file_url'] as String? ?? '';

    return AppScaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, studentName),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                _card(
                  title: 'Student Submission',
                  icon: Icons.description_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow('Student', studentName),
                      if (submissionUrl.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              context.push('/pdf-viewer', extra: {
                                'pdfUrl': submissionUrl,
                                'title': 'Student Submission',
                                'lessonId':
                                    'submission_${widget.submissionId}',
                              });
                            },
                            icon: const Icon(Icons.picture_as_pdf_rounded,
                                color: Color(0xFFF97316), size: 20),
                            label: const Text('View Submitted File',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B))),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                      if (notes != null && notes.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text('Student Notes:',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(notes,
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[700])),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _card(
                  title: 'Grading',
                  icon: Icons.grading_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _gradeController,
                        keyboardType: TextInputType.number,
                        enabled: !_isGraded,
                        decoration: InputDecoration(
                          labelText: 'Grade (0 - 20)',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE2E8F0))),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: _kAccentA, width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _feedbackController,
                        maxLines: 5,
                        enabled: !_isGraded,
                        decoration: InputDecoration(
                          labelText: 'Feedback',
                          hintText:
                              'Provide detailed feedback to the student...',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE2E8F0))),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: _kAccentA, width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 54,
                        child: FilledButton(
                          onPressed:
                              (_isSaving || _isGraded) ? null : _submitGrade,
                          style: FilledButton.styleFrom(
                            backgroundColor: _isGraded
                                ? Colors.grey
                                : _kAccentA,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : Text(
                                  _isGraded
                                      ? 'Already Graded'
                                      : 'Submit Grade',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600])),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14)),
        ),
      ],
    );
  }

  Widget _card({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: _kAccentA.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: _kAccentA),
            ),
            const SizedBox(width: 10),
            Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String studentName) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [_kAccentA, _kAccentADark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Grade Submission',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(studentName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Icon(Icons.grading_rounded, color: Colors.white, size: 24),
        ],
      ),
    );
  }
}
