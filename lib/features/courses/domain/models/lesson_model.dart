class LessonModel {
  final String id;
  final String subjectId;
  final String? titleEn;
  final String? titleFr;
  final String? titleAr;
  final String? descriptionEn;
  final String? descriptionFr;
  final String? descriptionAr;
  final String? content;
  final String videoUrl;
  final String pdfUrl;
  final int? duration;
  final int orderNumber;
  final DateTime? createdAt;

  LessonModel({
    required this.id,
    required this.subjectId,
    this.titleEn,
    this.titleFr,
    this.titleAr,
    this.descriptionEn,
    this.descriptionFr,
    this.descriptionAr,
    this.content,
    required this.videoUrl,
    required this.pdfUrl,
    this.duration,
    required this.orderNumber,
    this.createdAt,
  });

  String getTitle(String locale) {
    if (locale == 'fr' && titleFr != null && titleFr!.isNotEmpty) return titleFr!;
    if (locale == 'ar' && titleAr != null && titleAr!.isNotEmpty) return titleAr!;
    return titleEn ?? '';
  }

  String getDescription(String locale) {
    if (locale == 'fr' && (descriptionFr?.isNotEmpty ?? false)) return descriptionFr!;
    if (locale == 'ar' && (descriptionAr?.isNotEmpty ?? false)) return descriptionAr!;
    if (descriptionEn?.isNotEmpty ?? false) return descriptionEn!;
    return '';
  }

  LessonModel copyWith({
    String? id,
    String? subjectId,
    String? titleEn,
    String? titleFr,
    String? titleAr,
    String? descriptionEn,
    String? descriptionFr,
    String? descriptionAr,
    String? content,
    String? videoUrl,
    String? pdfUrl,
    int? duration,
    int? orderNumber,
    DateTime? createdAt,
  }) {
    return LessonModel(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      titleEn: titleEn ?? this.titleEn,
      titleFr: titleFr ?? this.titleFr,
      titleAr: titleAr ?? this.titleAr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionFr: descriptionFr ?? this.descriptionFr,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      content: content ?? this.content,
      videoUrl: videoUrl ?? this.videoUrl,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      duration: duration ?? this.duration,
      orderNumber: orderNumber ?? this.orderNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory LessonModel.fromJson(Map<String, dynamic> json) {
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

    int? dur;
    final rawDur = json['duration'];
    if (rawDur is int) {
      dur = rawDur;
    } else if (rawDur is num) {
      dur = rawDur.toInt();
    }

    return LessonModel(
      id: json['id'].toString(),
      subjectId: json['subject_id']?.toString() ?? '',
      titleEn: json['title_en'] as String?,
      titleFr: json['title_fr'] as String?,
      titleAr: json['title_ar'] as String?,
      descriptionEn: json['description_en'] as String?,
      descriptionFr: json['description_fr'] as String?,
      descriptionAr: json['description_ar'] as String?,
      content: json['content'] as String?,
      videoUrl: json['video_url'] as String? ?? '',
      pdfUrl: json['pdf_url'] as String? ?? '',
      duration: dur,
      orderNumber: order,
      createdAt: created,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject_id': subjectId,
      if (titleEn != null) 'title_en': titleEn,
      if (titleFr != null) 'title_fr': titleFr,
      if (titleAr != null) 'title_ar': titleAr,
      if (descriptionEn != null) 'description_en': descriptionEn,
      if (descriptionFr != null) 'description_fr': descriptionFr,
      if (descriptionAr != null) 'description_ar': descriptionAr,
      if (content != null) 'content': content,
      'video_url': videoUrl,
      'pdf_url': pdfUrl,
      if (duration != null) 'duration': duration,
      'order_number': orderNumber,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
