import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

// Agriculture-themed color scheme
class AppColors {
  static const Color primary = Color(0xFF2E7D32);       // Deep Forest Green
  static const Color secondary = Color(0xFF8BC34A);     // Light Leaf Green
  static const Color accent = Color(0xFFFFD54F);        // Harvest Gold
  static const Color textDark = Color(0xFF33691E);      // Dark Green Text
  static const Color background = Color(0xFFF5F9EE);    // Off-white with green tint
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFB71C1C);         // Dark Red for errors
  static const Color success = Color(0xFF33691E);       // Dark Green for success
}

class AdminProductScreen extends StatefulWidget {
  const AdminProductScreen({Key? key}) : super(key: key);

  @override
  State<AdminProductScreen> createState() => _AdminProductScreenState();
}

class _AdminProductScreenState extends State<AdminProductScreen> {
  List<dynamic> products = [];
  bool showOnlyFeatured = false;
  bool isLoading = true;
  String? errorMessage;
  bool isGridView = true; // Toggle between grid and list view

  final String baseUrl = 'http://10.0.2.2:3000'; // Emulator base URL

  @override
  void initState() {
    super.initState();
    fetchProducts().then((_) {
      if (products.isNotEmpty) {
        getImageUrl(products.first);
      }
    });
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<void> fetchProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final url = showOnlyFeatured
          ? '$baseUrl/api/admin/products/featured'
          : '$baseUrl/api/admin/products';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          products = data['products'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = "Server error: ${response.statusCode}";
        });
        _showErrorSnackBar("Failed to load products");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
      _showErrorSnackBar("Network error: ${e.toString()}");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> toggleFeatured(int productId, bool makeFeatured) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Authentication token not found');

      final endpoint = makeFeatured ? 'feature' : 'unfeature';
      final loadingMessage = makeFeatured
          ? 'Marking product as featured...'
          : 'Removing product from featured...';

