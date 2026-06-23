class Receipt {
  Receipt({
    required this.receiptId,
    required this.uploadedAt,
    required this.amount,
    required this.transactionType,
    required this.merchantName,
    required this.transactionDate,
    required this.transactionTime,
    required this.transactionId,
    required this.category,
  });

  final String receiptId;
  final String uploadedAt;
  final String amount;
  final String transactionType;
  final String merchantName;
  final String transactionDate;
  final String transactionTime;
  final String transactionId;
  final String category;

  factory Receipt.fromJson(Map<String, dynamic> json) => Receipt(
    receiptId: '${json['receipt_id'] ?? ''}',
    uploadedAt: '${json['uploaded_at'] ?? ''}',
    amount: '${json['amount'] ?? ''}',
    transactionType: '${json['transaction_type'] ?? ''}',
    merchantName: '${json['merchant_name'] ?? ''}',
    transactionDate: '${json['transaction_date'] ?? ''}',
    transactionTime: '${json['transaction_time'] ?? ''}',
    transactionId: '${json['trx_id'] ?? ''}',
    category: '${json['category'] ?? 'Other'}',
  );

  Map<String, dynamic> toJson() => {
    'receipt_id': receiptId,
    'uploaded_at': uploadedAt,
    'amount': amount,
    'transaction_type': transactionType,
    'merchant_name': merchantName,
    'transaction_date': transactionDate,
    'transaction_time': transactionTime,
    'trx_id': transactionId,
    'category': category,
  };

  Receipt copyWith({
    String? amount,
    String? transactionType,
    String? merchantName,
    String? transactionDate,
    String? transactionTime,
    String? transactionId,
    String? category,
  }) => Receipt(
    receiptId: receiptId,
    uploadedAt: uploadedAt,
    amount: amount ?? this.amount,
    transactionType: transactionType ?? this.transactionType,
    merchantName: merchantName ?? this.merchantName,
    transactionDate: transactionDate ?? this.transactionDate,
    transactionTime: transactionTime ?? this.transactionTime,
    transactionId: transactionId ?? this.transactionId,
    category: category ?? this.category,
  );
}

class ReceiptDetail {
  ReceiptDetail({
    required this.receipt,
    required this.imageBase64,
    required this.mimeType,
  });

  final Receipt receipt;
  final String imageBase64;
  final String mimeType;

  factory ReceiptDetail.fromJson(Map<String, dynamic> json) => ReceiptDetail(
    receipt: Receipt.fromJson(json['receipt'] as Map<String, dynamic>),
    imageBase64: '${json['image_base64'] ?? ''}',
    mimeType: '${json['mime_type'] ?? 'image/jpeg'}',
  );
}
