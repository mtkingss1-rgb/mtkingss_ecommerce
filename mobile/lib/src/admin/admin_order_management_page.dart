import 'package:flutter/material.dart';
import '../api/authed_api_client.dart';
import '../models/order.dart';

class AdminOrderManagementPage extends StatefulWidget {
  const AdminOrderManagementPage({
    super.key,
    required this.api,
  });

  final AuthedApiClient api;

  @override
  State<AdminOrderManagementPage> createState() => _AdminOrderManagementPageState();
}

class _AdminOrderManagementPageState extends State<AdminOrderManagementPage> {
  bool _loading = true;
  String? _error;
  List<Order> _orders = const [];

  static const List<String> _allowedStatuses = <String>[
    'PENDING',
    'PAID',
    'SHIPPED',
    'DELIVERED',
    'CANCELLED',
  ];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final orders = await widget.api.adminAllOrders();
      // newest first
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _orders = orders;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _setStatus(Order order, String newStatus) async {
    if (order.status == newStatus) return;

    final previous = order.status;

    // optimistic UI update
    setState(() {
      _orders = _orders
          .map((o) => o.id == order.id ? o.copyWith(status: newStatus) : o)
          .toList(growable: false);
    });

    try {
      await widget.api.adminUpdateOrderStatus(
        orderId: order.id,
        status: newStatus,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order ${_shortId(order.id)} updated to $newStatus')),
      );
    } catch (e) {
      // rollback
      setState(() {
        _orders = _orders
            .map((o) => o.id == order.id ? o.copyWith(status: previous) : o)
            .toList(growable: false);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  String _shortId(String id) => id.length <= 6 ? id : id.substring(id.length - 6);

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
            onPressed: _loading ? null : _loadOrders,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);

    if (_loading && _orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Failed to load orders',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: theme.hintColor)),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadOrders,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: theme.dividerColor),
            const SizedBox(height: 16),
            Text('No orders yet', style: TextStyle(color: theme.hintColor, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _OrderTile(
          order: _orders[index],
          allowedStatuses: _allowedStatuses,
          onChangeStatus: (status) => _setStatus(_orders[index], status),
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({
    required this.order,
    required this.allowedStatuses,
    required this.onChangeStatus,
  });

  final Order order;
  final List<String> allowedStatuses;
  final ValueChanged<String> onChangeStatus;

  String _shortId(String id) => id.length <= 6 ? id : id.substring(id.length - 6);

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING': return Colors.orange;
      case 'PAID': return Colors.blue;
      case 'SHIPPED': return Colors.purple;
      case 'DELIVERED': return Colors.green;
      case 'CANCELLED': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = order.status.toUpperCase();
    final statusColor = _statusColor(status);
    final total = order.totalUsd.toStringAsFixed(2);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${_shortId(order.id).toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year} • ${order.items.length} items',
              style: TextStyle(color: theme.hintColor, fontSize: 13),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$$total',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {}, // You could link to AdminOrderDetailPage here
                  icon: const Icon(Icons.edit_note, size: 18),
                  label: const Text('Status'),
                  onLongPress: null,
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ).buildPopupMenu(context),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Helper extension to make the button trigger the popup menu
extension on Widget {
  Widget buildPopupMenu(BuildContext context) {
    final tile = this as _OrderTile;
    return PopupMenuButton<String>(
      tooltip: 'Change Status',
      onSelected: tile.onChangeStatus,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => tile.allowedStatuses.map((s) {
        final isActive = s == tile.order.status.toUpperCase();
        return PopupMenuItem<String>(
          value: s,
          child: Row(
            children: [
              Icon(
                isActive ? Icons.check_circle : Icons.circle_outlined,
                size: 18,
                color: isActive ? Colors.deepPurple : Colors.grey,
              ),
              const SizedBox(width: 12),
              Text(s, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        );
      }).toList(),
      child: this,
    );
  }
}