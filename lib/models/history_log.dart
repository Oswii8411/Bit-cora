class HistoryLog {
  String? id;
  String actionType;
  String entityType;
  String description;
  DateTime? createdAt;
  String? userId, userEmail, userName, userRole;

  HistoryLog({
    this.id,
    required this.actionType,
    required this.entityType,
    required this.description,
    this.createdAt,
    this.userId,
    this.userEmail,
    this.userName,
    this.userRole,
  });

  factory HistoryLog.fromMap(Map<String, dynamic> map) {
    return HistoryLog(
      id: map['id']?.toString(),
      actionType: map['action_type'] as String? ?? '',
      entityType: map['entity_type'] as String? ?? '',
      description: map['description'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at']).toLocal()
          : null,
      userId: map['user_id'] as String?,
      userEmail: map['user_email'] as String?,
      userName: map['user_name'] as String?,
      userRole: map['user_role'] as String?,
    );
  }

  /// "Ulises (Administrador)" o el correo si no hay nombre.
  String get userLabel {
    final name = (userName != null && userName!.trim().isNotEmpty) ? userName! : (userEmail ?? 'Sistema');
    if (userRole == null || userRole!.isEmpty) return name;
    return '$name (${userRole == 'admin' ? 'Administrador' : 'Técnico'})';
  }
}
