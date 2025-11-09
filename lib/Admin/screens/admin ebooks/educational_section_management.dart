import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class AdminEbookModerationScreen extends StatefulWidget {
  final String token;
  const AdminEbookModerationScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<AdminEbookModerationScreen> createState() => _AdminEbookModerationScreenState();
}

class _AdminEbookModerationScreenState extends State<AdminEbookModerationScreen>
    with TickerProviderStateMixin {
  final String baseUrl = 'http://51.75.31.246:3000/api';
  List<dynamic> pendingEbooks = [];
  bool isLoading = true;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Agriculture-themed colors
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color darkGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFE8F5E8);
  static const Color accentOrange = Color(0xFFFF8F00);
  static const Color backgroundGray = Color(0xFFF8F9FA);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color errorRed = Color(0xFFE53E3E);

  @override
  void initState() {
    super.initState();
    _initAnimations();
    fetchPendingEbooks();
  }

  String? getImageUrl(dynamic ebook) {
    if (ebook['cover_image'] != null && ebook['cover_image'].toString().isNotEmpty) {
      String rawUrl = ebook['cover_image'];

      // Add slash if missing
      if (!rawUrl.startsWith('/')) {
        rawUrl = '/$rawUrl';
      }

      final fullUrl = rawUrl.startsWith('http')
          ? rawUrl
          : '$baseUrl$rawUrl';

      debugPrint('Ebook image URL: $fullUrl'); // 👈 Log for debugging

      return fullUrl;
    }
    return null;
  }


  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> fetchPendingEbooks() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/ebooks?approved=false'));
      if (response.statusCode == 200) {
        setState(() {
          pendingEbooks = jsonDecode(response.body);
          isLoading = false;
        });
        _fadeController.forward();
        _slideController.forward();
      } else {
        setState(() => isLoading = false);
        _showSnackBar('Failed to load ebooks', isError: true);
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar('Error: ${e.toString()}', isError: true);
    }
  }

  Future<void> approveEbook(int id) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/ebooks/$id/approve'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        fetchPendingEbooks();
        _showSnackBar('Ebook approved successfully! 🌱', isSuccess: true);
      }
    } catch (e) {
      _showSnackBar('Failed to approve ebook', isError: true);
    }
  }

  Future<void> rejectEbook(int id) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/ebooks/$id'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        fetchPendingEbooks();
        _showSnackBar('Ebook rejected', isError: true);
      }
    } catch (e) {
      _showSnackBar('Failed to reject ebook', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false, bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : (isError ? Icons.error : Icons.info),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? primaryGreen : (isError ? errorRed : darkGreen),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String formatDate(String date) {
    final parsed = DateTime.parse(date);
    return DateFormat('dd MMM yyyy • HH:mm').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGray,
      appBar: _buildModernAppBar(),
      body: isLoading
          ? _buildLoadingState()
          : pendingEbooks.isEmpty
          ? _buildEmptyState()
          : _buildEbooksList(),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: cardWhite,
      foregroundColor: textPrimary,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.eco,
              color: primaryGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Ebook Moderation',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: IconButton(
            onPressed: fetchPendingEbooks,
            icon: const Icon(Icons.refresh_rounded),
            style: IconButton.styleFrom(
              backgroundColor: lightGreen,
              foregroundColor: primaryGreen,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardWhite,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              color: primaryGreen,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Loading ebooks...',
            style: TextStyle(
              fontSize: 16,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: lightGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 64,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'All caught up! 🌱',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No pending ebooks to review',
              style: TextStyle(
                fontSize: 16,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEbooksList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 600;
            final isDesktop = constraints.maxWidth > 900;

            int crossAxisCount = 1;
            if (isDesktop) {
              crossAxisCount = 3;
            } else if (isTablet) {
              crossAxisCount = 2;
            }

            if (isTablet || isDesktop) {
              return GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: pendingEbooks.length,
                itemBuilder: (context, index) => _buildModernEbookCard(
                  pendingEbooks[index],
                  index,
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: pendingEbooks.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildModernEbookCard(pendingEbooks[index], index),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildModernEbookCard(dynamic ebook, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              decoration: BoxDecoration(
                color: cardWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEbookHeader(ebook),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildEbookTitle(ebook),
                            const SizedBox(height: 12),
                            _buildEbookDescription(ebook),
                            const SizedBox(height: 16),
                            Expanded(child: _buildEbookInfo(ebook)),
                            const SizedBox(height: 16),
                            _buildActionButtons(ebook),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEbookHeader(dynamic ebook) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryGreen.withOpacity(0.1),
            accentOrange.withOpacity(0.1),
          ],
        ),
      ),
      child: Stack(
        children: [
          if (ebook['cover_image'] != null)
            Center(
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      getImageUrl(ebook) ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: lightGreen,
                        child: const Icon(
                          Icons.menu_book_rounded,
                          size: 48,
                          color: primaryGreen,
                        ),
                      ),
                    ),

                ),
              ),
            )
          else
            Center(
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  size: 48,
                  color: primaryGreen,
                ),
              ),
            ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: accentOrange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'PENDING',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEbookTitle(dynamic ebook) {
    return Text(
      ebook['title'] ?? 'Untitled',
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        height: 1.3,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildEbookDescription(dynamic ebook) {
    return Text(
      ebook['description'] ?? 'No description available',
      style: const TextStyle(
        fontSize: 14,
        color: textSecondary,
        height: 1.4,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildEbookInfo(dynamic ebook) {
    return Column(
      children: [
        _buildInfoItem(
          Icons.attach_money_rounded,
          'Price',
          '\$${ebook['price']}',
          primaryGreen,
        ),
        _buildInfoItem(
          Icons.person_rounded,
          'Author',
          ebook['User']?['full_name'] ?? 'Unknown',
          darkGreen,
        ),
        _buildInfoItem(
          Icons.category_rounded,
          'Category',
          ebook['EbookCategory']?['name'] ?? 'Uncategorized',
          accentOrange,
        ),
        _buildInfoItem(
          Icons.access_time_rounded,
          'Submitted',
          formatDate(ebook['createdAt']),
          textSecondary,
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(dynamic ebook) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => approveEbook(ebook['id']),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Approve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => rejectEbook(ebook['id']),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Reject'),
            style: ElevatedButton.styleFrom(
              backgroundColor: errorRed,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}