import 'dart:async';
import 'dart:math';
import 'package:agritech/screens/educational%20library/services/api_service.dart';
import 'package:agritech/screens/educational%20library/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'model/ebook_model.dart';
import 'model/video_model.dart';

// Add MenuItem enum
enum MenuItem { dashboard, ebooks, videos, webinars, advisory }

class MarketplaceDashboard extends StatefulWidget {
  final ApiService apiService;
  final bool isMobile;
  final void Function(MenuItem)? onNavigateToSection;

  const MarketplaceDashboard({
    Key? key,
    required this.apiService,
    required this.isMobile,
    this.onNavigateToSection,
  }) : super(key: key);

  @override
  State<MarketplaceDashboard> createState() => _MarketplaceDashboardState();
}

class _MarketplaceDashboardState extends State<MarketplaceDashboard>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String _errorMessage = '';

  // Data lists
  List<Video> _videos = [];
  List<Ebook> _ebooks = [];
  List<dynamic> _webinars = [];

  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadMarketplaceData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadMarketplaceData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Fetch all data in parallel
      final results = await Future.wait([
        widget.apiService.getRandomVideos(),
        widget.apiService.getRandomEbooks(),
        widget.apiService.getRandomWebinars(),
      ]);

      if (mounted) {
        setState(() {
          _videos = results[0] as List<Video>;
          _ebooks = results[1] as List<Ebook>;
          _webinars = results[2] as List<dynamic>;
          _isLoading = false;
        });

        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load marketplace data: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadMarketplaceData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColorss.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMarketplaceHeader(),
              const SizedBox(height: 32),
              _buildVideoSection(),
              const SizedBox(height: 32),
              _buildEbookSection(),
              const SizedBox(height: 32),
              _buildWebinarSection(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColorss.primary,
                  AppColorss.primary.withOpacity(0.6)
                ],
              ),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading Marketplace...',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: AppColorss.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColorss.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColorss.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorss.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketplaceHeader() {
    return Container(
      padding: EdgeInsets.all(widget.isMobile ? 20 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColorss.primary.withOpacity(0.1),
            AppColorss.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColorss.primary.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learning Marketplace',
                  style: GoogleFonts.poppins(
                    fontSize: widget.isMobile ? 24 : 28,
                    fontWeight: FontWeight.w800,
                    color: AppColorss.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Discover educational content, expand your knowledge',
                  style: GoogleFonts.poppins(
                    fontSize: widget.isMobile ? 14 : 16,
                    color: AppColorss.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (!widget.isMobile) ...[
            const SizedBox(width: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColorss.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.storefront_rounded,
                color: AppColorss.primary,
                size: 32,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Videos',
            _videos.length.toString(),
            Icons.play_circle_filled,
            Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Ebooks',
            _ebooks.length.toString(),
            Icons.auto_stories,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Webinars',
            _webinars.length.toString(),
            Icons.video_call,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorss.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            count,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColorss.textPrimary,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColorss.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSection() {
    return _buildMarketplaceSection(
      title: 'Video Courses',
      subtitle: 'Learn through interactive video content',
      items: _videos,
      color: Colors.red,
      icon: Icons.play_circle_filled,
      emptyMessage: 'No videos available at the moment',
      onViewAll: () => _navigateToVideoList(),
    );
  }

  Widget _buildEbookSection() {
    return _buildMarketplaceSection(
      title: 'Digital Ebooks',
      subtitle: 'Comprehensive reading materials',
      items: _ebooks,
      color: Colors.blue,
      icon: Icons.auto_stories,
      emptyMessage: 'No ebooks available at the moment',
      onViewAll: () => _navigateToEbookList(),
    );
  }

  Widget _buildWebinarSection() {
    return _buildMarketplaceSection(
      title: 'Live Webinars',
      subtitle: 'Join interactive learning sessions',
      items: _webinars,
      color: Colors.purple,
      icon: Icons.video_call,
      emptyMessage: 'No upcoming webinars scheduled',
      onViewAll: () => _navigateToWebinarList(),
    );
  }

  Widget _buildMarketplaceSection({
    required String title,
    required String subtitle,
    required List<dynamic> items,
    required Color color,
    required IconData icon,
    required String emptyMessage,
    required VoidCallback onViewAll,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: widget.isMobile ? 18 : 22,
                      fontWeight: FontWeight.w700,
                      color: AppColorss.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColorss.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (items.isNotEmpty)
              TextButton.icon(
                onPressed: onViewAll,
                icon: Icon(Icons.arrow_forward, size: 16, color: color),
                label: Text(
                  'View All',
                  style: GoogleFonts.poppins(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Content area
        if (items.isEmpty)
          _buildEmptySection(emptyMessage, icon, color)
        else
          SizedBox(
            height: widget.isMobile ? 240 : 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(
                    right: 16,
                    left: index == 0 ? 0 : 0,
                  ),
                  child: _buildMarketplaceCard(items[index], color),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEmptySection(String message, IconData icon, Color color) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppColorss.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketplaceCard(dynamic item, Color color) {
    String title = _getItemTitle(item);
    String author = _getItemAuthor(item);
    String description = _getItemDescription(item);
    IconData typeIcon = _getItemIcon(item);
    String duration = _getItemDuration(item);
    String price = _getItemPrice(item);

    return InkWell(
      onTap: () => _onItemTap(item),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: widget.isMobile ? 180 : 220,
        decoration: BoxDecoration(
          color: AppColorss.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with image or gradient background
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Stack(
                  children: [
                    // Background image or gradient
                    Positioned.fill(
                      child: _buildItemImage(item, color),
                    ),

                    // Gradient overlay for better text visibility
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Type icon
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(typeIcon, color: Colors.white, size: 16),
                      ),
                    ),

                    // Duration badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          duration,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    // Center play icon for videos
                    if (item is Video)
                      Center(
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.play_arrow,
                            color: color,
                            size: 28,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Card content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColorss.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      author,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColorss.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        description,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColorss.textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Footer with price only
                    Row(
                      children: [
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            price,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w700,
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

  // Helper method to build item images
  Widget _buildItemImage(dynamic item, Color fallbackColor) {
    String? imageUrl = _getItemImageUrl(item);

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  fallbackColor.withOpacity(0.8),
                  fallbackColor.withOpacity(0.6),
                ],
              ),
            ),
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackImage(item, fallbackColor);
        },
      );
    } else {
      return _buildFallbackImage(item, fallbackColor);
    }
  }

  Widget _buildFallbackImage(dynamic item, Color fallbackColor) {
    IconData icon = _getItemIcon(item);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            fallbackColor.withOpacity(0.8),
            fallbackColor.withOpacity(0.6),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: CustomPaint(
              painter: CardPatternPainter(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          // Center icon
          Center(
            child: Icon(
              icon,
              color: Colors.white.withOpacity(0.7),
              size: 48,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get image URL from different item types
  String? _getItemImageUrl(dynamic item) {
    if (item is Video) {
      // Use the ApiService.getFullUrl method to get proper URL
      return item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty
          ? ApiService.getFullUrl(item.thumbnailUrl)
          : null;
    }
    if (item is Ebook) {
      // Use the ApiService.getFullUrl method to get proper URL
      return item.coverImage != null && item.coverImage!.isNotEmpty
          ? ApiService.getFullUrl(item.coverImage)
          : null;
    }
    // For webinars
    String? imageUrl = item['image_url'];
    if (imageUrl != null && imageUrl.isNotEmpty) {
      // Check if it's already a full URL or needs the base URL
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        return imageUrl;
      } else {
        return ApiService.getFullUrl(imageUrl);
      }
    }
    return null;
  }
  String _getItemTitle(dynamic item) {
    if (item is Video) return item.title;
    if (item is Ebook) return item.title;
    return item['title'] ?? 'Untitled';
  }

  String _getItemAuthor(dynamic item) {
    if (item is Video) return item.categoryName ?? 'AgriTech Expert';
    if (item is Ebook) return item.categoryName ?? 'AgriTech Authors';
    return item['host']?['full_name'] ?? 'Expert Instructor';
  }

  String _getItemDescription(dynamic item) {
    if (item is Video) {
      return item.description ?? 'Educational video content to enhance your learning journey';
    }
    if (item is Ebook) {
      return item.description ?? 'Comprehensive digital book covering essential topics';
    }
    return item['description'] ?? 'Interactive webinar session with expert instructors';
  }

  String _getItemDuration(dynamic item) {
    if (item is Video) {
      Duration? duration = item.duration;
      if (duration != null) {
        int minutes = duration.inMinutes;
        if (minutes > 0) {
          return '${minutes}min';
        }
        return '${duration.inSeconds}sec';
      }
      return '5-15min';
    }
    if (item is Ebook) {
      return '50+ pages';
    }
    return '1-2hrs';
  }

  String _getItemPrice(dynamic item) {
    if (item is Ebook) {
      double price = item.priceAsDouble;
      if (price > 0) {
        return '${price.toStringAsFixed(0)} XAF';
      }
    }
    return 'Free';
  }

  IconData _getItemIcon(dynamic item) {
    if (item is Video) return Icons.play_circle_filled;
    if (item is Ebook) return Icons.auto_stories;
    return Icons.video_call;
  }

  void _onItemTap(dynamic item) {
    String itemType = '';
    String title = _getItemTitle(item);

    if (item is Video) {
      itemType = 'Video';
      // Navigate to video player
    } else if (item is Ebook) {
      itemType = 'Ebook';
      // Navigate to ebook reader
    } else {
      itemType = 'Webinar';
      // Navigate to webinar details
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Opening $itemType: $title',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        backgroundColor: AppColorss.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _navigateToVideoList() {
    if (widget.onNavigateToSection != null) {
      widget.onNavigateToSection!(MenuItem.videos);
    }
  }

  void _navigateToEbookList() {
    if (widget.onNavigateToSection != null) {
      widget.onNavigateToSection!(MenuItem.ebooks);
    }
  }

  void _navigateToWebinarList() {
    if (widget.onNavigateToSection != null) {
      widget.onNavigateToSection!(MenuItem.webinars);
    }
  }
}

// Custom painter for card patterns
class CardPatternPainter extends CustomPainter {
  final Color color;

  CardPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Create subtle geometric patterns
    for (int i = 0; i < 6; i++) {
      final random = Random(i);
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;

      // Draw small circles
      canvas.drawCircle(
        Offset(x, y),
        random.nextDouble() * 15 + 5,
        paint..color = color.withOpacity(0.3),
      );

      // Draw small rectangles
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x + 30, y + 30),
            width: 20,
            height: 15,
          ),
          const Radius.circular(4),
        ),
        paint..color = color.withOpacity(0.2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}