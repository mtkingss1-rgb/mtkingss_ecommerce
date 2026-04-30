import 'package:flutter/material.dart';
import '../api/authed_api_client.dart';
import '../models/order.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key, required this.api});
  final AuthedApiClient api;

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  bool _loading = false;
  List<Order> _orders = const [];
  
  // ✅ Standardized status list
  static const List<String> _statuses = [
    'PENDING', 
    'PAID', 
    'SHIPPED', 
    'COMPLETED', 
    'CANCELLED'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final orders = await widget.api.adminAllOrders();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (mounted) setState(() => _orders = orders);
    } catch (e) {
      debugPrint("Admin Load Error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ✅ Helper for status colors
  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING': return Colors.orange;
      case 'PAID': return Colors.blue;
      case 'SHIPPED': return Colors.purple;
      case 'COMPLETED': return Colors.green;
      case 'CANCELLED': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Manage Orders', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loading ? null : _load, 
            icon: const Icon(Icons.refresh_rounded)
          ),
        ],
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator()) 
        : RefreshIndicator(
            onRefresh: _load,
            child: _orders.isEmpty 
              ? Center(child: Text('No orders found', style: TextStyle(color: theme.hintColor)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  itemBuilder: (context, i) {
                    final o = _orders[i];
                    final shortId = o.id.length > 6 ? o.id.substring(o.id.length - 6).toUpperCase() : o.id.toUpperCase();
                    final statusColor = _getStatusColor(o.status);

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      color: theme.cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16), 
                        side: BorderSide(color: theme.dividerColor)
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: ListTile(
                          title: Text(
                            'Order #$shortId', 
                            style: const TextStyle(fontWeight: FontWeight.bold)
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '\$${o.totalUsd.toStringAsFixed(2)} • ${o.createdAt.day}/${o.createdAt.month}/${o.createdAt.year}',
                              style: TextStyle(color: theme.hintColor, fontSize: 13),
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: theme.brightness == Brightness.dark ? Colors.white10 : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _statuses.contains(o.status.toUpperCase()) ? o.status.toUpperCase() : _statuses.first,
                                icon: Icon(Icons.arrow_drop_down, color: statusColor),
                                style: TextStyle(
                                  color: statusColor, 
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 12
                                ),
                                dropdownColor: theme.cardColor,
                                items: _statuses.map((s) => DropdownMenuItem(
                                  value: s, 
                                  child: Text(s)
                                )).toList(),
                                onChanged: (v) async {
                                  if (v != null && v != o.status) {
                                    try {
                                      await widget.api.adminUpdateOrderStatus(orderId: o.id, status: v);
                                      _load(); // Refresh list after update
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Order #$shortId marked as $v"))
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent)
                                        );
                                      }
                                    }
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ),
    );
  }
}