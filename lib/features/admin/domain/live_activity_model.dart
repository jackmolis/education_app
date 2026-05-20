enum ActivityType { quiz, video }

class LiveActivityModel {
  final String id;
  final ActivityType type;
  final String description;
  final DateTime timestamp;

  LiveActivityModel({
    required this.id,
    required this.type,
    required this.description,
    required this.timestamp,
  });
}
