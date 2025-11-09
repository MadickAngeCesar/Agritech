import 'dart:convert';
import 'package:agritech/screens/my%20Products/userProductDetailScreen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class MyProductsScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> userData;

  const MyProductsScreen({
    Key? key,
    required this.token,
    required this.userData,
  }) : super(key: key);

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  List<dynamic> products = [];
  bool isLoading = true;

  // Define agriculture theme colors
  final primaryGreen = Color(0xFF2E7D32); // Deep forest green
  final secondaryGreen = Color(0xFF66BB6A); // Medium green
  final accentGreen = Color(0xFFB9F6CA); // Light mint green
  final backgroundColor = Color(0xFFF5F9F5); // Very light green/off-white
  final textDark = Color(0xFF1B5E20); // Dark green for text

  Future<void> fetchMyProducts() async {
    setState(() => isLoading = true);

    final response = await http.get(
      Uri.parse('http://51.75.31.246:3000/api/my-products'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        products = data['data'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      print('Failed to load products: ${response.body}');
    }
  }

  void _confirmDelete(int productId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          'Delete Product',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this product?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[700]),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(context);
              deleteProduct(productId);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 5,
      ),
    );
  }

  Future<void> deleteProduct(int productId) async {
    final response = await http.delete(
      Uri.parse('http://51.75.31.246:3000/api/my-products/$productId'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Product deleted successfully',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: secondaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      fetchMyProducts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete product',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      print('Error deleting: ${response.body}');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchMyProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryGreen,
        title: Text(
          "My Products",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: fetchMyProducts,
          ),
        ],
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: primaryGreen,
        ),
      )
          : products.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.eco,
              size: 80,
              color: secondaryGreen.withOpacity(0.7),
            ),
            SizedBox(height: 20),
            Text(
              "No products yet",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: textDark,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Your agricultural products will appear here",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: fetchMyProducts,
        color: primaryGreen,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];

            List<dynamic> imageList = [];
            final imagesField = product['images'];

            if (imagesField is String) {
              try {
                imageList = jsonDecode(imagesField);
              } catch (e) {
                print('Error decoding images: $e');
              }
            } else if (imagesField is List) {
              imageList = imagesField;
            }

            String? imageUrl = imageList.isNotEmpty
                ? 'http://51.75.31.246:3000${imageList[0]}'
                : null;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserProductDetailsScreen(
                        product: product,
                        userData: widget.userData,
                        token: widget.token,
                      ),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product image with category badge
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: imageUrl != null
                              ? Image.network(
                            imageUrl,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  height: 180,
                                  width: double.infinity,
                                  color: accentGreen.withOpacity(0.3),
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 50,
                                    color: secondaryGreen,
                                  ),
                                ),
                          )
                              : Container(
                            height: 180,
                            width: double.infinity,
                            color: accentGreen.withOpacity(0.3),
                            child: Icon(
                              Icons.grass,
                              size: 50,
                              color: secondaryGreen,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: primaryGreen.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              product['category'] ?? 'Agricultural Product',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Product details
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  product['name'] ?? 'Product Name',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: textDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: secondaryGreen.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: secondaryGreen.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  "XAF ${product['price']}",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: primaryGreen,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 8),
                          if (product['description'] != null)
                            Text(
                              product['description'],
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                          SizedBox(height: 16),
                          Row(
                            children: [
                              // Stock status indicator
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: (product['quantity'] != null && product['quantity'] > 0)
                                      ? accentGreen
                                      : Colors.red[100],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  (product['quantity'] != null && product['quantity'] > 0)
                                      ? "In Stock"
                                      : "",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: (product['quantity'] != null && product['quantity'] > 0)
                                        ? primaryGreen
                                        : Colors.red[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),

                              Spacer(),

                              // Action buttons
                              IconButton(
                                icon: Icon(
                                  Icons.edit_outlined,
                                  color: primaryGreen,
                                ),
                                onPressed: () {
                                  // Edit functionality to be implemented
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.red[700],
                                ),
                                onPressed: () => _confirmDelete(product['id']),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryGreen,
        onPressed: () {
          // Navigate to add product screen
        },
        child: Icon(Icons.add, color: Colors.white),
        elevation: 3,
      ),
    );
  }
}