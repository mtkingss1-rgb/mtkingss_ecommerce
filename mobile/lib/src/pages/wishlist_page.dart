import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api/authed_api_client.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key, required this.api});

  final AuthedApiClient api;

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  List<Map<String, dynamic>> _wishlist = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    setState(() => _isLoading = true);
    try {
      final result = await widget.api.getWishlist();
      final items = (result['wishlist'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

      if (mounted) {
        setState(() => _wishlist = items);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading wishlist: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFromWishlist(String productId) async {
    try {
      await widget.api.removeFromWishlist(productId: productId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from wishlist'),
            backgroundColor: Colors.green,
          ),
        );
        _loadWishlist();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _openProductDetails(String productId) {
    // Navigate to product details
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening product details...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _wishlist.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 64,
                        color: theme.hintColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Wishlist is empty',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add items to your wishlist to see them here',
                        style: TextStyle(color: theme.hintColor),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadWishlist,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _wishlist.length,
                    itemBuilder: (context, i) {
                      return _buildWishlistItem(_wishlist[i], theme);
                    },
                  ),
                ),
    );
  }

  Widget _buildWishlistItem(Map<String, dynamic> item, ThemeData theme) {
    final product = item['product'] as Map<String, dynamic>? ?? {};
    final productId = item['id'] as String? ?? '';
    final title = product['title'] as String? ?? 'Unknown';
    final price = product['price'] as num? ?? 0;
    final image = product['image'] as String? ?? '';
    final inStock = product['inStock'] as bool? ?? false;

    return GestureDetector(
      onTap: () => _openProductDetails(productId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor, width: 0.5),
        ),
        child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 90,
              height: 90,
              color: theme.dividerColor,
              child: image.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: image,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: SizedBox(
                          width: 24, height: 24, 
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.image_not_supported_outlined),
                    )
                  : const Icon(Icons.inventory_2_outlined),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${(price).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                if (!inStock)
                  const Text(
                    'Out of stock',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Remove'),
                onTap: () => _removeFromWishlist(productId),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}
