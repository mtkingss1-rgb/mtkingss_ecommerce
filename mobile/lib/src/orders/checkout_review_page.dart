import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/authed_api_client.dart';
import '../models/address.dart';
import '../models/cart.dart';
import '../providers/cart_provider.dart';
import '../pages/addresses_page.dart';
import 'checkout_page.dart';

// ============ CONSTANTS ============
const double _cardBorderRadius = 16;
const double _containerPadding = 16;
const double _bottomBarHeight = 48;
const double _bottomBarWidth = 160;
const double _summaryImageSize = 50;
const double _summaryImageBorderRadius = 8;

class CheckoutReviewPage extends StatefulWidget {
  final AuthedApiClient api;
  final CartVm cart;

  const CheckoutReviewPage({super.key, required this.api, required this.cart});

  @override
  State<CheckoutReviewPage> createState() => _CheckoutReviewPageState();
}

class _CheckoutReviewPageState extends State<CheckoutReviewPage> {
  bool _isProcessing = false;
  bool _loadingAddresses = true;
  List<Address> _addresses = [];
  Address? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    if (mounted) setState(() => _loadingAddresses = true);
    try {
      final res = await widget.api.getAddresses();
      final addressList = (res['addresses'] as List? ?? []).map((e) => Address.fromJson(e)).toList();
      if (mounted) {
        setState(() {
          _addresses = addressList;
          _selectedAddress = addressList.isNotEmpty 
              ? addressList.firstWhere((a) => a.isDefault, orElse: () => addressList.first) 
              : null;
          _loadingAddresses = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingAddresses = false);
        _showErrorSnackbar('Could not load addresses: $e');
      }
    }
  }

