import 'package:flutter/material.dart';
import '../api/authed_api_client.dart';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key, required this.api});
  final AuthedApiClient api;

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  bool _loading = false;
  List<Map<String, dynamic>> _products = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final res = await widget.api.adminAllProducts();
      if (mounted) setState(() => _products = List<Map<String, dynamic>>.from(res));
    } catch (e) {
      debugPrint("Load Error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Inventory Management', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductDialog(),
        backgroundColor: theme.colorScheme.primary,
        child: Icon(Icons.add, color: theme.colorScheme.onPrimary),
      ),
      body: _loading 
        ? LinearProgressIndicator(color: theme.colorScheme.primary) 
        : RefreshIndicator(
            onRefresh: _load,
            color: theme.colorScheme.primary,
            child: _products.isEmpty 
              ? Center(child: Text('No products found', style: TextStyle(color: theme.hintColor)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _products.length,
                  itemBuilder: (context, i) {
                    final p = _products[i];
                    final int stock = (p['stock'] as num?)?.toInt() ?? 0;

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      color: theme.cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16), 
                        side: BorderSide(color: theme.dividerColor)
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            p['imageUrl'] ?? '', 
                            width: 60, height: 60, fit: BoxFit.cover, 
                            errorBuilder: (_,__,___) => Container(
                              color: isDark ? Colors.white10 : Colors.grey[100], 
                              child: Icon(Icons.image, color: theme.hintColor)
                            ),
                          ),
                        ),
                        title: Text(p['title'] ?? 'No Title', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Stock: $stock • \$${(p['priceUsd'] ?? 0.0).toStringAsFixed(2)}',
                            style: TextStyle(
                              color: stock < 5 ? Colors.redAccent : theme.hintColor,
                              fontWeight: stock < 5 ? FontWeight.bold : FontWeight.normal
                            ),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined), 
                              onPressed: () => _showProductDialog(p: p)
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent), 
                              onPressed: () => _delete(p),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
    );
  }

  Future<void> _delete(Map<String, dynamic> p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product?'),
        content: const Text('This will remove the item from the store permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await widget.api.adminDeleteProduct(productId: p['_id']);
      _load();
    }
  }

  void _showProductDialog({Map<String, dynamic>? p}) {
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (_) => _ProductDialog(initialData: p, api: widget.api, onSave: _load),
    );
  }
}

class _ProductDialog extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final AuthedApiClient api;
  final VoidCallback onSave;
  const _ProductDialog({this.initialData, required this.api, required this.onSave});

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  late final TextEditingController _t, _d, _i, _c, _p, _s;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData ?? {};
    _t = TextEditingController(text: d['title'] ?? '');
    _d = TextEditingController(text: d['description'] ?? '');
    _i = TextEditingController(text: d['imageUrl'] ?? '');
    _c = TextEditingController(text: d['category'] ?? 'general');
    _p = TextEditingController(text: d['priceUsd']?.toString() ?? '');
    _s = TextEditingController(text: d['stock']?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: theme.cardColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(widget.initialData == null ? 'Create Product' : 'Update Product'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _t, decoration: const InputDecoration(labelText: 'Product Title')),
            TextField(controller: _p, decoration: const InputDecoration(labelText: 'Price (USD)'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            TextField(controller: _s, decoration: const InputDecoration(labelText: 'Initial Stock'), keyboardType: TextInputType.number),
            TextField(controller: _i, decoration: const InputDecoration(labelText: 'Image URL')),
            TextField(controller: _c, decoration: const InputDecoration(labelText: 'Category')),
            TextField(controller: _d, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context), 
          child: Text('Cancel', style: TextStyle(color: theme.hintColor))
        ),
        _saving 
          ? const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator())
          : FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.primary),
              child: const Text('Save Product'),
            ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final double price = double.tryParse(_p.text) ?? 0.0;
      final int stock = int.tryParse(_s.text) ?? 0;

      if (widget.initialData == null) {
        await widget.api.adminCreateProduct(
          title: _t.text, description: _d.text, imageUrl: _i.text, 
          category: _c.text, priceUsd: price, stock: stock,
        );
      } else {
        await widget.api.adminUpdateProduct(
          productId: widget.initialData!['_id'], 
          title: _t.text, description: _d.text, imageUrl: _i.text, 
          category: _c.text, priceUsd: price, stock: stock,
        );
      }
      widget.onSave();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}