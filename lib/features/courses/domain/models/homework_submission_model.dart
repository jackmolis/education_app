/// Mirrors the `home_submissions` table.
/// Columns: id, assignment_id, student_id, file_url, note,
///          grade (numeric), feedback, status, submitted_at, graded_at
class HomeworkSubmissionModel {
  final String id;
  final String assignmentId;
  final String studentId;
  final String fileUrl;
  final String? note;
  final double? grade;
  final String? feedback;
  final String status; // 'pending' | 'graded'
  final DateTime submittedAt;
  final DateTime? gradedAt;

  HomeworkSubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.fileUrl,
    this.note,
    this.grade,
    this.feedback,
    this.status = 'pending',
    required this.submittedAt,
    this.gradedAt,
  });

  bool get isGraded => status == 'graded';
  bool get isPending => status == 'pending';

  factory HomeworkSubmissionModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDT(dynamic v) {
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return HomeworkSubmissionModel(
      id: json['id']?.toString() ?? '',
      assignmentId: json['assignment_id']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      fileUrl: json['file_url'] as String? ?? '',
      note: json['note'] as String?,
      grade: parseDouble(json['grade']),
      feedback: json['feedback'] as String?,
      status: json['status'] as String? ?? 'pending',
      submittedAt: parseDT(json['submitted_at']) ?? DateTime.now(),
      gradedAt: parseDT(json['graded_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'assignment_id': assignmentId,
        'student_id': studentId,
        'file_url': fileUrl,
        if (note != null && note!.isNotEmpty) 'note': note,
        if (grade != null) 'grade': grade,
        if (feedback != null) 'feedback': feedback,
        'status': status,
        'submitted_at': submittedAt.toUtc().toIso8601String(),
        if (gradedAt != null) 'graded_at': gradedAt!.toUtc().toIso8601String(),
      };

  HomeworkSubmissionModel copyWith({
    String? id,
    String? assignmentId,
    String? studentId,
    String? fileUrl,
    String? note,
    double? grade,
    String? feedback,
    String? status,
    DateTime? submittedAt,
    DateTime? gradedAt,
  }) {
    return HomeworkSubmissionModel(
      id: id ?? this.id,
      assignmentId: assignmentId ?? this.assignmentId,
      studentId: studentId ?? this.studentId,
      fileUrl: fileUrl ?? this.fileUrl,
      note: note ?? this.note,
      grade: grade ?? this.grade,
      feedback: feedback ?? this.feedback,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      gradedAt: gradedAt ?? this.gradedAt,
    );
  }
}
