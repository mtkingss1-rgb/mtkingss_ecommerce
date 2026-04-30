import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart.dart';
import '../api/authed_api_client.dart';


// ============ CUSTOM EXCEPTIONS ============
class CartException implements Exception {
  final String message;
  final String? type; // 'network', 'validation', 'server'
  CartException(this.message, {this.type});
  @override
  String toString() => message;
}

class CartProvider with ChangeNotifier {
  CartResponse? _cart;
  bool _isLoading = false;
  
  // Operation-specific loading states
  final Set<String> _addingProductIds = {};
  final Set<String> _removingProductIds = {};
  final Set<String> _updatingProductIds = {};

  CartResponse? get cart => _cart;
  bool get isLoading => _isLoading;

  // Check if a specific product is being added/removed/updated
  bool isProductAdding(String productId) => _addingProductIds.contains(productId);
  bool isProductRemoving(String productId) => _removingProductIds.contains(productId);
  bool isProductUpdating(String productId) => _updatingProductIds.contains(productId);

  List<CartItem> get selectedItems =>
      _cart?.items.where((item) => item.selected).toList() ?? [];

  double get selectedTotal =>
      selectedItems.fold(0.0, (sum, item) => sum + (item.product.priceUsd * item.quantity));

  /// Load cart from local storage on app startup
  Future<void> loadCartFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartString = prefs.getString('saved_cart');

      if (cartString != null) {
        final cartJson = jsonDecode(cartString);
        _cart = CartResponse.fromJson(cartJson);
        notifyListeners();
        debugPrint("✅ Cart loaded from disk");
      }
    } catch (e) {
      debugPrint("⚠️ Failed to load cart from disk: $e");
    }
  }

  /// Save cart to local storage (background)
  Future<void> _saveCartToDisk() async {
    if (_cart == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartString = jsonEncode(_cart!.toJson());
      await prefs.setString('saved_cart', cartString);
    } catch (e) {
      debugPrint("⚠️ Failed to save cart to disk: $e");
    }
  }

  /// Fetch cart from API and enrich with product data
  Future<void> fetchCart(AuthedApiClient api) async {
    _isLoading = true;
    notifyListeners();

    try {
      final cartJson = await api.getCart();
      final productsJson = await api.listProducts();
      final List allProducts = productsJson['products'] ?? [];

      CartResponse tempCart = CartResponse.fromJson(cartJson);

      for (var item in tempCart.items) {
        final fullProductMap = allProducts.firstWhere(
          (p) => p['_id'].toString() == item.product.id,
          orElse: () => null,
        );

        if (fullProductMap != null) {
          item.product.updateFromMap(fullProductMap);
        }
      }

      _cart = tempCart;
      _saveCartToDisk();
      debugPrint("✅ Cart fetched successfully");
    } on CartException {
      rethrow;
    } catch (e) {
      debugPrint("❌ Fetch error: $e");
      throw CartException("Failed to fetch cart: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add product to cart with operation-specific loading
  Future<void> addToCart(AuthedApiClient api, String productId, int quantity) async {
    _addingProductIds.add(productId);
    notifyListeners();

    try {
      await api.addToCart(productId: productId, quantity: quantity);
      await fetchCart(api);
      debugPrint("✅ Product $productId added to cart");
    } on CartException {
      _addingProductIds.remove(productId);
      notifyListeners();
      rethrow;
    } catch (e) {
      _addingProductIds.remove(productId);
      notifyListeners();
      debugPrint("❌ Add error: $e");
      throw CartException("Failed to add to cart: $e");
    }
  }

  /// Update quantity with optimistic update and rollback on error
  Future<void> updateQuantity(AuthedApiClient api, String productId, int quantity) async {
    if (quantity < 1 || _cart == null) {
      throw CartException("Invalid quantity", type: 'validation');
    }

    final itemIndex = _cart!.items.indexWhere((it) => it.product.id == productId);
    if (itemIndex < 0) {
      throw CartException("Product not found in cart", type: 'validation');
    }

    _updatingProductIds.add(productId);
    final oldQuantity = _cart!.items[itemIndex].quantity;

    try {
      // Optimistic update
      _cart!.items[itemIndex].quantity = quantity;
      notifyListeners();
      _saveCartToDisk();

      // API call
      await api.updateCartItemQuantity(productId: productId, quantity: quantity);
      debugPrint("✅ Quantity updated for $productId");
    } catch (e) {
      // Rollback on error
      _cart!.items[itemIndex].quantity = oldQuantity;
      notifyListeners();
      _saveCartToDisk();
      
      debugPrint("❌ Update error (rolled back): $e");
      throw CartException("Failed to update quantity: $e");
    } finally {
      _updatingProductIds.remove(productId);
      notifyListeners();
    }
  }

  /// Remove item with optimistic update and rollback
  Future<void> removeFromCart(AuthedApiClient api, String productId) async {
    if (_cart == null) {
      throw CartException("Cart is empty", type: 'validation');
    }

    final itemIndex = _cart!.items.indexWhere((it) => it.product.id == productId);
    if (itemIndex < 0) {
      throw CartException("Product not found in cart", type: 'validation');
    }

    _removingProductIds.add(productId);
    final removedItem = _cart!.items[itemIndex];

    try {
      // Optimistic removal
      _cart!.items.removeAt(itemIndex);
      notifyListeners();
      _saveCartToDisk();

      // API call
      await api.removeFromCart(productId: productId);
      debugPrint("✅ Product $productId removed from cart");
    } catch (e) {
      // Rollback on error
      _cart!.items.insert(itemIndex, removedItem);
      notifyListeners();
      _saveCartToDisk();
      
      debugPrint("❌ Remove error (rolled back): $e");
      throw CartException("Failed to remove from cart: $e");
    } finally {
      _removingProductIds.remove(productId);
      notifyListeners();
    }
  }

  /// Toggle selection for a single product
  void toggleSelection(String productId) {
    if (_cart == null) return;
    try {
      final item = _cart!.items.firstWhere((it) => it.product.id == productId);
      item.selected = !item.selected;
      notifyListeners();
      _saveCartToDisk();
    } catch (e) {
      debugPrint("⚠️ Toggle error: Product not found");
    }
  }

  /// Toggle all items selection
  void toggleAll(bool selected) {
    if (_cart == null) return;
    for (var item in _cart!.items) {
      item.selected = selected;
    }
    notifyListeners();
    _saveCartToDisk();
  }

  /// Get filtered cart view model (only selected items)
  CartVm getFilteredCartVm() {
    return CartVm(
      id: _cart?.id ?? '',
      items: selectedItems
          .map((it) => CartItemVm(
            productId: it.product.id,
            title: it.product.title,
            priceUsd: it.product.priceUsd,
            quantity: it.quantity,
            imageUrl: it.product.imageUrl,
            selected: true,
          ))
          .toList(),
      totalUsd: selectedTotal,
      currency: _cart?.currency ?? 'USD',
    );
  }
}