class StreamModel {
  final String id;
  final String levelId;
  final String nameAr;
  final String nameFr;
  final String nameEn;
  final int orderNumber;

  StreamModel({
    required this.id,
    required this.levelId,
    required this.nameAr,
    required this.nameFr,
    required this.nameEn,
    this.orderNumber = 0,
  });

  String getName(String locale) {
    if (locale == 'fr' && nameFr.isNotEmpty) return nameFr;
    if (locale == 'ar' && nameAr.isNotEmpty) return nameAr;
    return nameEn;
  }

  factory StreamModel.fromJson(Map<String, dynamic> json) {
    return StreamModel(
      id: json['id'].toString(),
      levelId: json['level_id']?.toString() ?? '',
      nameAr: json['name_ar']?.toString() ?? '',
      nameFr: json['name_fr']?.toString() ?? '',
      nameEn: json['name_en']?.toString() ?? '',
      orderNumber: json['order_number'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'level_id': levelId,
      'name_ar': nameAr,
      'name_fr': nameFr,
      'name_en': nameEn,
      'order_number': orderNumber,
    };
  }
}
