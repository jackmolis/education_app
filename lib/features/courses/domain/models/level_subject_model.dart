class LevelSubject {
  final String id;
  final String name;
  final String levelId;

  LevelSubject({
    required this.id,
    required this.name,
    required this.levelId,
  });

  factory LevelSubject.fromMap(Map<String, dynamic> map) {
    return LevelSubject(
      id: map['id'] as String,
      name: map['name'] as String,
      levelId: map['level_id'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'level_id': levelId,
    };
  }
}
