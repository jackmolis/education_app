import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';
import 'package:nexora_academy/core/widgets/empty_state_widget.dart';
import '../providers/admin_assignments_provider.dart';

const _kAccentA = Color(0xFF6366F1);
const _kAccentADark = Color(0xFF4338CA);

class ManageSubmissionsScreen extends ConsumerWidget {
  final String assignmentId;

  const ManageSubmissionsScreen({super.key, required this.assignmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionsAsync = ref.watch(adminSubmissionsProvider(assignmentId));

    return AppScaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          Expanded(
            child: submissionsAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: _kAccentA)),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: EmptyStateWidget(
                  icon: Icons.error_outline,
                  title: 'Failed to load submissions',
                  actionLabel: 'Retry',
                  onAction: () =>
                      ref.invalidate(adminSubmissionsProvider(assignmentId)),
                ),
              ),
              data: (submissions) {
                if (submissions.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: EmptyStateWidget(
                      icon: Icons.inbox_rounded,
                      title: 'No submissions yet',
                      subtitle: 'Students haven\'t submitted this assignment.',
                    ),
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  itemCount: submissions.length,
                  itemBuilder: (context, index) {
                    final s = submissions[index];
                    final profile = s['profiles'] as Map<String, dynamic>?;
                    final studentName =
                        profile?['full_name'] as String? ??
                        profile?['email'] as String? ??
                        'Unknown Student';
                    final status = s['status'] as String? ?? 'pending';
                    final grade = s['grade'] != null
                        ? (s['grade'] as num).toDouble()
                        : null;
                    final submittedAt = s['submitted_at'] as String? ?? '';

                    return _SubmissionCard(
                      studentName: studentName,
                      status: status,
                      grade: grade,
                      submittedAt: submittedAt,
                      onTap: () => context.push(
                        '/admin/manage-assignments/$assignmentId/submissions/${s['id']}/grade',
                        extra: s,
                      ),
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

  Widget _buildHeader(BuildContext context) {
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
          const Expanded(
            child: Text('Student Submissions',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
          ),
          const Icon(Icons.people_rounded, color: Colors.white, size: 24),
        ],
      ),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  final String studentName;
  final String status;
  final double? grade;
  final String submittedAt;
  final VoidCallback onTap;

  const _SubmissionCard({
    required this.studentName,
    required this.status,
    required this.grade,
    required this.submittedAt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isGraded = status == 'graded';
    final dateStr = _formatDate(submittedAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isGraded
                        ? const Color(0xFFD1FAE5)
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isGraded
                        ? Icons.check_circle_rounded
                        : Icons.hourglass_empty_rounded,
                    color:
                        isGraded ? const Color(0xFF065F46) : const Color(0xFF92400E),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(studentName,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(dateStr,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                ),
                if (isGraded && grade != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                        '${grade! % 1 == 0 ? grade!.toInt() : grade!.toStringAsFixed(1)} / 20',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: Color(0xFF065F46))),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isGraded
                        ? const Color(0xFF065F46).withValues(alpha: 0.1)
                        : const Color(0xFF92400E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isGraded ? 'Graded' : 'Pending',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isGraded
                          ? const Color(0xFF065F46)
                          : const Color(0xFF92400E),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    if (iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
