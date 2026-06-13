class Payment {
  final String id;
  final String bookingId;
  final int amount;
  final String method;
  final String status;
  final String? qrCode;
  final DateTime? paidAt;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.method,
    required this.status,
    this.qrCode,
    this.paidAt,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'] as String,
        bookingId: (json['bookingId'] ?? json['booking_id'] ?? '') as String,
        amount: ((json['amount'] ?? 0) as num).toInt(),
        method: (json['method'] ?? '') as String,
        status: (json['status'] ?? 'pending') as String,
        qrCode: (json['qrCode'] ?? json['qr_code']) as String?,
        paidAt: (json['paidAt'] ?? json['paid_at']) != null
            ? DateTime.tryParse((json['paidAt'] ?? json['paid_at']) as String)
            : null,
        createdAt: DateTime.tryParse(
                (json['createdAt'] ?? json['created_at'] ?? '') as String) ??
            DateTime.now(),
      );

  bool get isPaid => status == 'paid';
}
