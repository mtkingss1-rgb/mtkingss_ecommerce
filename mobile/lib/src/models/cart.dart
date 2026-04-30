import 'product.dart';

class CartItem {
  CartItem({
    required this.product,
    required this.quantity,
    this.selected = true,
  });

  final Product product;
  int quantity; 
  bool selected; 

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final rawProduct = json['product'];
    Map<String, dynamic> productMap = {};

    if (rawProduct is Map<String, dynamic>) {
      productMap = rawProduct;
    } else if (rawProduct is String) {
      productMap = {'_id': rawProduct, 'title': 'Loading...'};
    }

    return CartItem(
      product: Product.fromJson(productMap),
      quantity: (json['quantity'] as num? ?? 1).toInt(),
      selected: json['selected'] as bool? ?? true, 
    );
  }

  // ==========================================
  // ✅ FIX 2: THE "EXPORTER" FOR CART ITEM
  // ==========================================
  Map<String, dynamic> toJson() {
    return {
      // Note: This requires your Product class to also have a toJson() method!
      'product': product.toJson(), 
      'quantity': quantity,
      'selected': selected,
    };
  }

  double get lineTotal => product.priceUsd * quantity;
}

class CartResponse {
  CartResponse({
    required this.id,
    required this.items,
    required this.totalUsd,
    required this.currency,
  });

  final String id;
  final List<CartItem> items;
  final double totalUsd;
  final String currency;

  factory CartResponse.fromJson(Map<String, dynamic> json) {
    final cartMap = json['cart'] is Map<String, dynamic> 
        ? json['cart'] as Map<String, dynamic> 
        : json; 
        
    final rawItems = (cartMap['items'] as List<dynamic>? ?? []);
    
    return CartResponse(
      id: (cartMap['_id'] ?? cartMap['id'] ?? '').toString(), 
      items: rawItems
          .whereType<Map<String, dynamic>>() 
          .map((e) => CartItem.fromJson(e))
          .toList(),
      totalUsd: (json['totalUsd'] as num? ?? cartMap['totalUsd'] as num? ?? 0.0).toDouble(),
      currency: (json['currency'] ?? cartMap['currency'] ?? 'USD').toString(),
    );
  }

  // ==========================================
  // ✅ FIX 2: THE "EXPORTER" FOR THE WHOLE CART
  // ==========================================
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      // Map over every item and tell it to run its own toJson() exporter
      'items': items.map((item) => item.toJson()).toList(),
      'totalUsd': totalUsd,
      'currency': currency,
    };
  }

  double get selectedTotalUsd {
    return items
        .where((item) => item.selected)
        .fold(0.0, (sum, item) => sum + item.lineTotal);
  }
}

class CartItemVm {
  CartItemVm({
    required this.productId, 
    required this.title, 
    required this.priceUsd, 
    required this.quantity, 
    required this.imageUrl, 
    this.selected = true
  });
  
  final String productId; 
  final String title; 
  final double priceUsd; 
  final int quantity; 
  final String imageUrl; 
  bool selected;
  
  double get lineTotal => priceUsd * quantity;
}

class CartVm {
  CartVm({
    required this.id, 
    required this.items, 
    required this.totalUsd, 
    required this.currency
  });
  
  final String id; 
  final List<CartItemVm> items; 
  final double totalUsd; 
  final String currency;
}