// lib/screens/educational_library_screen.dart
import 'package:agritech/screens/educational%20library/services/api_service.dart';
import 'package:agritech/screens/educational%20library/utils/constants.dart';
import 'package:agritech/screens/educational%20library/widgets/category_dropdown.dart';
import 'package:agritech/screens/educational%20library/widgets/content_grid.dart';
import 'package:agritech/screens/educational%20library/widgets/ebook_viewer_dialog.dart';
import 'package:agritech/screens/educational%20library/widgets/upload_dialog.dart';
import 'package:agritech/screens/educational%20library/widgets/video_player_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../advisory/advisory.dart';
import '../navigation bar/navigation_bar.dart';
import '../webinar/user_webinar_screen.dart';
import 'dashboard_section.dart';
import 'model/category_model.dart';
import 'model/ebook_model.dart';
import 'model/video_model.dart';

enum MenuItem {dashboard, ebooks, videos, webinars, advisory }

class EducationalLibraryScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;

  const EducationalLibraryScreen({
    Key? key,
    required this.userData,
    required this.token,
  }) : super(key: key);

  @override
  State<EducationalLibraryScreen> createState() => _EducationalLibraryScreenState();
}

class _EducationalLibraryScreenState extends State<EducationalLibraryScreen>
    with TickerProviderStateMixin {
  // Controllers and Animation
  late ApiService _apiService;
  late AnimationController _sidebarAnimationController;
  late AnimationController _fadeAnimationController;
  late Animation<double> _sidebarAnimation;
  late Animation<double> _fadeAnimation;

  // Data Lists
  List<Ebook> _ebooks = [];
  List<Video> _videos = [];
  List<Category> _categories = [];

  // State Management
  int _selectedCategoryId = 0;
  bool _isLoading = false;
  bool _isCategoriesLoading = false;
  String? _errorMessage;
  MenuItem _selectedMenuItem =  MenuItem.dashboard;
  bool _isSidebarCollapsed = true; // Always start collapsed
  bool _showCategoriesInSidebar = false;

  // Responsive breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(token: widget.token);

    // Initialize animations
    _sidebarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _sidebarAnimation = CurvedAnimation(
      parent: _sidebarAnimationController,
      curve: Curves.easeInOutCubic,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    );

    _initializeData();
  }

  @override
  void dispose() {
    _sidebarAnimationController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  // Get responsive dimensions
  bool get isMobile => MediaQuery.of(context).size.width < mobileBreakpoint;
  bool get isTablet => MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;
  bool get isDesktop => MediaQuery.of(context).size.width >= desktopBreakpoint;

  double get screenWidth => MediaQuery.of(context).size.width;
  double get screenHeight => MediaQuery.of(context).size.height;

  double get sidebarExpandedWidth {
    if (isMobile) return screenWidth * 0.8;
    if (isTablet) return 280;
    return 320;
  }

  double get sidebarCollapsedWidth {
    if (isMobile) return 0;
    return 72;
  }

  Future<void> _initializeData() async {
    _fadeAnimationController.forward();
    await Future.wait([
      _fetchCategories(),
      _fetchContent(),
    ]);
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isCategoriesLoading = true;
      _errorMessage = null;
    });

    try {
      final categories = await _apiService.getAllCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isCategoriesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCategoriesLoading = false;
          _errorMessage = 'Failed to load categories: ${e.toString()}';
        });
        _showErrorSnackBar('Failed to load categories');
      }
    }
  }

  Future<void> _fetchContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final categoryId = _selectedCategoryId == 0 ? null : _selectedCategoryId;

      final futures = await Future.wait([
        _apiService.getEbooks(categoryId: categoryId, approved: true),
        _apiService.getVideos(categoryId: categoryId),
      ]);

      if (mounted) {
        setState(() {
          _ebooks = futures[0] as List<Ebook>;
          _videos = futures[1] as List<Video>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load content: ${e.toString()}';
        });
        _showErrorSnackBar('Failed to load content');
      }
    }
  }

  Future<void> _onCategoryChanged(int categoryId) async {
    setState(() {
      _selectedCategoryId = categoryId;
    });
    await _fetchContent();
  }

  Future<void> _onRefresh() async {
    await _fetchContent();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarCollapsed = !_isSidebarCollapsed;
    });

    if (_isSidebarCollapsed) {
      _sidebarAnimationController.reverse();
    } else {
      _sidebarAnimationController.forward();
    }
  }

  void _onMenuItemTap(MenuItem menuItem) {
    // Handle navigation for webinars and advisory
    if (menuItem == MenuItem.webinars) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserWebinarScreen(
            userData: widget.userData,
            token: widget.token,
          ),
        ),
      );
      return;
    }

    if (menuItem == MenuItem.advisory) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdvisoryScreen(
            userData: widget.userData,
            token: widget.token,
          ),
        ),
      );
      return;
    }

    // Handle local navigation for ebooks and videos
    setState(() {
      _selectedMenuItem = menuItem;
      _showCategoriesInSidebar = true;
    });

    // Fetch content and close sidebar on mobile
    if (menuItem == MenuItem.ebooks || menuItem == MenuItem.videos) {
      _fetchContent();
      if (isMobile && !_isSidebarCollapsed) {
        _toggleSidebar();
      }
    }
  }

  void _onEbookTap(Ebook ebook) {
    showDialog(
      context: context,
      builder: (context) => EbookViewerDialog(
        ebook: ebook,
        baseUrl: ApiService.baseUrl,
        onPurchase: () => _purchaseEbook(ebook),
      ),
    );
  }

  void _onVideoTap(Video video) {
    showDialog(
      context: context,
      builder: (context) => VideoPlayerDialog(
        video: video,
        baseUrl: ApiService.baseUrl,
      ),
    );
  }

  Future<void> _purchaseEbook(Ebook ebook) async {
    try {
      _showLoadingDialog('Processing purchase...');

      final success = await _apiService.purchaseEbook(ebook.id);

      if (mounted) {
        Navigator.of(context).pop();

        if (success) {
          _showSuccessSnackBar(AppConstants.purchaseSuccess);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showErrorSnackBar('Purchase failed: ${e.toString()}');
      }
    }
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => UploadDialog(
        categories: _categories,
        apiService: _apiService,
        onUploadSuccess: () {
          _showSuccessSnackBar(AppConstants.uploadSuccess);
          _fetchContent();
        },
        onUploadError: (error) {
          _showErrorSnackBar('Upload failed: $error');
        },
      ),
    );
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColorss.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColorss.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(isMobile ? 12 : 16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColorss.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(isMobile ? 12 : 16),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _fetchContent,
        ),
      ),
    );
  }

  String _getSelectedMenuTitle() {
    switch (_selectedMenuItem) {
      case MenuItem.dashboard:
        return 'Dashboard Overview';
      case MenuItem.ebooks:
        return 'Digital Library - Ebooks';
      case MenuItem.videos:
        return 'Video Library';
      case MenuItem.webinars:
        return 'Live Webinars';
      case MenuItem.advisory:
        return 'Expert Advisory';
    }
  }

  IconData _getSelectedMenuIcon() {
    switch (_selectedMenuItem) {
      case MenuItem.dashboard:
        return Icons.dashboard_rounded;
      case MenuItem.ebooks:
        return Icons.auto_stories;
      case MenuItem.videos:
        return Icons.play_circle_filled;
      case MenuItem.webinars:
        return Icons.video_call;
      case MenuItem.advisory:
        return Icons.support_agent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final darkBackgroundColor = Colors.grey[900] ?? Colors.black;
    final primaryColor = AppColorss.primary;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColorss.background,
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // Main Content
                Row(
                  children: [
                    // Sidebar space on desktop/tablet
                    if (!isMobile)
                      AnimatedBuilder(
                        animation: _sidebarAnimation,
                        builder: (context, child) {
                          return SizedBox(
                            width: _isSidebarCollapsed
                                ? sidebarCollapsedWidth
                                : sidebarExpandedWidth * _sidebarAnimation.value +
                                sidebarCollapsedWidth * (1 - _sidebarAnimation.value),
                          );
                        },
                      ),
                    // Main Content Area
                    Expanded(
                      child: Column(
                        children: [
                          _buildMainAppBar(),
                          Expanded(
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildMainContent(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Sidebar Overlay
                _buildSidebar(),

                // Mobile overlay when sidebar is open
                if (isMobile && !_isSidebarCollapsed)
                  GestureDetector(
                    onTap: _toggleSidebar,
                    child: Container(
                      color: Colors.black54,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
              ],
            );
          },
        ),
        bottomNavigationBar: FarmConnectNavBar(
          isDarkMode: isDarkMode,
          darkColor: darkBackgroundColor,
          primaryColor: primaryColor,
          textColor: textColor,
          currentIndex: 3,
          userData: widget.userData,
          token: widget.token,
        ),
        floatingActionButton: (_selectedMenuItem == MenuItem.ebooks ||
            _selectedMenuItem == MenuItem.videos)
            ? _buildFloatingActionButton()
            : null,
      ),
    );
  }

  Widget _buildSidebar() {
    return AnimatedBuilder(
      animation: _sidebarAnimation,
      builder: (context, child) {
        final sidebarWidth = _isSidebarCollapsed
            ? sidebarCollapsedWidth
            : isMobile
            ? sidebarExpandedWidth
            : sidebarExpandedWidth * _sidebarAnimation.value +
            sidebarCollapsedWidth * (1 - _sidebarAnimation.value);

        return Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: Container(
            width: sidebarWidth,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColorss.primary,
                  AppColorss.primary.withOpacity(0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(4, 0),
                ),
              ],
            ),
            child: _isSidebarCollapsed && !isMobile
                ? _buildCollapsedSidebar()
                : _buildExpandedSidebar(),
          ),
        );
      },
    );
  }

  Widget _buildCollapsedSidebar() {
    return Column(
      children: [
        const SizedBox(height: 20),
        // Logo/Icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.school_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 32),

        // Menu Items
        Expanded(
          child: Column(
            children: [
              _buildCollapsedMenuItem(Icons.dashboard_rounded, MenuItem.dashboard),
              const SizedBox(height: 16),
              _buildCollapsedMenuItem(Icons.auto_stories, MenuItem.ebooks),
              const SizedBox(height: 16),
              _buildCollapsedMenuItem(Icons.play_circle_filled, MenuItem.videos),
              const SizedBox(height: 16),
              _buildCollapsedMenuItem(Icons.video_call, MenuItem.webinars),
              const SizedBox(height: 16),
              _buildCollapsedMenuItem(Icons.support_agent, MenuItem.advisory),
            ],
          ),
        ),

        // Expand Button
        Padding(
          padding: const EdgeInsets.all(16),
          child: InkWell(
            onTap: _toggleSidebar,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.chevron_right,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedMenuItem(IconData icon, MenuItem menuItem) {
    final isSelected = _selectedMenuItem == menuItem;
    // Remove this line: _buildCollapsedMenuItem(Icons.dashboard_rounded, MenuItem.dashboard);

    return Tooltip(
      message: _getMenuItemTitle(menuItem),
      preferBelow: false,
      child: InkWell(
        onTap: () => _onMenuItemTap(menuItem),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: Colors.white.withOpacity(0.5))
                : null,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedSidebar() {
    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _toggleSidebar,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isMobile ? Icons.close : Icons.chevron_left,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'AgriTech',
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 20 : 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Educational Library',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Navigation Menu
        Expanded(
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'LIBRARY',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.7),
                      letterSpacing: 1.0,
                    ),
                  ),
                  _buildExpandedMenuItem(
                    Icons.dashboard_rounded,
                    'Dashboard',
                    MenuItem.dashboard,
                    'Overview & insights',
                  ),

                  const SizedBox(height: 12),

                  _buildExpandedMenuItem(
                    Icons.auto_stories,
                    'Ebooks',
                    MenuItem.ebooks,
                    'Discover digital books',
                  ),
                  const SizedBox(height: 6),

                  _buildExpandedMenuItem(
                    Icons.play_circle_filled,
                    'Videos',
                    MenuItem.videos,
                    'Watch educational content',
                  ),
                  const SizedBox(height: 6),

                  _buildExpandedMenuItem(
                    Icons.video_call,
                    'Webinars',
                    MenuItem.webinars,
                    'Join live sessions',
                  ),
                  const SizedBox(height: 6),

                  _buildExpandedMenuItem(
                    Icons.support_agent,
                    'Advisory',
                    MenuItem.advisory,
                    'Get expert advice',
                  ),

                  // Categories Section (shown when menu item is selected)
                  if (_showCategoriesInSidebar &&
                      (_selectedMenuItem == MenuItem.ebooks || _selectedMenuItem == MenuItem.videos))
                    _buildCategoriesSection(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),

        // User Info
        Container(
          margin: EdgeInsets.all(isMobile ? 16 : 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  (widget.userData['name'] ?? 'U')[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.userData['name'] ?? 'User',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      'Premium Member',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedMenuItem(
      IconData icon,
      String title,
      MenuItem menuItem,
      String subtitle,
      ) {
    final isSelected = _selectedMenuItem == menuItem;

    return InkWell(
      onTap: () => _onMenuItemTap(menuItem),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: Colors.white.withOpacity(0.3))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 12,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'CATEGORIES',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.7),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),

          if (_isCategoriesLoading)
            Container(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.3,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCategoryItem('All Categories', 0),
                    ..._categories.map((category) =>
                        _buildCategoryItem(category.name, category.id)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String name, int categoryId) {
    final isSelected = _selectedCategoryId == categoryId;

    return InkWell(
      onTap: () => _onCategoryChanged(categoryId),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.poppins(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withOpacity(0.8),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMenuItemTitle(MenuItem menuItem) {
    switch (menuItem) {
      case MenuItem.dashboard:
        return 'Dashboard';
      case MenuItem.ebooks:
        return 'Ebooks';
      case MenuItem.videos:
        return 'Videos';
      case MenuItem.webinars:
        return 'Webinars';
      case MenuItem.advisory:
        return 'Advisory';
    }
  }


  Widget _buildMainAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: AppColorss.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Menu button for mobile
          if (isMobile) ...[
            InkWell(
              onTap: _toggleSidebar,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColorss.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.menu,
                  color: AppColorss.primary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Title and Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColorss.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getSelectedMenuIcon(),
              color: AppColorss.primary,
              size: isMobile ? 20 : 24,
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getSelectedMenuTitle(),
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 16 : 20,
                    fontWeight: FontWeight.w700,
                    color: AppColorss.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (!isMobile)
                  Text(
                    'Explore our educational resources',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColorss.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
              ],
            ),
          ),

          // Action buttons
          if (!isMobile) ...[
            if (_selectedMenuItem == MenuItem.ebooks || _selectedMenuItem == MenuItem.videos) ...[
              Container(
                decoration: BoxDecoration(
                  color: AppColorss.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  onPressed: _showUploadDialog,
                  icon: Icon(
                    Icons.add,
                    color: AppColorss.primary,
                    size: 20,
                  ),
                  tooltip: 'Upload Content',
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Container(
              decoration: BoxDecoration(
                color: AppColorss.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                onPressed: _onRefresh,
                icon: Icon(
                  Icons.refresh,
                  color: AppColorss.primary,
                  size: 20,
                ),
                tooltip: 'Refresh',
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Simply replace the _buildMainContent method in your existing file with this:

  Widget _buildMainContent() {
    if (_errorMessage != null) {
      return _buildErrorState();
    }

    switch (_selectedMenuItem) {
      case MenuItem.dashboard:
        return Container(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: MarketplaceDashboard(apiService: _apiService, isMobile: isMobile)
        );
      case MenuItem.ebooks:
        return _buildContentWithCategories(
          child: EbookGrid(
            ebooks: _ebooks,
            isLoading: _isLoading,
            onRefresh: _onRefresh,
            onEbookTap: _onEbookTap,
            onPurchase: _purchaseEbook,
          ),
        );
      case MenuItem.videos:
        return _buildContentWithCategories(
          child: VideoGrid(
            videos: _videos,
            isLoading: _isLoading,
            onRefresh: _onRefresh,
            onVideoTap: _onVideoTap,
          ),
        );
      case MenuItem.webinars:
      case MenuItem.advisory:
        return Container(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _selectedMenuItem == MenuItem.webinars
                      ? Icons.video_call
                      : Icons.support_agent,
                  size: 64,
                  color: AppColorss.primary.withOpacity(0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedMenuItem == MenuItem.webinars
                      ? 'Webinars'
                      : 'Advisory Services',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColorss.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedMenuItem == MenuItem.webinars
                      ? 'Navigate to this section from the sidebar'
                      : 'Navigate to this section from the sidebar',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColorss.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      default:
        return Container(
          child: Center(
            child: Text(
              'Select a section from the sidebar',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppColorss.textSecondary,
              ),
            ),
          ),
        );
    }
  }

  Widget _buildContentWithCategories({required Widget child}) {
    return Column(
      children: [
        // Categories dropdown for main content (only on mobile/when sidebar is closed)
        if (isMobile || _isSidebarCollapsed)
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: CategoryDropdown(
              categories: _categories,
              selectedCategoryId: _selectedCategoryId,
              onCategoryChanged: _onCategoryChanged,
              isLoading: _isCategoriesLoading,
            ),
          ),

        Expanded(child: child),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 24 : 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: isMobile ? 100 : 120,
                height: isMobile ? 100 : 120,
                decoration: BoxDecoration(
                  color: AppColorss.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: isMobile ? 48 : 64,
                  color: AppColorss.error,
                ),
              ),
              SizedBox(height: isMobile ? 24 : 32),

              Text(
                'Oops! Something went wrong',
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 18 : 24,
                  fontWeight: FontWeight.w700,
                  color: AppColorss.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _errorMessage ?? 'An unexpected error occurred',
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 14 : 16,
                    color: AppColorss.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              SizedBox(height: isMobile ? 24 : 32),

              ElevatedButton.icon(
                onPressed: _initializeData,
                icon: const Icon(Icons.refresh),
                label: Text(
                  'Try Again',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorss.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 24 : 32,
                    vertical: isMobile ? 12 : 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showUploadDialog,
      backgroundColor: AppColorss.primary,
      foregroundColor: Colors.white,
      elevation: 8,
      icon: const Icon(Icons.add),
      label: Text(
        isMobile ? 'Upload' : 'Upload Content',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}