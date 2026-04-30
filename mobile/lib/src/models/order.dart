class OrderItem {
  OrderItem({
    required this.productId,
    required this.title,
    required this.priceUsd,
    required this.quantity,
    required this.imageUrl,
  });

  final String productId;
  final String title;
  final double priceUsd;
  final int quantity;
  final String imageUrl;

  double get lineTotal => priceUsd * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // 1. ✅ Robust Product Extraction
    final rawProduct = json['product'];
    String pid = '';
    String img = '';

    if (rawProduct is String) {
      pid = rawProduct;
    } else if (rawProduct is Map<String, dynamic>) {
      pid = (rawProduct['_id'] ?? rawProduct['id'] ?? '').toString();
      img = (rawProduct['imageUrl'] ?? rawProduct['image'] ?? '').toString();
    }

    // 2. ✅ Final Image fallback logic
    final String finalImageUrl = json['imageUrl']?.toString() ?? 
                                 json['image']?.toString() ?? 
                                 img;

    return OrderItem(
      productId: pid,
      title: (json['title'] ?? (rawProduct is Map ? rawProduct['title'] : 'Unknown Item')).toString(),
      priceUsd: (json['priceUsd'] as num? ?? (rawProduct is Map ? rawProduct['priceUsd'] : 0.0) as num).toDouble(),
      quantity: (json['quantity'] as num? ?? 1).toInt(),
      imageUrl: finalImageUrl,
    );
  }
}

class Order {
  Order({
    required this.id,
    required this.totalUsd,
    required this.currency,
    required this.status,
    required this.createdAt,
    required this.items,
  });

  final String id;
  final double totalUsd;
  final String currency;
  final String status;
  final DateTime createdAt;
  final List<OrderItem> items;

  factory Order.fromJson(Map<String, dynamic> json) {
    // 1. ✅ Robust handling of ID and List
    final String oid = (json['_id'] ?? json['id'] ?? '').toString();
    final rawItems = (json['items'] as List<dynamic>? ?? const []);

    // 2. ✅ Safe Date Parsing
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['createdAt']?.toString() ?? DateTime.now().toIso8601String());
    } catch (e) {
      parsedDate = DateTime.now();
    }

    return Order(
      id: oid,
      totalUsd: (json['totalUsd'] as num? ?? 0.0).toDouble(),
      currency: (json['currency'] ?? 'USD').toString(),
      status: (json['status'] ?? 'PENDING').toString(),
      createdAt: parsedDate,
      items: rawItems
          .whereType<Map<String, dynamic>>() // Ensure we only map actual JSON objects
          .map((e) => OrderItem.fromJson(e))
          .toList(),
    );
  }

  Order copyWith({
    String? status,
    double? totalUsd,
    String? currency,
    DateTime? createdAt,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id,
      totalUsd: totalUsd ?? this.totalUsd,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }
}