import 'package:flutter/material.dart';
import '../api/authed_api_client.dart';
import '../models/order.dart';
import 'order_details_page.dart';

// ✅ Ensure this class name is exactly "OrdersPage"
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key, required this.api});
  final AuthedApiClient api;

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  bool _loading = false;
  String? _error;
  List<Order> _orders = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final orders = await widget.api.myOrders();
      // Sort: Newest orders first
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (mounted) setState(() => _orders = orders);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING': return Colors.orange;
      case 'PAID': return Colors.blue;
      case 'SHIPPED': return Colors.purple;
      case 'COMPLETED': return Colors.green;
      case 'CANCELLED': return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // We removed the AppBar here because HomeShell provides the main AppBar
      body: Column(
        children: [
          if (_loading) LinearProgressIndicator(minHeight: 2, color: theme.colorScheme.primary),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              color: theme.colorScheme.primary,
              child: _orders.isEmpty && !_loading
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _orders.length,
                      itemBuilder: (context, i) {
                        final o = _orders[i];
                        // Robust ID display
                        final shortId = o.id.length > 6 
                            ? o.id.substring(o.id.length - 6).toUpperCase() 
                            : o.id.toUpperCase();
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: isDark ? Border.all(color: theme.dividerColor) : null,
                            boxShadow: isDark ? null : [
                              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OrderDetailsPage(
                                  order: o, 
                                  api: widget.api,
                                ),
                              ),
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.receipt_long_rounded, color: theme.colorScheme.primary),
                            ),
                            title: Row(
                              children: [
                                Text('Order #$shortId', 
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const Spacer(),
                                _statusBadge(o.status),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${o.items.length} Items • ${o.createdAt.day}/${o.createdAt.month}/${o.createdAt.year}',
                                      style: TextStyle(color: theme.hintColor, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text('\$${o.totalUsd.toStringAsFixed(2)}', 
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900, 
                                        color: theme.colorScheme.primary, 
                                        fontSize: 18
                                      )),
                                ],
                              ),
                            ),
                            trailing: Icon(Icons.arrow_forward_ios, size: 14, color: theme.hintColor),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return ListView( // Wrap in ListView so RefreshIndicator still works
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long_outlined, size: 80, color: theme.dividerColor),
              const SizedBox(height: 16),
              Text('No orders yet', 
                  style: TextStyle(color: theme.hintColor, fontSize: 18, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text('Your purchase history will appear here', 
                  style: TextStyle(color: theme.hintColor, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}