  Future<void> _placeOrder() async {
    // Pre-order validation
    if (widget.cart.items.isEmpty) {
      _showErrorSnackbar('Your cart is empty');
      return;
    }

    if (widget.cart.totalUsd <= 0) {
      _showErrorSnackbar('Invalid order total');
      return;
    }

    if (_selectedAddress == null) {
      _showErrorSnackbar('Please select or add a shipping address.');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // 1. Call API to create the order
      final response = await widget.api.checkoutCreateOrder(addressId: _selectedAddress!.id);

      if (!mounted) return;

      final orderMap = response['order'] as Map<String, dynamic>? ?? {};
      final orderId = (orderMap['_id'] ?? orderMap['id'] ?? '').toString();

      if (orderId.isEmpty) {
        throw Exception('Server error: Failed to generate Order ID');
      }

      // 2. Refresh the global cart provider (non-blocking)
      try {
        await context.read<CartProvider>().fetchCart(widget.api);
      } catch (e) {
        debugPrint('Cart refresh warning: $e');
      }

      // 3. Navigate to the Payment/Success Page
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => CheckoutPage(orderId: orderId, api: widget.api)),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        final errorMsg = _parseErrorMessage(e.toString());
        _showErrorSnackbar(errorMsg);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  String _parseErrorMessage(String error) {
    final cleanError = error.replaceFirst('Exception: ', '');
    if (cleanError.contains('Connection refused')) return 'Network error: Please check your connection';
    if (cleanError.contains('timeout')) return 'Request timeout: Please try again';
    if (cleanError.contains('Order ID')) return 'Failed to create order. Please contact support.';
    if (cleanError.contains('Socket')) return 'Network error: Please check your connection';
    return 'Order failed: $cleanError';
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(label: 'Retry', textColor: Colors.white, onPressed: _placeOrder),
      ),
    );
  }

  void _showAddressPicker() async {
    final selectedId = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Select Address', style: Theme.of(context).textTheme.titleLarge),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _addresses.length,
                  itemBuilder: (context, index) {
                    final address = _addresses[index];
                    return RadioListTile<String>(
                      title: Text(address.label),
                      subtitle: Text('${address.street}, ${address.city}'),
                      value: address.id,
                      groupValue: _selectedAddress?.id,
                      onChanged: (String? value) {
                        Navigator.pop(context, value);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selectedId != null && selectedId != _selectedAddress?.id) {
      setState(() => _selectedAddress = _addresses.firstWhere((a) => a.id == selectedId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedItems = widget.cart.items;
    final double subtotal = widget.cart.totalUsd;
    const double shippingFee = 0.00;
    final double finalTotal = subtotal + shippingFee;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Confirm Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      bottomNavigationBar: _buildBottomBar(finalTotal),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // 1. Delivery Address Block
                _buildAddressSection(theme, isDark),

                // 2. Order Summary
                _buildOrderSummarySection(theme, isDark, selectedItems),

                // 3. Price Breakdown
                _buildPriceBreakdown(theme, isDark, subtotal, shippingFee, finalTotal),

                const SizedBox(height: 20),
              ],
            ),
          ),
          // Full-screen loading overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: theme.colorScheme.primary),
                        const SizedBox(height: 16),
                        const Text('Placing your order...', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddressSection(ThemeData theme, bool isDark) {
    if (_loadingAddresses) {
      return Container(
        margin: const EdgeInsets.all(_containerPadding),
        padding: const EdgeInsets.all(_containerPadding),
        decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(_cardBorderRadius)),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_selectedAddress == null) {
      return Container(
        margin: const EdgeInsets.all(_containerPadding),
        padding: const EdgeInsets.all(_containerPadding),
        decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(_cardBorderRadius)),
        child: Center(
          child: Column(
            children: [
              const Text('No Shipping Address Found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text('Please add an address in your profile to continue.', style: TextStyle(color: theme.hintColor)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddressesPage(api: widget.api)),
                ).then((_) => _loadAddresses()),
                child: const Text('Add Address'),
              )
            ],
          ),
        ),
      );
    }

    final address = _selectedAddress!;
    return Container(
      margin: const EdgeInsets.all(_containerPadding),
      padding: const EdgeInsets.all(_containerPadding),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(_cardBorderRadius),
        border: isDark ? Border.all(color: theme.dividerColor) : null,
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.location_on_rounded, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(address.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('${address.street}, ${address.city}, ${address.state}', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: theme.hintColor, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (_addresses.length > 1)
            TextButton(
              onPressed: _showAddressPicker,
              child: const Text('Change'),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderSummarySection(ThemeData theme, bool isDark, List<CartItemVm> selectedItems) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: _containerPadding),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(_cardBorderRadius),
        border: isDark ? Border.all(color: theme.dividerColor) : null,
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(_containerPadding),
            child: Text('Order Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Divider(height: 1, color: theme.dividerColor),
          ...selectedItems.map((item) => _buildSummaryItem(item, theme)),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown(ThemeData theme, bool isDark, double subtotal, double shippingFee, double finalTotal) {
    return Container(
      margin: const EdgeInsets.all(_containerPadding),
      padding: const EdgeInsets.all(_containerPadding),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(_cardBorderRadius),
        border: isDark ? Border.all(color: theme.dividerColor) : null,
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
      ),
      child: Column(
        children: [
          _priceRow('Subtotal', '\$${subtotal.toStringAsFixed(2)}', theme),
          const SizedBox(height: 12),
          _priceRow('Shipping Fee', shippingFee == 0 ? 'Free' : '\$${shippingFee.toStringAsFixed(2)}', theme),
          Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: theme.dividerColor)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('\$${finalTotal.toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: theme.colorScheme.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(CartItemVm item, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(_containerPadding),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(_summaryImageBorderRadius),
            child: Container(
              width: _summaryImageSize,
              height: _summaryImageSize,
              color: theme.brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade50,
              child: item.imageUrl.isNotEmpty
                  ? Image.network(item.imageUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => Icon(Icons.image, color: theme.hintColor))
                  : Icon(Icons.image, color: theme.hintColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('x${item.quantity}', style: TextStyle(color: theme.hintColor, fontSize: 12)),
              ],
            ),
          ),
          Text('\$${item.lineTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String displayValue, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: theme.hintColor, fontSize: 14)),
        Text(
          displayValue,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: displayValue == 'Free' ? Colors.green : theme.textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(double total) {
    final theme = Theme.of(context);
    final isActionDisabled = _isProcessing || widget.cart.items.isEmpty || _selectedAddress == null;

    return Container(
      padding: const EdgeInsets.fromLTRB(_containerPadding, 12, _containerPadding, 34),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Payment', style: TextStyle(fontSize: 12, color: theme.hintColor)),
              Text('\$${total.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: theme.colorScheme.primary)),
            ],
          ),
          SizedBox(
            height: _bottomBarHeight,
            width: _bottomBarWidth,
            child: ElevatedButton(
              onPressed: isActionDisabled ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isProcessing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : const Text('Place Order', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}