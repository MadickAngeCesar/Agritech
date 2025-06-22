import 'dart:async';
import 'dart:math';
import 'package:agritech/screens/educational%20library/services/api_service.dart';
import 'package:agritech/screens/educational%20library/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'model/ebook_model.dart';
import 'model/video_model.dart';

class DashboardSection extends StatefulWidget {
  final ApiService apiService;
  final bool isMobile;

  const DashboardSection({
    Key? key,
    required this.apiService,
    required this.isMobile,
  }) : super(key: key);

  @override
  State<DashboardSection> createState() => _DashboardSectionState();
}

class _DashboardSectionState extends State<DashboardSection>
    with TickerProviderStateMixin {
  Timer? _rotationTimer;
  PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isLoading = true;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Data lists
  List<dynamic> _heroItems = [];
  List<Video> _randomVideos = [];
  List<Ebook> _randomEbooks = [];
  List<dynamic> _randomWebinars = [];

  // Statistics
  Map<String, int> _stats = {
    'totalEbooks': 0,
    'totalVideos': 0,
    'totalWebinars': 0,
    'totalUsers': 0,
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchDashboardData();
    _startRotationTimer();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _startRotationTimer() {
    _rotationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_heroItems.isNotEmpty && mounted) {
        _nextHeroItem();
      }
    });
  }

  void _nextHeroItem() {
    if (_heroItems.isEmpty) return;

    setState(() {
      _currentIndex = (_currentIndex + 1) % _heroItems.length;
    });

    if (_pageController.hasClients) {
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _fetchDashboardData() async {
    try {
      setState(() => _isLoading = true);

      // Fetch all random data in parallel
      final results = await Future.wait([
        widget.apiService.getRandomVideos(),
        widget.apiService.getRandomEbooks(),
        widget.apiService.getRandomWebinars(),
      ]);

      if (mounted) {
        setState(() {
          _randomVideos = results[0] as List<Video>;
          _randomEbooks = results[1] as List<Ebook>;
          _randomWebinars = results[2] as List<dynamic>;

          // Combine all items for hero rotation
          _heroItems = [
            ..._randomVideos.take(3),
            ..._randomEbooks.take(3),
            ..._randomWebinars.take(2),
          ];

          // Update stats (mock data - replace with actual API calls)
          _stats = {
            'totalEbooks': _randomEbooks.length * 4, // Simulated total
            'totalVideos': _randomVideos.length * 3,
            'totalWebinars': _randomWebinars.length * 5,
            'totalUsers': 1247, // Replace with actual user count
          };

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        print('Error fetching dashboard data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDashboardHeader(),
            const SizedBox(height: 24),
            _buildStatsCards(),
            const SizedBox(height: 32),
            _buildHeroSection(),
            const SizedBox(height: 32),
            _buildQuickAccessSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColorss.primary, AppColorss.primary.withOpacity(0.6)],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading Dashboard...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppColorss.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardHeader() {
    return Container(
      padding: EdgeInsets.all(widget.isMobile ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColorss.primary.withOpacity(0.1),
            AppColorss.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColorss.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: widget.isMobile ? 50 : 60,
            height: widget.isMobile ? 50 : 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColorss.primary, AppColorss.primary.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColorss.primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.dashboard_rounded,
              color: Colors.white,
              size: widget.isMobile ? 24 : 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard Overview',
                  style: GoogleFonts.poppins(
                    fontSize: widget.isMobile ? 18 : 22,
                    fontWeight: FontWeight.w700,
                    color: AppColorss.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your learning hub at a glance',
                  style: GoogleFonts.poppins(
                    fontSize: widget.isMobile ? 12 : 14,
                    color: AppColorss.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _fetchDashboardData,
            icon: Icon(
              Icons.refresh_rounded,
              color: AppColorss.primary,
            ),
            tooltip: 'Refresh Dashboard',
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final stats = [
      {'icon': Icons.auto_stories, 'label': 'Ebooks', 'value': _stats['totalEbooks']!, 'color': Colors.blue},
      {'icon': Icons.play_circle_filled, 'label': 'Videos', 'value': _stats['totalVideos']!, 'color': Colors.red},
      {'icon': Icons.video_call, 'label': 'Webinars', 'value': _stats['totalWebinars']!, 'color': Colors.purple},
      {'icon': Icons.people, 'label': 'Users', 'value': _stats['totalUsers']!, 'color': Colors.green},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.isMobile ? 2 : 4,
        childAspectRatio: widget.isMobile ? 1.2 : 1.1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return _buildStatCard(
          icon: stat['icon'] as IconData,
          label: stat['label'] as String,
          value: stat['value'] as int,
          color: stat['color'] as Color,
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorss.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value.toString(),
            style: GoogleFonts.poppins(
              fontSize: widget.isMobile ? 18 : 20,
              fontWeight: FontWeight.w700,
              color: AppColorss.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
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

  Widget _buildHeroSection() {
    if (_heroItems.isEmpty) {
      return _buildEmptyHeroSection();
    }

    return Container(
      height: widget.isMobile ? 200 : 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: _heroItems.length,
              itemBuilder: (context, index) {
                return _buildHeroItem(_heroItems[index]);
              },
            ),

            // Gradient overlay
            Positioned.fill(
              child: Container(
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

            // Page indicators
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _heroItems.length,
                      (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
            ),

            // Auto-rotation indicator
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Auto',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildHeroItem(dynamic item) {
    String title = '';
    String subtitle = '';
    String imageUrl = '';
    IconData typeIcon = Icons.info;
    Color typeColor = AppColorss.primary;

    if (item is Video) {
      title = item.title;
      subtitle = 'Educational Video';
      imageUrl = item.thumbnailUrl ?? '';
      typeIcon = Icons.play_circle_filled;
      typeColor = Colors.red;
    } else if (item is Ebook) {
      title = item.title;
      subtitle = 'Digital Book';
      imageUrl = item.coverImage ?? '';
      typeIcon = Icons.auto_stories;
      typeColor = Colors.blue;
    } else {
      title = item['title'] ?? 'Webinar';
      subtitle = 'Live Session';
      imageUrl = item['imageUrl'] ?? '';
      typeIcon = Icons.video_call;
      typeColor = Colors.purple;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            typeColor.withOpacity(0.8),
            typeColor.withOpacity(0.6),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: CustomPaint(
              painter: HeroPatterPainter(color: Colors.white.withOpacity(0.1)),
            ),
          ),

          // Content
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(typeIcon, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: widget.isMobile ? 18 : 24,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHeroSection() {
    return Container(
      height: widget.isMobile ? 200 : 300,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColorss.primary.withOpacity(0.1), AppColorss.primary.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColorss.primary.withOpacity(0.2)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore,
              size: 48,
              color: AppColorss.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'No featured content available',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppColorss.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessSection() {
    final quickActions = [
      {'icon': Icons.auto_stories, 'label': 'Browse Ebooks', 'color': Colors.blue},
      {'icon': Icons.play_circle_filled, 'label': 'Watch Videos', 'color': Colors.red},
      {'icon': Icons.video_call, 'label': 'Join Webinars', 'color': Colors.purple},
      {'icon': Icons.support_agent, 'label': 'Get Advisory', 'color': Colors.green},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Access',
          style: GoogleFonts.poppins(
            fontSize: widget.isMobile ? 16 : 18,
            fontWeight: FontWeight.w700,
            color: AppColorss.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.isMobile ? 2 : 4,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: quickActions.length,
          itemBuilder: (context, index) {
            final action = quickActions[index];
            return _buildQuickActionCard(
              icon: action['icon'] as IconData,
              label: action['label'] as String,
              color: action['color'] as Color,
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return InkWell(
      onTap: () {
        // Handle quick action tap
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColorss.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColorss.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for hero section background pattern
class HeroPatterPainter extends CustomPainter {
  final Color color;

  HeroPatterPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    // Create flowing wave pattern
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.25, size.height * 0.1,
      size.width * 0.5, size.height * 0.2,
    );
    path.quadraticBezierTo(
      size.width * 0.75, size.height * 0.3,
      size.width, size.height * 0.1,
    );
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);

    // Add some floating circles
    for (int i = 0; i < 5; i++) {
      final random = Random(i);
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 20 + 10;

      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint..color = color.withOpacity(0.1),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}