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
  MenuItem _selectedMenuItem = MenuItem.dashboard;
  bool _isSidebarCollapsed = true;
  bool _showCategoriesInSidebar = false;

  // Enhanced responsive breakpoints with more granular control
  static const double extraSmallBreakpoint = 360;
  static const double smallMobileBreakpoint = 480;
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 768;
  static const double largeTabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1200;
  static const double largeDesktopBreakpoint = 1440;
  static const double extraLargeDesktopBreakpoint = 1920;

  @override
  @override
  void initState() {
    super.initState();
    _apiService = ApiService(token: widget.token);
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  bool _animationsInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_animationsInitialized) {
      _sidebarAnimationController = AnimationController(
        duration: Duration(milliseconds: _getAnimationDuration()),
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

      _animationsInitialized = true;
      _initializeData();
    }
  }


  @override
  void dispose() {
    _sidebarAnimationController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  // Enhanced device type detection
  bool get isExtraSmall => MediaQuery.of(context).size.width < extraSmallBreakpoint;
  bool get isSmallMobile => MediaQuery.of(context).size.width >= extraSmallBreakpoint &&
      MediaQuery.of(context).size.width < smallMobileBreakpoint;
  bool get isMobile => MediaQuery.of(context).size.width < mobileBreakpoint;
  bool get isTablet => MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < largeTabletBreakpoint;
  bool get isLargeTablet => MediaQuery.of(context).size.width >= tabletBreakpoint &&
      MediaQuery.of(context).size.width < largeTabletBreakpoint;
  bool get isDesktop => MediaQuery.of(context).size.width >= largeTabletBreakpoint &&
      MediaQuery.of(context).size.width < largeDesktopBreakpoint;
  bool get isLargeDesktop => MediaQuery.of(context).size.width >= largeDesktopBreakpoint;
  bool get isExtraLargeDesktop => MediaQuery.of(context).size.width >= extraLargeDesktopBreakpoint;

  // Enhanced responsive getters
  double get screenWidth => MediaQuery.of(context).size.width;
  double get screenHeight => MediaQuery.of(context).size.height;

  // Device pixel ratio for high DPI displays
  double get devicePixelRatio => MediaQuery.of(context).devicePixelRatio;

  // Text scale factor for accessibility
  double get textScaleFactor => MediaQuery.of(context).textScaleFactor;

  // Responsive sidebar dimensions
  double get sidebarExpandedWidth {
    if (isExtraSmall) return screenWidth * 0.85;
    if (isSmallMobile) return screenWidth * 0.82;
    if (isMobile) return screenWidth * 0.8;
    if (isTablet) return 280;
    if (isLargeTablet) return 300;
    if (isDesktop) return 320;
    if (isLargeDesktop) return 340;
    return 360; // Extra large desktop
  }

  double get sidebarCollapsedWidth {
    if (isMobile) return 0;
    if (isTablet) return 64;
    if (isLargeTablet) return 68;
    return 72; // Desktop and larger
  }

  // Responsive padding and margins
  EdgeInsets get mainPadding {
    if (isExtraSmall) return const EdgeInsets.all(12);
    if (isSmallMobile) return const EdgeInsets.all(14);
    if (isMobile) return const EdgeInsets.all(16);
    if (isTablet) return const EdgeInsets.all(20);
    if (isLargeTablet) return const EdgeInsets.all(24);
    if (isDesktop) return const EdgeInsets.all(28);
    return const EdgeInsets.all(32); // Large desktop
  }

  EdgeInsets get sidebarPadding {
    if (isExtraSmall) return const EdgeInsets.all(12);
    if (isSmallMobile) return const EdgeInsets.all(14);
    if (isMobile) return const EdgeInsets.all(16);
    if (isTablet) return const EdgeInsets.all(18);
    return const EdgeInsets.all(20); // Desktop and larger
  }

  // Animation duration based on device performance
  int _getAnimationDuration() {
    if (isExtraSmall || devicePixelRatio > 2.5) return 400; // Slower for low-end devices
    if (isMobile) return 350;
    if (isTablet) return 300;
    return 250; // Faster for desktop
  }

  // Responsive font sizes
  double get headerFontSize {
    if (isExtraSmall) return 18;
    if (isSmallMobile) return 20;
    if (isMobile) return 22;
    if (isTablet) return 24;
    if (isLargeTablet) return 26;
    if (isDesktop) return 28;
    return 30; // Large desktop
  }

  double get titleFontSize {
    if (isExtraSmall) return 14;
    if (isSmallMobile) return 16;
    if (isMobile) return 18;
    if (isTablet) return 20;
    if (isLargeTablet) return 22;
    return 24; // Desktop and larger
  }

  double get bodyFontSize {
    if (isExtraSmall) return 12;
    if (isSmallMobile) return 13;
    if (isMobile) return 14;
    if (isTablet) return 15;
    return 16; // Desktop and larger
  }

  double get captionFontSize {
    if (isExtraSmall) return 10;
    if (isSmallMobile) return 11;
    if (isMobile) return 12;
    return 13; // Tablet and larger
  }

  // Responsive icon sizes
  double get primaryIconSize {
    if (isExtraSmall) return 18;
    if (isSmallMobile) return 20;
    if (isMobile) return 22;
    if (isTablet) return 24;
    return 26; // Desktop and larger
  }

  double get secondaryIconSize {
    if (isExtraSmall) return 14;
    if (isSmallMobile) return 16;
    if (isMobile) return 18;
    return 20; // Tablet and larger
  }

  // Responsive spacing
  double get primarySpacing {
    if (isExtraSmall) return 8;
    if (isSmallMobile) return 10;
    if (isMobile) return 12;
    if (isTablet) return 16;
    return 20; // Desktop and larger
  }

  double get secondarySpacing {
    if (isExtraSmall) return 4;
    if (isSmallMobile) return 6;
    if (isMobile) return 8;
    return 12; // Tablet and larger
  }

  // Responsive button dimensions
  double get buttonHeight {
    if (isExtraSmall) return 36;
    if (isSmallMobile) return 40;
    if (isMobile) return 44;
    if (isTablet) return 48;
    return 52; // Desktop and larger
  }

  double get buttonMinWidth {
    if (isExtraSmall) return 80;
    if (isSmallMobile) return 90;
    if (isMobile) return 100;
    if (isTablet) return 120;
    return 140; // Desktop and larger
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
            SizedBox(
              width: primaryIconSize,
              height: primaryIconSize,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColorss.primary),
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: primarySpacing),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: bodyFontSize,
                ),
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
            Icon(
              Icons.check_circle,
              color: Colors.white,
              size: secondaryIconSize,
            ),
            SizedBox(width: secondarySpacing),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: bodyFontSize,
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
        margin: mainPadding,
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
            Icon(
              Icons.error,
              color: Colors.white,
              size: secondaryIconSize,
            ),
            SizedBox(width: secondarySpacing),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: bodyFontSize,
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
        margin: mainPadding,
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
        return isExtraSmall ? 'Ebooks' : 'Digital Library - Ebooks';
      case MenuItem.videos:
        return isExtraSmall ? 'Videos' : 'Video Library';
      case MenuItem.webinars:
        return isExtraSmall ? 'Webinars' : 'Live Webinars';
      case MenuItem.advisory:
        return isExtraSmall ? 'Advisory' : 'Expert Advisory';
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
                  blurRadius: isDesktop ? 20 : 15,
                  offset: Offset(isDesktop ? 4 : 2, 0),
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
        SizedBox(height: primarySpacing),
        // Logo/Icon
        Container(
          width: primaryIconSize * 1.5,
          height: primaryIconSize * 1.5,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.school_rounded,
            color: Colors.white,
            size: primaryIconSize,
          ),
        ),
        SizedBox(height: primarySpacing * 1.5),

        // Menu Items
        Expanded(
          child: Column(
            children: [
              _buildCollapsedMenuItem(Icons.dashboard_rounded, MenuItem.dashboard),
              SizedBox(height: primarySpacing),
              _buildCollapsedMenuItem(Icons.auto_stories, MenuItem.ebooks),
              SizedBox(height: primarySpacing),
              _buildCollapsedMenuItem(Icons.play_circle_filled, MenuItem.videos),
              SizedBox(height: primarySpacing),
              _buildCollapsedMenuItem(Icons.video_call, MenuItem.webinars),
              SizedBox(height: primarySpacing),
              _buildCollapsedMenuItem(Icons.support_agent, MenuItem.advisory),
            ],
          ),
        ),

        // Expand Button
        Padding(
          padding: sidebarPadding,
          child: InkWell(
            onTap: _toggleSidebar,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: primaryIconSize * 1.5,
              height: primaryIconSize * 1.5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.chevron_right,
                color: Colors.white,
                size: secondaryIconSize,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedMenuItem(IconData icon, MenuItem menuItem) {
    final isSelected = _selectedMenuItem == menuItem;

    return Tooltip(
      message: _getMenuItemTitle(menuItem),
      preferBelow: false,
      child: InkWell(
        onTap: () => _onMenuItemTap(menuItem),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: primaryIconSize * 1.5,
          height: primaryIconSize * 1.5,
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
            size: secondaryIconSize,
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
          padding: sidebarPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: primaryIconSize * 1.5,
                    height: primaryIconSize * 1.5,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: primaryIconSize,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _toggleSidebar,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: EdgeInsets.all(secondarySpacing / 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isMobile ? Icons.close : Icons.chevron_left,
                        color: Colors.white,
                        size: secondaryIconSize,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: secondarySpacing),
              Text(
                'AgriTech',
                style: GoogleFonts.poppins(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Educational Library',
                style: GoogleFonts.poppins(
                  fontSize: captionFontSize,
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
              padding: EdgeInsets.symmetric(horizontal: sidebarPadding.left),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'LIBRARY',
                    style: GoogleFonts.poppins(
                      fontSize: captionFontSize - 1,
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

                  SizedBox(height: secondarySpacing),

                  _buildExpandedMenuItem(
                    Icons.auto_stories,
                    'Ebooks',
                    MenuItem.ebooks,
                    'Discover digital books',
                  ),
                  SizedBox(height: secondarySpacing / 2),

                  _buildExpandedMenuItem(
                    Icons.play_circle_filled,
                    'Videos',
                    MenuItem.videos,
                    'Watch educational content',
                  ),
                  SizedBox(height: secondarySpacing / 2),

                  _buildExpandedMenuItem(
                    Icons.video_call,
                    'Webinars',
                    MenuItem.webinars,
                    'Join live sessions',
                  ),
                  SizedBox(height: secondarySpacing / 2),

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

                  SizedBox(height: primarySpacing),
                ],
              ),
            ),
          ),
        ),

        // User Info
        Container(
          margin: EdgeInsets.all(sidebarPadding.left),
          padding: EdgeInsets.all(secondarySpacing),
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
                radius: primaryIconSize * 0.7,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  (widget.userData['name'] ?? 'U')[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: captionFontSize,
                  ),
                ),
              ),
              SizedBox(width: secondarySpacing),
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
                        fontSize: captionFontSize,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      'Premium Member',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: captionFontSize - 1,
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
        padding: EdgeInsets.all(secondarySpacing),
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
              width: primaryIconSize * 1.2,
              height: primaryIconSize * 1.2,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: secondaryIconSize,
              ),
            ),
            SizedBox(width: secondarySpacing),
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
                      fontSize: bodyFontSize,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (!isExtraSmall)
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: captionFontSize,
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
                size: captionFontSize,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Container(
      margin: EdgeInsets.only(top: primarySpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'CATEGORIES',
            style: GoogleFonts.poppins(
              fontSize: captionFontSize - 1,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.7),
              letterSpacing: 1.0,
            ),
          ),
          SizedBox(height: secondarySpacing),

          if (_isCategoriesLoading)
            Container(
              padding: EdgeInsets.all(secondarySpacing),
              child: Center(
                child: SizedBox(
                  width: secondaryIconSize,
                  height: secondaryIconSize,
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
                maxHeight: MediaQuery.of(context).size.height * (isExtraSmall ? 0.25 : 0.3),
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
        padding: EdgeInsets.symmetric(
          horizontal: secondarySpacing,
          vertical: secondarySpacing / 2,
        ),
        margin: EdgeInsets.only(bottom: secondarySpacing / 4),
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
            SizedBox(width: secondarySpacing),
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.poppins(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withOpacity(0.8),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: captionFontSize,
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
        horizontal: mainPadding.left,
        vertical: primarySpacing,
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
                padding: EdgeInsets.all(secondarySpacing),
                decoration: BoxDecoration(
                  color: AppColorss.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.menu,
                  color: AppColorss.primary,
                  size: secondaryIconSize,
                ),
              ),
            ),
            SizedBox(width: secondarySpacing),
          ],

          // Title and Icon
          Container(
            padding: EdgeInsets.all(secondarySpacing),
            decoration: BoxDecoration(
              color: AppColorss.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getSelectedMenuIcon(),
              color: AppColorss.primary,
              size: primaryIconSize,
            ),
          ),
          SizedBox(width: secondarySpacing),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getSelectedMenuTitle(),
                  style: GoogleFonts.poppins(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w700,
                    color: AppColorss.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (!isMobile && !isExtraSmall)
                  Text(
                    'Explore our educational resources',
                    style: GoogleFonts.poppins(
                      fontSize: captionFontSize,
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
                    size: secondaryIconSize,
                  ),
                  tooltip: 'Upload Content',
                  constraints: BoxConstraints(
                    minWidth: buttonHeight * 0.7,
                    minHeight: buttonHeight * 0.7,
                  ),
                ),
              ),
              SizedBox(width: secondarySpacing / 2),
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
                  size: secondaryIconSize,
                ),
                tooltip: 'Refresh',
                constraints: BoxConstraints(
                  minWidth: buttonHeight * 0.7,
                  minHeight: buttonHeight * 0.7,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_errorMessage != null) {
      return _buildErrorState();
    }

    switch (_selectedMenuItem) {
      case MenuItem.dashboard:
        return Container(
          padding: mainPadding,
          child: MarketplaceDashboard(
            apiService: _apiService,
            isMobile: isMobile,
          ),
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
            child: Padding(
              padding: mainPadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _selectedMenuItem == MenuItem.webinars
                        ? Icons.video_call
                        : Icons.support_agent,
                    size: primaryIconSize * 2.5,
                    color: AppColorss.primary.withOpacity(0.6),
                  ),
                  SizedBox(height: primarySpacing),
                  Text(
                    _selectedMenuItem == MenuItem.webinars
                        ? 'Webinars'
                        : 'Advisory Services',
                    style: GoogleFonts.poppins(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w600,
                      color: AppColorss.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: secondarySpacing),
                  Text(
                    _selectedMenuItem == MenuItem.webinars
                        ? 'Navigate to this section from the sidebar'
                        : 'Navigate to this section from the sidebar',
                    style: GoogleFonts.poppins(
                      fontSize: bodyFontSize,
                      color: AppColorss.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      default:
        return Container(
          child: Center(
            child: Padding(
              padding: mainPadding,
              child: Text(
                'Select a section from the sidebar',
                style: GoogleFonts.poppins(
                  fontSize: bodyFontSize,
                  color: AppColorss.textSecondary,
                ),
                textAlign: TextAlign.center,
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
            padding: mainPadding,
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
        padding: mainPadding,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: primaryIconSize * (isExtraSmall ? 3 : 4),
                height: primaryIconSize * (isExtraSmall ? 3 : 4),
                decoration: BoxDecoration(
                  color: AppColorss.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: primaryIconSize * (isExtraSmall ? 1.5 : 2),
                  color: AppColorss.error,
                ),
              ),
              SizedBox(height: primarySpacing * (isExtraSmall ? 1 : 1.5)),

              Text(
                'Oops! Something went wrong',
                style: GoogleFonts.poppins(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w700,
                  color: AppColorss.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: secondarySpacing),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: primarySpacing),
                child: Text(
                  _errorMessage ?? 'An unexpected error occurred',
                  style: GoogleFonts.poppins(
                    fontSize: bodyFontSize,
                    color: AppColorss.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: isExtraSmall ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              SizedBox(height: primarySpacing * (isExtraSmall ? 1 : 1.5)),

              ElevatedButton.icon(
                onPressed: _initializeData,
                icon: Icon(
                  Icons.refresh,
                  size: secondaryIconSize,
                ),
                label: Text(
                  'Try Again',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: bodyFontSize,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorss.primary,
                  foregroundColor: Colors.white,
                  minimumSize: Size(buttonMinWidth, buttonHeight),
                  padding: EdgeInsets.symmetric(
                    horizontal: primarySpacing,
                    vertical: secondarySpacing,
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
    if (isExtraSmall) {
      // Compact FAB for extra small screens
      return FloatingActionButton(
        onPressed: _showUploadDialog,
        backgroundColor: AppColorss.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        child: Icon(
          Icons.add,
          size: primaryIconSize,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      );
    }

    return FloatingActionButton.extended(
      onPressed: _showUploadDialog,
      backgroundColor: AppColorss.primary,
      foregroundColor: Colors.white,
      elevation: 8,
      icon: Icon(
        Icons.add,
        size: secondaryIconSize,
      ),
      label: Text(
        isMobile ? 'Upload' : 'Upload Content',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: bodyFontSize,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}