class ExerciseModel {
  final String id;
  final String lessonId;
  final String? titleEn;
  final String? titleFr;
  final String? titleAr;
  final String? descriptionEn;
  final String? descriptionFr;
  final String? descriptionAr;
  final String pdfUrl;
  final int orderNumber;
  final DateTime? createdAt;

  ExerciseModel({
    required this.id,
    required this.lessonId,
    this.titleEn,
    this.titleFr,
    this.titleAr,
    this.descriptionEn,
    this.descriptionFr,
    this.descriptionAr,
    required this.pdfUrl,
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

  bool get hasPdf => pdfUrl.isNotEmpty;

  static String _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v != null && v.isNotEmpty) return v;
    }
    return '';
  }

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    DateTime? created;
    final rawCreated = json['created_at'];
    if (rawCreated is String) {
      created = DateTime.tryParse(rawCreated);
    }

    int order = 0;
    final rawOrder = json['order_number'];
    if (rawOrder is int) {
      order = rawOrder;
    } else if (rawOrder is num) {
      order = rawOrder.toInt();
    }

    return ExerciseModel(
      id: json['id'].toString(),
      lessonId: json['lesson_id']?.toString() ?? '',
      titleEn: json['title_en'] as String?,
      titleFr: json['title_fr'] as String?,
      titleAr: json['title_ar'] as String?,
      descriptionEn: json['description_en'] as String?,
      descriptionFr: json['description_fr'] as String?,
      descriptionAr: json['description_ar'] as String?,
      pdfUrl: json['pdf_url'] as String? ?? '',
      orderNumber: order,
      createdAt: created,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lesson_id': lessonId,
      if (titleEn != null) 'title_en': titleEn,
      if (titleFr != null) 'title_fr': titleFr,
      if (titleAr != null) 'title_ar': titleAr,
      if (descriptionEn != null) 'description_en': descriptionEn,
      if (descriptionFr != null) 'description_fr': descriptionFr,
      if (descriptionAr != null) 'description_ar': descriptionAr,
      'pdf_url': pdfUrl,
      'order_number': orderNumber,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
