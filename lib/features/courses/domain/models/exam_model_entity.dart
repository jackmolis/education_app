/// A single "model" (Modèle / النموذج / Model) belonging to an exam.
/// Each model carries its own exam PDF and correction PDF.
///
/// DB table: `exam_models`
/// Fields: id, exam_id, model_number, title_ar, title_fr, title_en,
///         exam_pdf_url, correction_pdf_url, created_at
class ExamModelEntity {
  final String id;
  final String examId;
  final int modelNumber;
  final String? titleEn;
  final String? titleFr;
  final String? titleAr;
  final String examPdfUrl;
  final String correctionPdfUrl;
  final DateTime? createdAt;

  ExamModelEntity({
    required this.id,
    required this.examId,
    required this.modelNumber,
    this.titleEn,
    this.titleFr,
    this.titleAr,
    required this.examPdfUrl,
    required this.correctionPdfUrl,
    this.createdAt,
  });

  bool get hasExamPdf => examPdfUrl.isNotEmpty;
  bool get hasCorrectionPdf => correctionPdfUrl.isNotEmpty;

  /// Localized title for the model (optional in DB). Falls back across the
  /// other localized columns; empty string when none are set.
  String getTitle(String locale) {
    switch (locale) {
      case 'ar':
        return _firstNonEmpty([titleAr, titleFr, titleEn]);
      case 'fr':
        return _firstNonEmpty([titleFr, titleEn, titleAr]);
      default:
        return _firstNonEmpty([titleEn, titleFr, titleAr]);
    }
  }

  static String _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v != null && v.isNotEmpty) return v;
    }
    return '';
  }

  factory ExamModelEntity.fromJson(Map<String, dynamic> json) {
    DateTime? created;
    final rawCreated = json['created_at'];
    if (rawCreated is String) {
      created = DateTime.tryParse(rawCreated);
    }

    int parseInt(dynamic raw) {
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      return 0;
    }

    return ExamModelEntity(
      id: json['id'].toString(),
      examId: json['exam_id']?.toString() ?? '',
      modelNumber: parseInt(json['model_number']),
      titleEn: json['title_en'] as String?,
      titleFr: json['title_fr'] as String?,
      titleAr: json['title_ar'] as String?,
      examPdfUrl: json['exam_pdf_url'] as String? ?? '',
      correctionPdfUrl: json['correction_pdf_url'] as String? ?? '',
      createdAt: created,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exam_id': examId,
      'model_number': modelNumber,
      if (titleEn != null) 'title_en': titleEn,
      if (titleFr != null) 'title_fr': titleFr,
      if (titleAr != null) 'title_ar': titleAr,
      'exam_pdf_url': examPdfUrl,
      'correction_pdf_url': correctionPdfUrl,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
