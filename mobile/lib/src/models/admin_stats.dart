class AdminDashboardStats {
  AdminDashboardStats({
    required this.users,
    required this.products,
    required this.ordersTotal,
    required this.pendingOrders,
    required this.paidOrders,
    required this.revenueUsd,
    required this.currency,
    this.totalItemsSold = 0, // ✅ Optional: Added to track sales volume
  });

  final int users;
  final int products;
  final int ordersTotal;
  final int pendingOrders;
  final int paidOrders;
  final double revenueUsd;
  final String currency;
  final int totalItemsSold; // ✅ Added

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse numbers
    num asNum(dynamic val) => (val is num) ? val : 0;

    return AdminDashboardStats(
      users: asNum(json['users']).toInt(),
      products: asNum(json['products']).toInt(),
      ordersTotal: asNum(json['ordersTotal']).toInt(),
      pendingOrders: asNum(json['pendingOrders']).toInt(),
      paidOrders: asNum(json['paidOrders']).toInt(),
      revenueUsd: asNum(json['revenueUsd']).toDouble(),
      currency: (json['currency'] ?? 'USD').toString(),
      totalItemsSold: asNum(json['totalItemsSold']).toInt(), // ✅ Parses from API
    );
  }

  // ✅ Helpful for refreshing the dashboard UI without a full reload
  AdminDashboardStats copyWith({
    int? users,
    int? products,
    int? ordersTotal,
    int? pendingOrders,
    int? paidOrders,
    double? revenueUsd,
    String? currency,
    int? totalItemsSold,
  }) {
    return AdminDashboardStats(
      users: users ?? this.users,
      products: products ?? this.products,
      ordersTotal: ordersTotal ?? this.ordersTotal,
      pendingOrders: pendingOrders ?? this.pendingOrders,
      paidOrders: paidOrders ?? this.paidOrders,
      revenueUsd: revenueUsd ?? this.revenueUsd,
      currency: currency ?? this.currency,
      totalItemsSold: totalItemsSold ?? this.totalItemsSold,
    );
  }
}