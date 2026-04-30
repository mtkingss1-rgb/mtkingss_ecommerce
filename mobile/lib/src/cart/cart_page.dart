import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../api/authed_api_client.dart';
import '../providers/cart_provider.dart';
import '../orders/checkout_review_page.dart';
import '../products/product_details_page.dart';
import '../models/cart.dart';
import '../models/product.dart';

const double _cartItemImageSize = 90;
const double _containerBorderRadius = 16;

class CartPage extends StatefulWidget {
  const CartPage({super.key, required this.api});
  final AuthedApiClient api;

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CartProvider>().fetchCart(widget.api);
      }
    });
  }

  Future<void> _openProductDetails(String productId) async {
    try {
      final productMap = await widget.api.getProduct(productId);
      if (mounted && productMap.isNotEmpty) {
        final product = Product.fromJson(productMap);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ProductDetailsPage(api: widget.api, product: product),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load product: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<CartProvider>();
    final cart = provider.cart;
    final hasItems = cart != null && cart.items.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'My Cart',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      bottomNavigationBar: hasItems ? _buildCheckoutBar(provider) : null,
      body: Column(
        children: [
          if (provider.isLoading)
            LinearProgressIndicator(
              minHeight: 2,
              color: theme.colorScheme.primary,
            ),
          Expanded(
            child: (cart == null && provider.isLoading)
                ? Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  )
                : (!hasItems)
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: () => provider.fetchCart(widget.api),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: cart.items.length,
                      itemBuilder: (context, i) =>
                          _buildCartItem(provider, cart.items[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: theme.dividerColor,
          ),
          const SizedBox(height: 24),
          Text(
            'Your cart is empty',
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Add products to get started',
            style: TextStyle(color: theme.hintColor, fontSize: 14),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.shopping_bag_outlined),
            label: const Text('Continue Shopping'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartProvider provider, CartItem item) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Dismissible(
        key: Key(item.product.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: Colors.red.shade600,
            borderRadius: BorderRadius.circular(_containerBorderRadius),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        onDismissed: (_) => _removeItemWithFeedback(provider, item.product.id),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(_containerBorderRadius),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
            border: isDark
                ? Border.all(color: theme.dividerColor, width: 0.5)
                : null,
          ),
          child: InkWell(
            onTap: () => _openProductDetails(item.product.id),
            borderRadius: BorderRadius.circular(_containerBorderRadius),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  label: 'Select ${item.product.title}',
                  child: Transform.scale(
                    scale: 1.2,
                    child: Checkbox(
                      value: item.selected,
                      activeColor: theme.colorScheme.primary,
                      shape: const CircleBorder(),
                      onChanged: (val) =>
                          provider.toggleSelection(item.product.id),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: _cartItemImageSize,
                    height: _cartItemImageSize,
                    color: isDark ? Colors.white10 : Colors.grey[100],
                    child: (item.product.imageUrl.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: item.product.imageUrl,
                            placeholder: (context, url) => const Center(
                                child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))),
                            errorWidget: (context, url, error) => Icon(
                                Icons.image_not_supported_outlined,
                                color: theme.hintColor),
                            fit: BoxFit.cover,
                          )
                        : Icon(
                            Icons.inventory_2_outlined,
                            color: theme.hintColor,
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.product.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: theme.hintColor, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\$${item.product.priceUsd.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          _buildQuantityControl(provider, item, theme),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityControl(
    CartProvider provider,
    CartItem item,
    ThemeData theme,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Decrease quantity',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: item.quantity > 1
                ? () => _updateQuantity(
                    provider,
                    item.product.id,
                    item.quantity - 1,
                  )
                : null,
            icon: const Icon(Icons.remove, size: 16),
          ),
          Semantics(
            label: 'Current quantity: ${item.quantity}',
            child: Container(
              width: 40,
              alignment: Alignment.center,
              child: Text(
                '${item.quantity}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Increase quantity',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () =>
                _updateQuantity(provider, item.product.id, item.quantity + 1),
            icon: const Icon(Icons.add, size: 16),
          ),
        ],
      ),
    );
  }

  Future<void> _updateQuantity(
    CartProvider provider,
    String productId,
    int newQuantity,
  ) async {
    try {
      await provider.updateQuantity(widget.api, productId, newQuantity);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update quantity: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  Future<void> _removeItemWithFeedback(
    CartProvider provider,
    String productId,
  ) async {
    try {
      await provider.removeFromCart(widget.api, productId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text(
                  'Item removed',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove item: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  Widget _buildCheckoutBar(CartProvider provider) {
    final theme = Theme.of(context);
    final selectedCount = provider.selectedItems.length;
    final bool allSelected =
        provider.cart?.items.every((it) => it.selected) ?? false;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 34),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Checkbox(
                value: allSelected,
                activeColor: theme.colorScheme.primary,
                shape: const CircleBorder(),
                onChanged: (val) => provider.toggleAll(val ?? false),
              ),
              const Text(
                "Select All",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(fontSize: 12, color: theme.hintColor),
                  ),
                  Text(
                    '\$${provider.selectedTotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: (selectedCount == 0 || provider.isLoading)
                  ? null
                  : () => _proceedToCheckout(provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Checkout ($selectedCount items)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _proceedToCheckout(CartProvider provider) {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CheckoutReviewPage(
            api: widget.api,
            cart: provider.getFilteredCartVm(),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to proceed: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }
}
