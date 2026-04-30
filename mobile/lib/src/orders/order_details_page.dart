import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/order.dart';
import '../api/authed_api_client.dart';
import '../products/product_details_page.dart'; 

class OrderDetailsPage extends StatelessWidget {
  const OrderDetailsPage({super.key, required this.order, required this.api});
  
  final Order order;
  final AuthedApiClient api; 

  static const LatLng _userPos = LatLng(11.5564, 104.9282);
  static const LatLng _driverPos = LatLng(11.5620, 104.9350);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final double subtotal = order.totalUsd;
    final double grandTotal = subtotal; 

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Order #${order.id.substring(order.id.length - 6).toUpperCase()}', 
          style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        foregroundColor: theme.appBarTheme.foregroundColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Map Tracking Section
            SizedBox(
              height: 250,
              child: FlutterMap(
                options: const MapOptions(
                  initialCenter: _userPos,
                  initialZoom: 14.5,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.mtkingss.app',
                    // Darken the map tiles slightly for better dark mode visibility
                    tileBuilder: isDark 
                      ? (context, tileWidget, tile) => ColorFiltered(
                          colorFilter: const ColorFilter.matrix([
                            -1, 0, 0, 0, 255,
                            0, -1, 0, 0, 255,
                            0, 0, -1, 0, 255,
                            0, 0, 0, 1, 0,
                          ]),
                          child: tileWidget,
                        )
                      : null,
                  ),
                  MarkerLayer(
                    markers: [
                      const Marker(
                        point: _driverPos,
                        width: 45,
                        height: 45,
                        child: Icon(Icons.delivery_dining, color: Colors.deepPurple, size: 38),
                      ),
                      const Marker(
                        point: _userPos,
                        width: 45,
                        height: 45,
                        child: Icon(Icons.location_on, color: Colors.red, size: 38),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(context),
                  const SizedBox(height: 24),

                  const Text('Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildTimeline(context),
                  const SizedBox(height: 24),

                  const Text('Items Ordered', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  
                  // 2. Clickable Items List
                  ...order.items.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor),
                        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 8)],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          try {
                            final res = await api.listProducts();
                            final List products = (res['products'] as List? ?? []);
                            
                            final realProduct = products.firstWhere(
                              (p) => p['_id']?.toString() == item.productId,
                              orElse: () => null,
                            );

                            if (realProduct != null && context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailsPage(api: api, product: realProduct),
                                ),
                              );
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Product details not found in store.")),
                                );
                              }
                            }
                          } catch (e) {
                            debugPrint("Error: $e");
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 65,
                                  height: 65,
                                  color: isDark ? Colors.white10 : Colors.grey.shade50,
                                  child: item.imageUrl.isNotEmpty 
                                    ? Image.network(item.imageUrl, fit: BoxFit.cover, 
                                        errorBuilder: (_,__,___) => Icon(Icons.image, color: theme.hintColor))
                                    : Icon(Icons.inventory_2_outlined, color: theme.hintColor),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, 
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                    const SizedBox(height: 6),
                                    Text('Qty: ${item.quantity}', style: TextStyle(color: theme.hintColor, fontSize: 13)),
                                  ],
                                ),
                              ),
                              Text('\$${item.lineTotal.toStringAsFixed(2)}', 
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: theme.colorScheme.primary)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  const Text('Payment Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  
                  // 3. Payment Breakdown
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.dividerColor),
                      boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                    ),
                    child: Column(
                      children: [
                        _priceRow(context, 'Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
                        _priceRow(context, 'Delivery Fee', 'Free'),
                        _priceRow(context, 'Service Fee', 'Free'),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Divider(color: theme.dividerColor),
                        ),
                        _priceRow(context, 'Total Paid', '\$${grandTotal.toStringAsFixed(2)}', isTotal: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
        boxShadow: theme.brightness == Brightness.dark ? null : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Icon(Icons.local_shipping, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.status, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("Driver is 1.2km away", style: TextStyle(color: theme.hintColor, fontSize: 13)),
                  ],
                ),
              ),
              Text("15 mins", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.primary)),
            ],
          ),
          Divider(height: 24, color: theme.dividerColor),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statusAction(context, Icons.call, "Call Driver", Colors.green),
              Container(width: 1, height: 20, color: theme.dividerColor),
              _statusAction(context, Icons.chat_bubble_outline, "Message", Colors.blue),
            ],
          )
        ],
      ),
    );
  }

  Widget _statusAction(BuildContext context, IconData icon, String label, Color color) {
    return InkWell(
      onTap: () {},
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context) {
    return Column(
      children: [
        _timelineStep(context, "On the Way", "Driver is heading to your location", true),
        _timelineStep(context, "Processing", "Seller has packed your items", false),
        _timelineStep(context, "Order Placed", "We have received your order", false),
      ],
    );
  }

  Widget _timelineStep(BuildContext context, String title, String subtitle, bool isActive) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Column(
          children: [
            Icon(Icons.check_circle, color: isActive ? theme.colorScheme.primary : theme.dividerColor, size: 20),
            Container(width: 2, height: 20, color: theme.dividerColor),
          ],
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal, 
              color: isActive ? theme.textTheme.bodyLarge?.color : theme.hintColor
            )),
            Text(subtitle, style: TextStyle(fontSize: 12, color: theme.hintColor)),
          ],
        ),
      ],
    );
  }

  Widget _priceRow(BuildContext context, String label, String displayValue, {bool isTotal = false}) {
    final theme = Theme.of(context);
    final bool isFree = displayValue.toLowerCase() == 'free';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            color: isTotal ? theme.textTheme.bodyLarge?.color : theme.hintColor, 
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14
          )),
          Text(displayValue, style: TextStyle(
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
            fontSize: isTotal ? 20 : 14,
            color: isTotal ? theme.colorScheme.primary : (isFree ? Colors.green : theme.textTheme.bodyLarge?.color),
          )),
        ],
      ),
    );
  }
}