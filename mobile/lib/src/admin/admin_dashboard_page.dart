import 'package:flutter/material.dart';
import '../api/authed_api_client.dart';
import '../models/order.dart';
import '../models/admin_stats.dart'; 
import 'admin_orders_page.dart';
import 'admin_products_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key, required this.api});
  final AuthedApiClient api;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _loading = false;
  String? _error;
  AdminDashboardStats? _stats;
  List<Order> _latestOrders = const [];

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
      final stats = await widget.api.adminDashboardStats();
      final orders = await widget.api.adminAllOrders();
      // Sort: Newest orders first
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _stats = stats;
          _latestOrders = orders.take(5).toList();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _statCard(BuildContext context, String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 13, color: theme.hintColor)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _stats;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Admin Panel', style: TextStyle(fontWeight: FontWeight.bold)),
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
      body: RefreshIndicator(
        onRefresh: _load,
        color: theme.colorScheme.primary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            if (_error != null) 
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ),
            
            if (s != null) ...[
              const Text('Business Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _statCard(context, 'Revenue', '\$${s.revenueUsd.toStringAsFixed(2)}', Icons.payments, Colors.green),
                  _statCard(context, 'Products', '${s.products}', Icons.inventory_2, Colors.blue),
                  _statCard(context, 'Users', '${s.users}', Icons.people, Colors.orange),
                  _statCard(context, 'Total Orders', '${s.ordersTotal}', Icons.receipt_long, Colors.purple),
                ],
              ),
              const SizedBox(height: 24),
            ],

            Row(
              children: [
                Expanded(
                  child: _adminButton(
                    context, 
                    'Products', 
                    Icons.edit_note, 
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminProductsPage(api: widget.api)))
                  )
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _adminButton(
                    context, 
                    'Orders', 
                    Icons.local_shipping, 
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminOrdersPage(api: widget.api)))
                  )
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            if (_latestOrders.isEmpty && !_loading) 
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text('No recent orders', style: TextStyle(color: theme.hintColor)),
                )
              )
            else ..._latestOrders.map((o) => _buildOrderTile(context, o)),
          ],
        ),
      ),
    );
  }

  Widget _adminButton(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.cardColor,
        foregroundColor: theme.textTheme.bodyLarge?.color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), 
          side: BorderSide(color: theme.dividerColor)
        ),
      ),
      icon: Icon(icon, size: 20, color: theme.colorScheme.primary),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildOrderTile(BuildContext context, Order o) {
    final theme = Theme.of(context);
    final shortId = o.id.length > 6 ? o.id.substring(o.id.length - 6).toUpperCase() : o.id.toUpperCase();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), 
        side: BorderSide(color: theme.dividerColor)
      ),
      child: ListTile(
        title: Text('Order #$shortId', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('\$${o.totalUsd.toStringAsFixed(2)} • ${o.status}', style: TextStyle(color: theme.hintColor)),
        trailing: Icon(Icons.chevron_right, color: theme.hintColor),
        onTap: () {
          // You can add navigation to specific Admin Order Details here if needed
        },
      ),
    );
  }
}