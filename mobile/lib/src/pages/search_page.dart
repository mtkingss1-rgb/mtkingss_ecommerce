import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api/authed_api_client.dart';
import '../models/product.dart';
import '../products/product_details_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.api});
  final AuthedApiClient api;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  final int _limit = 20;
  List<Map<String, dynamic>> _items = [];
  final _searchCtrl = TextEditingController();
  String _sort = 'newest';
  String _category = 'All';
  double _minPrice = 0;
  double _maxPrice = 1000;
  final List<String> _categories = ['All', 'Phones', 'Tablets', 'Accessories', 'Fragrance'];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    if (mounted) setState(() {
      _loading = true;
      _page = 1;
      _hasMore = true;
    });
    try {
      final j = await widget.api.listProducts(
        q: _searchCtrl.text,
        sort: _sort,
        minPrice: _minPrice.toStringAsFixed(0),
        maxPrice: _maxPrice.toStringAsFixed(0),
        page: _page,
        limit: _limit,
      );
      var raw = (j['products'] as List? ?? []);

      // Filter by category if not 'All'
      if (_category != 'All') {
        raw = raw
            .where((p) =>
                (p['category'] as String?)?.toLowerCase() ==
                _category.toLowerCase())
            .toList();
      }

      if (mounted) setState(() {
        _items = raw.cast<Map<String, dynamic>>();
        if (raw.length < _limit) _hasMore = false;
      });
    } catch (e) {
      debugPrint('Error loading products: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading) return;
    if (mounted) setState(() => _loadingMore = true);
    try {
      _page++;
      final j = await widget.api.listProducts(
        q: _searchCtrl.text,
        sort: _sort,
        minPrice: _minPrice.toStringAsFixed(0),
        maxPrice: _maxPrice.toStringAsFixed(0),
        page: _page,
        limit: _limit,
      );
      var raw = (j['products'] as List? ?? []);

      if (_category != 'All') {
        raw = raw
            .where((p) =>
                (p['category'] as String?)?.toLowerCase() ==
                _category.toLowerCase())
            .toList();
      }

      if (mounted) setState(() {
        _items.addAll(raw.cast<Map<String, dynamic>>());
        if (raw.length < _limit) _hasMore = false;
      });
    } catch (e) {
      debugPrint('Error loading more products: $e');
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Search Bar
        Container(
          color: theme.appBarTheme.backgroundColor,
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        _load();
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark ? Colors.white10 : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _load(),
          ),
        ),
        // Filters
        Container(
          color: theme.cardColor,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Filter
              Text('Category',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _category == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() => _category = cat);
                          _load();
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              // Price Range Slider
              Text('Price Range',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 8),
              RangeSlider(
                values: RangeValues(_minPrice, _maxPrice),
                min: 0,
                max: 1000,
                onChanged: (RangeValues values) {
                  setState(() {
                    _minPrice = values.start;
                    _maxPrice = values.end;
                  });
                },
                onChangeEnd: (_) => _load(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('\$${_minPrice.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('\$${_maxPrice.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Sort
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sort By',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            )),
                        const SizedBox(height: 8),
                        DropdownButton<String>(
                          value: _sort,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'newest', child: Text('Newest')),
                            DropdownMenuItem(value: 'price_asc', child: Text('Price: Low to High')),
                            DropdownMenuItem(value: 'price_desc', child: Text('Price: High to Low')),
                          ],
                          onChanged: (v) {
                            setState(() => _sort = v!);
                            _load();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Results
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: _items.isEmpty && !_loading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_outlined,
                          size: 80, color: theme.hintColor),
                      const SizedBox(height: 16),
                      Text(
                        'No products found',
                        style: TextStyle(color: theme.hintColor, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting filters',
                        style: TextStyle(color: theme.hintColor, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: GridView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.65,
                        ),
                        itemCount: _items.length,
                        itemBuilder: (context, i) {
                          final raw = _items[i];
                          final product = Product.fromJson(raw);
                          return GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailsPage(api: widget.api, product: product),
                              ),
                            ),
                            child: _buildProductCard(product, theme),
                          );
                        },
                      ),
                    ),
                    if (_loadingMore)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              width: double.infinity,
              child: (product.imageUrl.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      placeholder: (context, url) => const Center(
                        child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (context, url, error) =>
                          Icon(Icons.broken_image, color: theme.hintColor),
                      fit: BoxFit.cover)
                  : Icon(Icons.image, color: theme.hintColor),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  product.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: theme.hintColor),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${product.priceUsd.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        fontSize: 13,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: product.stock > 0
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.stock > 0 ? 'Stock' : 'Out',
                        style: TextStyle(
                          fontSize: 10,
                          color: product.stock > 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
