class SubjectModel {
  final String id;
  final String name;
  final String nameEn;
  final String nameFr;
  final String nameAr;
  final String level;
  final String? imageUrl;
  final String? description;

  SubjectModel({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.nameFr,
    required this.nameAr,
    required this.level,
    this.imageUrl,
    this.description,
  });

  String getName(String locale) {
    if (locale == 'fr' && nameFr.isNotEmpty) return nameFr;
    if (locale == 'ar' && nameAr.isNotEmpty) return nameAr;
    if (locale == 'en' && nameEn.isNotEmpty) return nameEn;
    // Cross-language fallback before the legacy default column.
    if (nameEn.isNotEmpty) return nameEn;
    if (name.isNotEmpty) return name;
    return '';
  }

  String getDescription(String locale) {
    return description ?? '';
  }

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? json['name_en']?.toString() ?? '',
      nameEn: json['name_en'] ?? json['name'] ?? '',
      nameFr: json['name_fr'] ?? '',
      nameAr: json['name_ar'] ?? '',
      level: json['level_id']?.toString() ?? json['level']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_en': nameEn,
      'name_fr': nameFr,
      'name_ar': nameAr,
      'level_id': level,
      'image_url': imageUrl,
      'description': description,
    };
  }
}
