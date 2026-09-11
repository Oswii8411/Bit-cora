class HistoryLog {
  String? id;
  String actionType;
  String entityType;
  String description;
  DateTime? createdAt;

  HistoryLog({
    this.id,
    required this.actionType,
    required this.entityType,
    required this.description,
    this.createdAt,
  });

  factory HistoryLog.fromMap(Map<String, dynamic> map) {
    return HistoryLog(
      id: map['id'],
      actionType: map['action_type'],
      entityType: map['entity_type'],
      description: map['description'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at']).toLocal()
          : null,
    );
  }
}
