class Product {
  // ✅ Removed 'final' so these can be updated by the CartProvider lookup
  String id;
  String title;
  double priceUsd;
  String currency;
  String imageUrl;
  String description;
  String category;
  int stock;

  Product({
    required this.id,
    required this.title,
    required this.priceUsd,
    required this.currency,
    required this.imageUrl,
    required this.description,
    required this.category,
    required this.stock,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse numbers, preventing "String is not a subtype of double" errors
    num asNum(dynamic val) => (val is num) 
        ? val 
        : num.tryParse(val?.toString() ?? '0') ?? 0;

    return Product(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      // ✅ We use 'Loading...' as a placeholder until the Provider populates it
      title: (json['title'] ?? 'Loading...').toString(),
      priceUsd: asNum(json['priceUsd']).toDouble(),
      currency: (json['currency'] ?? 'USD').toString(),
      imageUrl: (json['imageUrl'] ?? json['image'] ?? json['img'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      category: (json['category'] ?? 'General').toString(),
      stock: asNum(json['stock']).toInt(),
    );
  }

  // ==========================================
  // ✅ FIX 2 (CONT): THE "EXPORTER" FOR PRODUCT
  // ==========================================
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'priceUsd': priceUsd,
      'currency': currency,
      'imageUrl': imageUrl,
      'description': description,
      'category': category,
      'stock': stock,
    };
  }
  // ==========================================

  // ✅ THE FIX: This method allows the Provider to inject full data into a partial product
  void updateFromMap(Map<String, dynamic> map) {
    num asNum(dynamic val) => (val is num) 
        ? val 
        : num.tryParse(val?.toString() ?? '0') ?? 0;

    title = (map['title'] ?? title).toString();
    priceUsd = asNum(map['priceUsd']).toDouble();
    imageUrl = (map['imageUrl'] ?? map['image'] ?? imageUrl).toString();
    description = (map['description'] ?? description).toString();
    category = (map['category'] ?? category).toString();
    stock = asNum(map['stock']).toInt();
    currency = (map['currency'] ?? currency).toString();
  }

  Product copyWith({
    String? id,
    String? title,
    double? priceUsd,
    String? currency,
    String? imageUrl,
    String? description,
    String? category,
    int? stock,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      priceUsd: priceUsd ?? this.priceUsd,
      currency: currency ?? this.currency,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      category: category ?? this.category,
      stock: stock ?? this.stock,
    );
  }

  @override
  String toString() => 'Product(id: $id, title: $title, price: $priceUsd)';
}