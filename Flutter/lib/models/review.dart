class Review {
  final String id;
  final String bookingId;
  final String authorId;
  final String targetId;
  final String reviewType; // owner_to_shop | shop_to_owner
  final int rating;
  final String comment;
  final String authorName;
  final bool isModerated;
  final DateTime? createdAt;

  Review({
    required this.id,
    required this.bookingId,
    required this.authorId,
    required this.targetId,
    required this.reviewType,
    required this.rating,
    required this.comment,
    required this.authorName,
    required this.isModerated,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;
    return Review(
      id:          json['id']          as String? ?? '',
      bookingId:   (json['bookingId']  ?? json['booking_id'])  as String? ?? '',
      authorId:    (json['authorId']   ?? json['author_id'])   as String? ?? '',
      targetId:    (json['targetId']   ?? json['target_id'])   as String? ?? '',
      reviewType:  (json['reviewType'] ?? json['review_type']) as String? ?? '',
      rating:      (json['rating']     as num?)?.toInt() ?? 0,
      comment:     json['comment']     as String? ?? '',
      authorName:  (author?['fullName'] ?? author?['full_name']) as String? ?? '',
      isModerated: (json['isModerated'] ?? json['is_moderated']) as bool? ?? false,
      createdAt:   (json['createdAt'] ?? json['created_at']) != null
          ? DateTime.tryParse((json['createdAt'] ?? json['created_at']) as String)
          : null,
    );
  }
}
