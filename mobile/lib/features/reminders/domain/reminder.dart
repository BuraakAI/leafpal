class Reminder {
  final String id;
  final String type;
  final String title;
  final DateTime dueDate;
  final bool completed;
  final String? userPlantId;
  final String? plantName;

  const Reminder({
    required this.id,
    required this.type,
    required this.title,
    required this.dueDate,
    required this.completed,
    this.userPlantId,
    this.plantName,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    final plant = json['userPlant'] as Map<String, dynamic>?;
    final species = plant?['species'] as Map<String, dynamic>?;
    return Reminder(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
      completed: json['completed'] as bool? ?? false,
      userPlantId: json['userPlantId'] as String?,
      plantName: species?['turkishName'] as String? ?? species?['commonName'] as String?,
    );
  }

  String get typeIcon => switch (type) {
        'watering' => '💧',
        'fertilizing' => '🌿',
        'repotting' => '🪴',
        _ => '🔔',
      };
}