      final loadingSnackBar = SnackBar(
        content: Row(
          children: [
            const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                )),
            const SizedBox(width: 16),
            Text(loadingMessage),
          ],
        ),
        duration: const Duration(seconds: 60),
        backgroundColor: AppColors.primary,
        margin: const EdgeInsets.all(16),
        behavior: SnackBarBehavior.floating,
      );

      final snackBarController =
      ScaffoldMessenger.of(context).showSnackBar(loadingSnackBar);

      final response = await http.put(
        Uri.parse('$baseUrl/api/admin/products/$productId/$endpoint'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      // Hide the loading snackbar
      snackBarController.close();

      if (response.statusCode == 200) {
        _showSuccessSnackBar(makeFeatured
            ? 'Product marked as featured'
            : 'Product removed from featured');
        fetchProducts();
      } else {
        _showErrorSnackBar("Failed to update feature status");
      }
    } catch (e) {
      _showErrorSnackBar("Error: ${e.toString()}");
    }
  }

  Future<void> deleteProduct(int productId, String productName) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirm Deletion',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "$productName"?',
          style: TextStyle(color: Colors.grey.shade700),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: TextStyle(color: AppColors.textDark),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                final token = await getToken();
                if (token == null)
                  throw Exception('Authentication token not found');

                final loadingSnackBar = SnackBar(
                  content: Row(
                    children: const [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 16),
                      Text('Deleting product...'),
                    ],
                  ),
                  duration: const Duration(seconds: 60),
                  backgroundColor: AppColors.primary,
                  margin: const EdgeInsets.all(16),
                  behavior: SnackBarBehavior.floating,
                );

                final snackBarController = ScaffoldMessenger.of(context)
                    .showSnackBar(loadingSnackBar);

                final response = await http.delete(
                  Uri.parse('$baseUrl/api/admin/products/$productId'),
                  headers: {'Authorization': 'Bearer $token'},
                ).timeout(const Duration(seconds: 10));

                // Hide the loading snackbar
                snackBarController.close();

                if (response.statusCode == 200) {
                  _showSuccessSnackBar('Product deleted successfully');
                  fetchProducts();
                } else {
                  _showErrorSnackBar("Failed to delete product");
                }
              } catch (e) {
                _showErrorSnackBar("Error: ${e.toString()}");
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  String? getImageUrl(dynamic product) {
    if (product['images'] == null) return null;

    List<dynamic> imageList = [];

    if (product['images'] is String) {
      try {
        imageList = jsonDecode(product['images']);
      } catch (e) {
        print("⚠️ Failed to parse image string: ${product['images']}");
        return null;
      }
    } else if (product['images'] is List) {
      imageList = product['images'];
    }

    if (imageList.isNotEmpty) {
      String rawUrl = imageList[0].toString();

      if (!rawUrl.startsWith('/')) {
        rawUrl = '/$rawUrl';
      }

      final finalUrl = rawUrl.startsWith('http')
          ? rawUrl
          : '$baseUrl$rawUrl';

      print('🖼️ Flutter image URL: $finalUrl');
      return finalUrl;
    }

    return null;
  }

  // Responsive helper method
  int _getCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 1200) return 4;  // Desktop
    if (screenWidth >= 900) return 3;   // Tablet landscape
    if (screenWidth >= 600) return 2;   // Tablet portrait
    return 2; // Mobile (changed from 1 to 2 for better mobile experience)
  }

  double _getChildAspectRatio(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = _getCrossAxisCount(context);

    // Calculate available width per card
    const horizontalPadding = 32.0; // Total horizontal padding
    const crossAxisSpacing = 16.0;
    final totalSpacing = (crossAxisCount - 1) * crossAxisSpacing;
    final availableWidth = screenWidth - horizontalPadding - totalSpacing;
    final cardWidth = availableWidth / crossAxisCount;

    // Dynamic height calculation based on content
    const imageHeight = 120.0; // Reduced from 150
    const contentPadding = 12.0;
    const titleHeight = 32.0; // 2 lines max
    const buttonHeight = 40.0;
    const spacing = 8.0;

    final cardHeight = imageHeight + contentPadding * 2 + titleHeight + buttonHeight + spacing;

    return cardWidth / cardHeight;
  }

  Widget _buildGridProductCard(dynamic product) {
    final imageUrl = getImageUrl(product);
    final bool isFeatured = product['is_featured'] ?? false;
    final double price = product['price'] is int
        ? product['price'].toDouble()
        : (product['price'] is String
        ? double.tryParse(product['price']) ?? 0.0
        : product['price'] ?? 0.0);

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isFeatured
            ? BorderSide(color: AppColors.accent, width: 2)
            : BorderSide.none,
      ),
      elevation: 2,
      shadowColor: Colors.black26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image with stack for featured badge
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: imageUrl != null
                        ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey.shade200,
                        highlightColor: Colors.grey.shade50,
                        child: Container(
                          color: Colors.white,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: Icon(Icons.image_not_supported,
                              size: 32, color: Colors.grey),
                        ),
                      ),
                    )
                        : Container(
                      color: Colors.grey.shade100,
                      child: const Center(
                        child: Icon(Icons.image_not_supported,
                            size: 32, color: Colors.grey),
                      ),
                    ),
                  ),
                  // Overlay gradient at the bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Featured badge
                  if (isFeatured)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.star, color: Colors.white, size: 10),
                            SizedBox(width: 2),
                            Text(
                              'FEATURED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Price badge
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${price.toStringAsFixed(0)} XAF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Product details
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      product['name'] ?? 'Unnamed Product',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Feature toggle button
                      Material(
                        color: isFeatured ? AppColors.accent.withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        child: InkWell(
                          onTap: () {
                            toggleFeatured(product['id'], !isFeatured);
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Icon(
                              isFeatured ? Icons.star : Icons.star_border,
                              color: isFeatured ? AppColors.accent : Colors.grey,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      // Delete button
                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        child: InkWell(
                          onTap: () {
                            deleteProduct(product['id'], product['name'] ?? 'This product');
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Icon(
                              Icons.delete_outline,
                              color: AppColors.error,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListProductCard(dynamic product) {
    final imageUrl = getImageUrl(product);
    final bool isFeatured = product['is_featured'] ?? false;
    final double price = product['price'] is int
        ? product['price'].toDouble()
        : (product['price'] is String
        ? double.tryParse(product['price']) ?? 0.0
        : product['price'] ?? 0.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isFeatured
            ? BorderSide(color: AppColors.accent, width: 2)
            : BorderSide.none,
      ),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigate to product details if needed
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Stack(
                children: [
                  SizedBox(
                    width: 100,
                    height: 120,
                    child: imageUrl != null
                        ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey.shade200,
                        highlightColor: Colors.grey.shade50,
                        child: Container(
                          color: Colors.white,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: Icon(Icons.image_not_supported,
                              size: 32, color: Colors.grey),
                        ),
                      ),
                    )
                        : Container(
                      color: Colors.grey.shade100,
                      child: const Center(
                        child: Icon(Icons.image_not_supported,
                            size: 32, color: Colors.grey),
                      ),
                    ),
                  ),
                  if (isFeatured)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Details section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] ?? 'Unnamed Product',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${price.toStringAsFixed(0)} XAF',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Feature toggle button
                        Material(
                          color: isFeatured
                              ? AppColors.accent.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () {
                              toggleFeatured(product['id'], !isFeatured);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isFeatured ? Icons.star : Icons.star_border,
                                    color:
                                    isFeatured ? AppColors.accent : Colors.grey,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isFeatured ? 'Featured' : 'Feature',
                                    style: TextStyle(
                                      color: isFeatured
                                          ? AppColors.accent
                                          : Colors.grey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Delete button
                        Material(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () {
                              deleteProduct(product['id'],
                                  product['name'] ?? 'This product');
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.delete_outline,
                                    color: AppColors.error,
                                    size: 18,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: AppColors.error,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  showOnlyFeatured ? Icons.star_border : Icons.inventory_2_outlined,
                  size: 60,
                  color: AppColors.primary.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                showOnlyFeatured
                    ? 'No Featured Products'
                    : 'No Products Found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                showOnlyFeatured
                    ? 'Feature products to display them here'
                    : 'Add products to start managing your inventory',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () {
                  if (showOnlyFeatured) {
                    setState(() {
                      showOnlyFeatured = false;
                    });
                    fetchProducts();
                  } else {
                    // Navigate to add product
                  }
                },
                icon: Icon(showOnlyFeatured ? Icons.visibility : Icons.add),
                label: Text(
                  showOnlyFeatured ? 'Show All Products' : 'Add New Product',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 60,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Failed to Load Products',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage ?? 'An unknown error occurred',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: fetchProducts,
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'Try Again',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: isGridView
          ? GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(context),
          childAspectRatio: _getChildAspectRatio(context),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                      BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            height: 12,
                            width: double.infinity,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              height: 24,
                              width: 24,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              height: 24,
                              width: 24,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            height: 120,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 100,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(12)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          height: 16,
                          width: 150,
                          color: Colors.white,
                        ),
                        Container(
                          height: 14,
                          width: 80,
                          color: Colors.white,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: 30,
                              width: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              height: 30,
                              width: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
        ),
        cardTheme: CardTheme(
          color: AppColors.cardBackground,
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  showOnlyFeatured ? "Featured Products" : "All Products",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  "Agricultural Store Admin",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
            actions: [
              // View toggle button
              IconButton(
                icon: Icon(
                  isGridView ? Icons.view_list : Icons.grid_view,
                  color: Colors.white,
                ),
                tooltip: isGridView ? 'Switch to list view' : 'Switch to grid view',
                onPressed: () {
                  setState(() {
                    isGridView = !isGridView;
                  });
                },
              ),
              // Featured filter button
              IconButton(
                icon: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.star,
                      color: showOnlyFeatured
                          ? AppColors.accent
                          : Colors.white.withOpacity(0.7),
                      size: 28,
                    ),
                    if (showOnlyFeatured)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                tooltip: showOnlyFeatured ? 'Show all products' : 'Show only featured',
                onPressed: () {
                  setState(() {
                    showOnlyFeatured = !showOnlyFeatured;
                  });
                  fetchProducts();
                },
              ),
              // Refresh button
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Refresh products',
                onPressed: fetchProducts,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: fetchProducts,
          color: AppColors.primary,
          child: isLoading
              ? _buildLoadingState()
              : errorMessage != null
              ? _buildErrorState()
              : products.isEmpty
              ? _buildEmptyState()
              : isGridView
              ? GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate:
            SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _getCrossAxisCount(context),
              childAspectRatio: _getChildAspectRatio(context),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return _buildGridProductCard(products[index]);
            },
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return _buildListProductCard(products[index]);
            },
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            // Navigate to add product screen
            // Navigator.push(context, MaterialPageRoute(builder: (context) => AddProductScreen()));
          },
          label: Text(
            "Add Product",
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width < 600 ? 12 : 14,
            ),
          ),
          icon: const Icon(Icons.add),
          elevation: 4,
        ),
      ),
    );
  }
}