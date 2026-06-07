/// DB table: `home_assignments`
/// Fields: id, subject_id, title_ar, title_fr, title_en,
///         description_ar, description_fr, description_en,
///         pdf_url, order_number, created_at
class HomeAssignmentModel {
  final String id;
  final String subjectId;
  final String? titleEn;
  final String? titleFr;
  final String? titleAr;
  final String? descriptionEn;
  final String? descriptionFr;
  final String? descriptionAr;
  final String pdfUrl;
  final int orderNumber;
  final DateTime? createdAt;

  HomeAssignmentModel({
    required this.id,
    required this.subjectId,
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

  bool get hasPdf => pdfUrl.isNotEmpty;

  String getTitle(String locale) {
    switch (locale) {
      case 'ar':
        return _first([titleAr, titleFr, titleEn]);
      case 'fr':
        return _first([titleFr, titleEn, titleAr]);
      default:
        return _first([titleEn, titleFr, titleAr]);
    }
  }

  String getDescription(String locale) {
    switch (locale) {
      case 'ar':
        return _first([descriptionAr, descriptionFr, descriptionEn]);
      case 'fr':
        return _first([descriptionFr, descriptionEn, descriptionAr]);
      default:
        return _first([descriptionEn, descriptionFr, descriptionAr]);
    }
  }

  static String _first(List<String?> values) {
    for (final v in values) {
      if (v != null && v.isNotEmpty) return v;
    }
    return '';
  }

  factory HomeAssignmentModel.fromJson(Map<String, dynamic> json) {
    DateTime? created;
    final raw = json['created_at'];
    if (raw is String) created = DateTime.tryParse(raw);

    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return 0;
    }

    return HomeAssignmentModel(
      id: json['id'].toString(),
      subjectId: json['subject_id']?.toString() ?? '',
      titleEn: json['title_en'] as String?,
      titleFr: json['title_fr'] as String?,
      titleAr: json['title_ar'] as String?,
      descriptionEn: json['description_en'] as String?,
      descriptionFr: json['description_fr'] as String?,
      descriptionAr: json['description_ar'] as String?,
      pdfUrl: json['pdf_url'] as String? ?? '',
      orderNumber: parseInt(json['order_number']),
      createdAt: created,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject_id': subjectId,
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
