import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../api/authed_api_client.dart';
import '../models/product.dart';
import 'reviews_section.dart';

// ============ CONSTANTS ============
const double _imageHeight = 320;
const double _relatedItemHeight = 230;
const double _relatedItemWidth = 160;
const double _productImageSize = 160;
const double _borderRadius = 16;
const double _bottomActionHeight = 52;
const int _maxRelatedItems = 20;

class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage({
    super.key,
    required this.api,
    required this.product,
  });

  final AuthedApiClient api;
  final Product product;

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int _quantity = 1;
  bool _loading = false;
  bool _loadingRelated = true;
  List<Product> _relatedProducts = [];
  bool _inWishlist = false;
  bool _loadingWishlist = true;
  
  @override
  void initState() {
    super.initState();
    _loadRelatedProducts();
    _checkWishlistStatus();
  }

  Future<void> _loadRelatedProducts() async {
    try {
      final res = await widget.api.listProducts();
      final allProductsData = (res['products'] as List? ?? []).cast<Map<String, dynamic>>();
      
      if (mounted) {
        final products = allProductsData
            .map((p) => Product.fromJson(p))
            .where((p) => p.id != widget.product.id)
            .take(_maxRelatedItems)
            .toList();
        
        setState(() {
          _relatedProducts = products;
          _loadingRelated = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingRelated = false);
        debugPrint("Error loading related products: $e");
      }
    }
  }

  Future<void> _checkWishlistStatus() async {
    try {
      final res = await widget.api.isInWishlist(productId: widget.product.id);
      if (mounted) {
        setState(() {
          _inWishlist = res['inWishlist'] == true || res['isInWishlist'] == true;
          _loadingWishlist = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingWishlist = false);
    }
  }

  Future<void> _toggleWishlist() async {
    final originalState = _inWishlist;
    setState(() => _inWishlist = !_inWishlist);
    
    try {
      if (originalState) {
        await widget.api.removeFromWishlist(productId: widget.product.id);
      } else {
        await widget.api.addToWishlist(productId: widget.product.id);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _inWishlist = originalState);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update wishlist: $e')));
      }
    }
  }

  Future<void> _addToCart() async {
    if (_quantity < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a quantity'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (widget.product.stock < _quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only ${widget.product.stock} items available'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await context.read<CartProvider>().addToCart(widget.api, widget.product.id, _quantity);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Added to cart successfully!', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        // Reset quantity after successful add
        setState(() => _quantity = 1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to cart: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final product = widget.product;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Product Details', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _loadingWishlist
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _inWishlist ? Icons.favorite : Icons.favorite_border,
                    color: _inWishlist ? Colors.redAccent : null,
                  ),
            onPressed: _loadingWishlist ? null : _toggleWishlist,
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomAction(product.stock),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductImage(product, theme, isDark),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.category.toUpperCase(),
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(product.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(
                    '\$${product.priceUsd.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    product.description.isNotEmpty ? product.description : 'No description available.',
                    style: TextStyle(color: theme.hintColor, height: 1.5, fontSize: 15),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Divider(color: theme.dividerColor),
                  ),
                  ReviewsSection(
                    api: widget.api,
                    product: product,
                    onReviewAdded: () {
                      // Optionally refresh related products or UI
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Divider(color: theme.dividerColor),
                  ),
                  const Text('You might also like', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildRelatedSection(theme),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(Product product, ThemeData theme, bool isDark) {
    return Container(
      height: _imageHeight,
      width: double.infinity,
      color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
      child: product.imageUrl.isEmpty
          ? Icon(Icons.image, size: 80, color: theme.dividerColor)
          : Image.network(
              product.imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: 80, color: theme.dividerColor),
            ),
    );
  }

  Widget _buildRelatedSection(ThemeData theme) {
    if (_loadingRelated) return const Center(child: CircularProgressIndicator());
    if (_relatedProducts.isEmpty) {
      return Center(
        child: Text('No related products', style: TextStyle(color: theme.hintColor)),
      );
    }
    return SizedBox(
      height: _relatedItemHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _relatedProducts.length,
        itemBuilder: (context, i) {
          final product = _relatedProducts[i];
          return GestureDetector(
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailsPage(api: widget.api, product: product),
              ),
            ),
            child: _buildRelatedProductCard(product, theme),
          );
        },
      ),
    );
  }

  Widget _buildRelatedProductCard(Product product, ThemeData theme) {
    return Container(
      width: _relatedItemWidth,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(_borderRadius),
            child: Container(
              height: _productImageSize,
              width: _productImageSize,
              color: theme.brightness == Brightness.dark ? Colors.white10 : Colors.grey[100],
              child: product.imageUrl.isNotEmpty
                  ? Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.image, color: theme.hintColor),
                    )
                  : Icon(Icons.image, color: theme.hintColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            '\$${product.priceUsd.toStringAsFixed(2)}',
            style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(int stock) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isOutOfStock = stock == 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Decrease quantity',
                  onPressed: _quantity > 1 && !_loading && !isOutOfStock
                      ? () => setState(() => _quantity--)
                      : null,
                  icon: const Icon(Icons.remove, size: 20),
                ),
                Semantics(
                  label: 'Quantity: $_quantity',
                  child: Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                IconButton(
                  tooltip: 'Increase quantity',
                  onPressed: _quantity < stock && !_loading && !isOutOfStock
                      ? () => setState(() => _quantity++)
                      : null,
                  icon: const Icon(Icons.add, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: _bottomActionHeight,
              child: ElevatedButton(
                onPressed: (isOutOfStock || _loading) ? null : _addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(isOutOfStock ? 'OUT OF STOCK' : 'ADD TO CART'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}