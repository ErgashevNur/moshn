class Review {
  final String id;
  final int rating;
  final String comment;
  final String authorName;
  final DateTime? createdAt;

  Review({
    required this.id,
    required this.rating,
    required this.comment,
    required this.authorName,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'] as Map<String, dynamic>?;
    return Review(
      id: json['id'] as String? ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String? ?? '',
      authorName: (owner?['full_name'] as String?) ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
