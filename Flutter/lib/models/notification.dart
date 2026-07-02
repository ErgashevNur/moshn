class AppNotification {
  final String id;
  final String title;
  final String body;
  final String? type;
  final String? referenceId;
  final bool read;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.type,
    this.referenceId,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        type: json['type'] as String?,
        referenceId: (json['referenceId'] ?? json['reference_id']) as String?,
        read: (json['isRead'] ?? json['is_read'] ?? json['read']) as bool? ?? false,
        createdAt: DateTime.tryParse(
                (json['createdAt'] ?? json['created_at'] ?? '') as String) ??
            DateTime.now(),
      );
}
