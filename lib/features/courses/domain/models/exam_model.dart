class ExamModel {
  final String id;
  final String subjectId;
  final int semester;
  final String? titleEn;
  final String? titleFr;
  final String? titleAr;
  final String? descriptionEn;
  final String? descriptionFr;
  final String? descriptionAr;
  final int orderNumber;
  final DateTime? createdAt;

  ExamModel({
    required this.id,
    required this.subjectId,
    required this.semester,
    this.titleEn,
    this.titleFr,
    this.titleAr,
    this.descriptionEn,
    this.descriptionFr,
    this.descriptionAr,
    required this.orderNumber,
    this.createdAt,
  });

  /// Localized title. Picks the column for [locale]; if empty, falls back to
  /// the other localized columns so something always renders.
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

  /// Localized description with the same fallback strategy as [getTitle].
  String getDescription(String locale) {
    switch (locale) {
      case 'ar':
        return _firstNonEmpty([descriptionAr, descriptionFr, descriptionEn]);
      case 'fr':
        return _firstNonEmpty([descriptionFr, descriptionEn, descriptionAr]);
      default:
        return _firstNonEmpty([descriptionEn, descriptionFr, descriptionAr]);
    }
  }

  static String _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v != null && v.isNotEmpty) return v;
    }
    return '';
  }

  factory ExamModel.fromJson(Map<String, dynamic> json) {
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

    return ExamModel(
      id: json['id'].toString(),
      subjectId: json['subject_id']?.toString() ?? '',
      semester: parseInt(json['semester']),
      titleEn: json['title_en'] as String?,
      titleFr: json['title_fr'] as String?,
      titleAr: json['title_ar'] as String?,
      descriptionEn: json['description_en'] as String?,
      descriptionFr: json['description_fr'] as String?,
      descriptionAr: json['description_ar'] as String?,
      orderNumber: parseInt(json['order_number']),
      createdAt: created,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject_id': subjectId,
      'semester': semester,
      if (titleEn != null) 'title_en': titleEn,
      if (titleFr != null) 'title_fr': titleFr,
      if (titleAr != null) 'title_ar': titleAr,
      if (descriptionEn != null) 'description_en': descriptionEn,
      if (descriptionFr != null) 'description_fr': descriptionFr,
      if (descriptionAr != null) 'description_ar': descriptionAr,
      'order_number': orderNumber,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
