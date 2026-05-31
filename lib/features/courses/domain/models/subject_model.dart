class SubjectModel {
  final String id;
  final String nameEn;
  final String nameFr;
  final String nameAr;
  final String level;
  final String? imageUrl;
  final String? description;

  SubjectModel({
    required this.id,
    required this.nameEn,
    required this.nameFr,
    required this.nameAr,
    required this.level,
    this.imageUrl,
    this.description,
  });

  /// Localized name. Picks the column for [locale]; if that language is empty
  /// it falls back to the other localized columns so something always renders.
  String getName(String locale) {
    switch (locale) {
      case 'ar':
        return _firstNonEmpty([nameAr, nameFr, nameEn]);
      case 'fr':
        return _firstNonEmpty([nameFr, nameEn, nameAr]);
      default:
        return _firstNonEmpty([nameEn, nameFr, nameAr]);
    }
  }

  String getDescription(String locale) {
    return description ?? '';
  }

  static String _firstNonEmpty(List<String> values) {
    for (final v in values) {
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id'].toString(),
      nameEn: json['name_en']?.toString() ?? '',
      nameFr: json['name_fr']?.toString() ?? '',
      nameAr: json['name_ar']?.toString() ?? '',
      level: json['level_id']?.toString() ?? json['level']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_en': nameEn,
      'name_fr': nameFr,
      'name_ar': nameAr,
      'level_id': level,
      'image_url': imageUrl,
      'description': description,
    };
  }
}
