import 'dart:convert';
import 'dart:math';
import 'package:agritech/screens/market%202/market_updates_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../chat forum/forum.dart';
import '../market 2/market.dart';
import '../navigation bar/navigation_bar.dart';
import '../notifications/notifications.dart';

// Search suggestion model
class SearchSuggestion {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final List<String> keywords;

  SearchSuggestion({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.keywords,
  });
}

// Responsive breakpoints and utilities
class ResponsiveUtils {
  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 600;
  static bool isTablet(BuildContext context) => MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1200;
  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= 1200;
  static bool isLandscape(BuildContext context) => MediaQuery.of(context).orientation == Orientation.landscape;

  static double getScreenWidth(BuildContext context) => MediaQuery.of(context).size.width;
  static double getScreenHeight(BuildContext context) => MediaQuery.of(context).size.height;

  // Responsive padding
  static EdgeInsets getHorizontalPadding(BuildContext context) {
    if (isDesktop(context)) return const EdgeInsets.symmetric(horizontal: 40);
    if (isTablet(context)) return const EdgeInsets.symmetric(horizontal: 32);
    return const EdgeInsets.symmetric(horizontal: 20);
  }

  // Responsive font sizes
  static double getHeaderFontSize(BuildContext context) {
    if (isDesktop(context)) return 28;
    if (isTablet(context)) return 26;
    return 24;
  }

  static double getSubHeaderFontSize(BuildContext context) {
    if (isDesktop(context)) return 20;
    if (isTablet(context)) return 18;
    return 16;
  }

  static double getBodyFontSize(BuildContext context) {
    if (isDesktop(context)) return 16;
    if (isTablet(context)) return 15;
    return 14;
  }

  // Responsive grid columns
  static int getCropGridColumns(BuildContext context) {
    final width = getScreenWidth(context);
    if (width >= 1200) return 6;
    if (width >= 900) return 5;
    if (width >= 600) return 4;
    return 3;
  }

  // Responsive spacing
  static double getSpacing(BuildContext context, {double mobile = 16, double tablet = 20, double desktop = 24}) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }
}

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;

  const HomeScreen({
    Key? key,
    required this.userData,
    required this.token,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _cityName = '...';
  String _searchText = '';
  List<dynamic> _topCrops = [];
  String _weatherSummary = '';
  int _temperature = 0;
  int _humidity = 0;
  String _weatherCondition = '';
  String _marketDemand = '';
  Map<String, dynamic>? _randomVideo;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _weatherKey = GlobalKey();
  final GlobalKey _helpKey = GlobalKey();
  final GlobalKey _cropsKey = GlobalKey();
  final GlobalKey _marketKey = GlobalKey();
  final GlobalKey _videoKey = GlobalKey();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  // Search suggestions state
  List<SearchSuggestion> _searchSuggestions = [];
  List<SearchSuggestion> _filteredSuggestions = [];
  bool _showSuggestions = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  final String _weatherApiKey = 'e1aec962217269cb21622d157c043f5f';

  // Modern Agriculture Color Palette
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color accentGreen = Color(0xFF66BB6A);
  static const Color softGreen = Color(0xFFE8F5E8);
  static const Color earthBrown = Color(0xFF5D4037);
  static const Color warmBeige = Color(0xFFF5F5DC);
  static const Color skyBlue = Color(0xFF81C784);
  static const Color darkGreen = Color(0xFF1B5E20);

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _fetchTopCrops();
    _fetchMarketDemand();
    _fetchRandomVideo();
    _speech = stt.SpeechToText();
    _initializeSearchSuggestions();

    // Listen to search text changes
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _initializeSearchSuggestions() {
    _searchSuggestions = [
      SearchSuggestion(
        title: 'Marketplace',
        subtitle: 'Buy and sell agricultural products',
        icon: Icons.store,
        keywords: [
          'market',
          'marketplace',
          'shop',
          'buy',
          'sell',
          'products',
          'store'
        ],
        onTap: () => _navigateToMarketplace(),
      ),
      SearchSuggestion(
        title: 'Community Forum',
        subtitle: 'Connect with other farmers',
        icon: Icons.forum,
        keywords: [
          'forum',
          'community',
          'farmers',
          'connect',
          'chat',
          'discuss',
          'talk'
        ],
        onTap: () => _navigateToForum(),
      ),
      SearchSuggestion(
        title: 'Today\'s Weather',
        subtitle: 'View current weather conditions',
        icon: Icons.wb_sunny,
        keywords: [
          'weather',
          'temperature',
          'humidity',
          'forecast',
          'climate',
          'rain',
          'sun'
        ],
        onTap: () => _scrollToWeatherSection(),
      ),
      SearchSuggestion(
        title: 'Help & Support',
        subtitle: 'Get assistance with farming questions',
        icon: Icons.help,
        keywords: ['help', 'support', 'assistance', 'guide', 'tutorial', 'faq'],
        onTap: () => _scrollToHelpSection(),
      ),
      SearchSuggestion(
        title: 'Top Crops',
        subtitle: 'Discover popular crops in your area',
        icon: Icons.agriculture,
        keywords: [
          'crops',
          'plants',
          'vegetables',
          'fruits',
          'farming',
          'agriculture',
          'seeds'
        ],
        onTap: () => _scrollToCropsSection(),
      ),
      SearchSuggestion(
        title: 'Market Trends',
        subtitle: 'View current market demands',
        icon: Icons.trending_up,
        keywords: [
          'trends',
          'market trends',
          'demand',
          'prices',
          'economics',
          'analysis'
        ],
        onTap: () => _scrollToMarketDemand(),
      ),
      SearchSuggestion(
        title: 'Learning Videos',
        subtitle: 'Watch educational farming content',
        icon: Icons.play_circle,
        keywords: [
          'videos',
          'learning',
          'education',
          'tutorials',
          'tips',
          'knowledge'
        ],
        onTap: () => _scrollToVideoSection(),
      ),
    ];
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      setState(() {
        _filteredSuggestions = [];
        _showSuggestions = false;
      });
      _removeOverlay();
      return;
    }

    final filtered = _searchSuggestions.where((suggestion) {
      return suggestion.keywords.any((keyword) => keyword.contains(query)) ||
          suggestion.title.toLowerCase().contains(query) ||
          suggestion.subtitle.toLowerCase().contains(query);
    }).toList();

    setState(() {
      _filteredSuggestions = filtered;
      _showSuggestions = filtered.isNotEmpty;
    });

    if (_showSuggestions) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _onSearchFocusChanged() {
    if (!_searchFocusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          setState(() {
            _showSuggestions = false;
          });
          _removeOverlay();
        }
      });
    }
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) =>
          Positioned(
            width: MediaQuery
                .of(context)
                .size
                .width - ResponsiveUtils
                .getHorizontalPadding(context)
                .horizontal,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, ResponsiveUtils.isTablet(context) ? 70 : 65),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: ResponsiveUtils.isDesktop(context) ? 400 : 300,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filteredSuggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _filteredSuggestions[index];
                      return InkWell(
                        onTap: () {
                          suggestion.onTap();
                          _searchController.clear();
                          _searchFocusNode.unfocus();
                          _removeOverlay();
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.getSpacing(context),
                            vertical: ResponsiveUtils.getSpacing(
                                context, mobile: 12, tablet: 14, desktop: 16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(
                                    ResponsiveUtils.getSpacing(
                                        context, mobile: 8,
                                        tablet: 10,
                                        desktop: 12)),
                                decoration: BoxDecoration(
                                  color: primaryGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  suggestion.icon,
                                  color: primaryGreen,
                                  size: ResponsiveUtils.isDesktop(context)
                                      ? 24
                                      : 20,
                                ),
                              ),
                              SizedBox(width: ResponsiveUtils.getSpacing(
                                  context, mobile: 12,
                                  tablet: 14,
                                  desktop: 16)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      suggestion.title,
                                      style: GoogleFonts.poppins(
                                        fontSize: ResponsiveUtils
                                            .getBodyFontSize(context),
                                        fontWeight: FontWeight.w600,
                                        color: darkGreen,
                                      ),
                                    ),
                                    Text(
                                      suggestion.subtitle,
                                      style: GoogleFonts.poppins(
                                        fontSize: ResponsiveUtils
                                            .getBodyFontSize(context) - 2,
                                        color: earthBrown.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: primaryGreen.withOpacity(0.5),
                                size: ResponsiveUtils.isDesktop(context)
                                    ? 18
                                    : 16,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // Navigation methods
  void _navigateToMarketplace() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MarketplaceScreen(
              userData: widget.userData,
              token: widget.token,
              categoryId: 0,
            ),
      ),
    );
  }

  void _navigateToForum() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ForumScreen(
              userData: widget.userData,
              token: widget.token,
            ),
      ),
    );
  }

  // Scroll methods
  void _scrollToWeatherSection() {
    Scrollable.ensureVisible(
      _weatherKey.currentContext!,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToHelpSection() {
    Scrollable.ensureVisible(
      _helpKey.currentContext!,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToCropsSection() {
    Scrollable.ensureVisible(
      _cropsKey.currentContext!,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToMarketDemand() {
    Scrollable.ensureVisible(
      _marketKey.currentContext!,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToVideoSection() {
    if (_videoKey.currentContext != null) {
      Scrollable.ensureVisible(
        _videoKey.currentContext!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) => print('🟡 Status: $val'),
      onError: (val) => print('🔴 Error: $val'),
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) {
          final text = val.recognizedWords;
          setState(() {
            _searchText = text;
            _searchController.text = text;
          });
          _handleVoiceCommand(text.toLowerCase());
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _handleVoiceCommand(String command) {
    command = command.toLowerCase();

    final matchingSuggestion = _searchSuggestions.firstWhere(
          (suggestion) =>
          suggestion.keywords.any((keyword) => command.contains(keyword)),
      orElse: () =>
          SearchSuggestion(
            title: 'No match found',
            subtitle: '',
            icon: Icons.error,
            keywords: [],
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(
                    "⚠️ Sorry, I didn't understand: \"$command\"")),
              );
            },
          ),
    );

    matchingSuggestion.onTap();

    if (matchingSuggestion.title != 'No match found') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Navigating to ${matchingSuggestion.title}"),
          backgroundColor: primaryGreen,
        ),
      );
    }

    _stopListening();
  }

  Future<void> _determinePosition() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    await _fetchWeather(position.latitude, position.longitude);
  }

  Future<void> _fetchWeather(double lat, double lon) async {
    final url = 'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$_weatherApiKey&units=metric';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _cityName = data['name'];
        _temperature = data['main']['temp'].toInt();
        _humidity = data['main']['humidity'];
        _weatherCondition = data['weather'][0]['main'];
        _weatherSummary = _getTipBasedOnWeather(_weatherCondition);
      });
    }
  }

  String _getTipBasedOnWeather(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return 'Perfect for outdoor farming.';
      case 'rain':
      case 'drizzle':
        return 'Let nature irrigate! Avoid pesticides today.';
      case 'thunderstorm':
        return 'Stay indoors. Secure equipment.';
      case 'snow':
        return 'Protect sensitive crops and livestock.';
      case 'clouds':
        return 'Great time for transplanting.';
      default:
        return 'Adjust activities accordingly.';
    }
  }

  Future<void> _fetchTopCrops() async {
    final url = 'http://10.0.2.2:3000/api/categories/top';
    final response = await http.get(
      Uri.parse(url),
      headers: { 'Authorization': 'Bearer ${widget.token}'},
    );
    if (response.statusCode == 200) {
      setState(() => _topCrops = json.decode(response.body));
    }
  }

  Future<void> _fetchMarketDemand() async {
    final url = 'http://10.0.2.2:3000/api/market/demands/today';
    final response = await http.get(
      Uri.parse(url),
      headers: { 'Authorization': 'Bearer ${widget.token}'},
    );
    if (response.statusCode == 200) {
      setState(() =>
      _marketDemand = json.decode(response.body)['message'] ?? '');
    }
  }

  Future<void> _fetchRandomVideo() async {
    final url = 'http://10.0.2.2:3000/api/videos/random';
    final response = await http.get(
      Uri.parse(url),
      headers: { 'Authorization': 'Bearer ${widget.token}'},
    );
    if (response.statusCode == 200) {
      setState(() => _randomVideo = json.decode(response.body));
    }
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'rain':
      case 'drizzle':
        return Icons.grain;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'snow':
        return Icons.ac_unit;
      case 'clouds':
        return Icons.cloud;
      default:
        return Icons.wb_cloudy;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: warmBeige,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _determinePosition();
            await _fetchTopCrops();
            await _fetchMarketDemand();
            await _fetchRandomVideo();
          },
          color: primaryGreen,
          child: ResponsiveUtils.isDesktop(context)
              ? _buildDesktopLayout()
              : _buildMobileTabletLayout(),
        ),
      ),
      bottomNavigationBar: ResponsiveUtils.isDesktop(context)
          ? null
          : FarmConnectNavBar(
        isDarkMode: false,
        darkColor: darkGreen,
        primaryColor: primaryGreen,
        textColor: earthBrown,
        currentIndex: 0,
        userData: widget.userData,
        token: widget.token,
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Sidebar for desktop navigation
        Container(
          width: 280,
          color: Colors.white,
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildDesktopNavigation(),
            ],
          ),
        ),
        // Main content area
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: ResponsiveUtils.getHorizontalPadding(context).copyWith(
                top: 16, bottom: 100),
            children: [
              _buildSearchBar(),
              SizedBox(height: ResponsiveUtils.getSpacing(context)),
              _buildDesktopGrid(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileTabletLayout() {
    return ListView(
      controller: _scrollController,
      padding: ResponsiveUtils.getHorizontalPadding(context).copyWith(
          top: 16, bottom: 100),
      children: [
        _buildHeader(),
        SizedBox(height: ResponsiveUtils.getSpacing(context)),
        _buildSearchBar(),
        SizedBox(height: ResponsiveUtils.getSpacing(context)),
        _buildWeatherSection(),
        SizedBox(height: ResponsiveUtils.getSpacing(context)),
        if (_randomVideo != null) ...[
          _buildVideoSection(),
          SizedBox(height: ResponsiveUtils.getSpacing(context)),
        ],
        _buildMarketDemand(context),
        SizedBox(height: ResponsiveUtils.getSpacing(
            context, mobile: 32, tablet: 36, desktop: 40)),
        _buildTopCropsSection(),
        SizedBox(height: ResponsiveUtils.getSpacing(
            context, mobile: 32, tablet: 36, desktop: 40)),
        _buildCommunitySection(),
        SizedBox(height: ResponsiveUtils.getSpacing(context)),
        _buildHelpSupport(),
      ],
    );
  }

  Widget _buildDesktopGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: ResponsiveUtils.isDesktop(context) ? 2 : 1,
      crossAxisSpacing: 24,
      mainAxisSpacing: 24,
      childAspectRatio: ResponsiveUtils.isDesktop(context) ? 1.5 : 1.0,
      children: [
        _buildWeatherSection(),
        if (_randomVideo != null) _buildVideoSection() else
          _buildCommunitySection(),
        _buildMarketDemand(context),
        _buildTopCropsSection(),
        _buildCommunitySection(),
        _buildHelpSupport(),
      ],
    );
  }

  Widget _buildDesktopNavigation() {
    return Column(
      children: _searchSuggestions.map((suggestion) {
        return ListTile(
          leading: Icon(suggestion.icon, color: primaryGreen),
          title: Text(
            suggestion.title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: darkGreen,
            ),
          ),
          onTap: suggestion.onTap,
        );
      }).toList(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.getSpacing(context),
        horizontal: ResponsiveUtils.isDesktop(context) ? 20 : 0,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(ResponsiveUtils.getSpacing(
                context, mobile: 12, tablet: 14, desktop: 16)),
            decoration: BoxDecoration(
              color: primaryGreen,
              borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getSpacing(context)),
              boxShadow: [
                BoxShadow(
                  color: primaryGreen.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.eco,
              color: Colors.white,
              size: ResponsiveUtils.isDesktop(context) ? 28 : 24,
            ),
          ),
          SizedBox(width: ResponsiveUtils.getSpacing(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back!',
                  style: GoogleFonts.poppins(
                    fontSize: ResponsiveUtils.getHeaderFontSize(context),
                    fontWeight: FontWeight.w600,
                    color: darkGreen,
                  ),
                ),
                Text(
                  'Let\'s grow together today',
                  style: GoogleFonts.poppins(
                    fontSize: ResponsiveUtils.getBodyFontSize(context),
                    color: earthBrown.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NotificationScreen(userId: widget.userData['id'].toString()),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accentGreen, width: 2),
              ),
              child: CircleAvatar(
                radius: ResponsiveUtils.isDesktop(context) ? 26 : 22,
                backgroundColor: softGreen,
                child: Icon(
                  Icons.notifications,
                  color: primaryGreen,
                  size: ResponsiveUtils.isDesktop(context) ? 28 : 24,
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ResponsiveUtils.getSpacing(
              context, mobile: 20, tablet: 22, desktop: 24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: GoogleFonts.poppins(
              fontSize: ResponsiveUtils.getBodyFontSize(context) + 2),
          decoration: InputDecoration(
            hintText: 'Search crops, tips, markets...',
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey[500],
              fontSize: ResponsiveUtils.getBodyFontSize(context) + 2,
            ),
            prefixIcon: Container(
              padding: EdgeInsets.all(ResponsiveUtils.getSpacing(
                  context, mobile: 12, tablet: 14, desktop: 16)),
              child: Icon(
                Icons.search,
                color: primaryGreen,
                size: ResponsiveUtils.isDesktop(context) ? 26 : 24,
              ),
            ),
            suffixIcon: GestureDetector(
              onTap: _isListening ? _stopListening : _startListening,
              child: Container(
                margin: EdgeInsets.all(ResponsiveUtils.getSpacing(
                    context, mobile: 8, tablet: 10, desktop: 12)),
                padding: EdgeInsets.all(ResponsiveUtils.getSpacing(
                    context, mobile: 8, tablet: 10, desktop: 12)),
                decoration: BoxDecoration(
                  color: _isListening ? Colors.red : primaryGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _isListening ? Icons.mic_off : Icons.mic,
                  color: Colors.white,
                  size: ResponsiveUtils.isDesktop(context) ? 22 : 20,
                ),
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ResponsiveUtils.getSpacing(
                  context, mobile: 20, tablet: 22, desktop: 24)),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              vertical: ResponsiveUtils.getSpacing(
                  context, mobile: 16, tablet: 18, desktop: 20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherSection() {
    return Container(
      key: _weatherKey,
      padding: EdgeInsets.all(ResponsiveUtils.getSpacing(
          context, mobile: 24, tablet: 28, desktop: 32)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [lightGreen, accentGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(ResponsiveUtils.getSpacing(
            context, mobile: 24, tablet: 26, desktop: 28)),
        boxShadow: [
          BoxShadow(
            color: lightGreen.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getWeatherIcon(_weatherCondition),
                color: Colors.white,
                size: ResponsiveUtils.isDesktop(context) ? 32 : 28,
              ),
              SizedBox(width: ResponsiveUtils.getSpacing(
                  context, mobile: 12, tablet: 14, desktop: 16)),
              Expanded(
                child: Text(
                  "Today's Weather in $_cityName",
                  style: GoogleFonts.poppins(
                    fontSize: ResponsiveUtils.getSubHeaderFontSize(context),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(
              context, mobile: 20, tablet: 22, desktop: 24)),
          ResponsiveUtils.isDesktop(context) ||
              ResponsiveUtils.isTablet(context)
              ? Row(
            children: [
              Expanded(flex: 2, child: _buildTemperatureInfo()),
              SizedBox(width: ResponsiveUtils.getSpacing(context)),
              Expanded(flex: 1, child: _buildHumidityInfo()),
            ],
          )
              : Column(
            children: [
              _buildTemperatureInfo(),
              SizedBox(height: ResponsiveUtils.getSpacing(context)),
              _buildHumidityInfo(),
            ],
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(context)),
          _buildWeatherTip(),
        ],
      ),
    );
  }

  Widget _buildTemperatureInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$_temperature°C',
          style: GoogleFonts.poppins(
            fontSize: ResponsiveUtils.isDesktop(context) ? 42 : ResponsiveUtils
                .isTablet(context) ? 38 : 36,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          'Feels perfect',
          style: GoogleFonts.poppins(
            fontSize: ResponsiveUtils.getBodyFontSize(context),
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildHumidityInfo() {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(
            ResponsiveUtils.getSpacing(context)),
      ),
      child: ResponsiveUtils.isMobile(context)
          ? Row(
        children: [
          Icon(Icons.water_drop, color: Colors.white, size: 20),
          SizedBox(width: ResponsiveUtils.getSpacing(
              context, mobile: 8, tablet: 10, desktop: 12)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_humidity%',
                style: GoogleFonts.poppins(
                  fontSize: ResponsiveUtils.getBodyFontSize(context) + 2,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                'Humidity',
                style: GoogleFonts.poppins(
                  fontSize: ResponsiveUtils.getBodyFontSize(context) - 2,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      )
          : Column(
        children: [
          Icon(Icons.water_drop, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            '$_humidity%',
            style: GoogleFonts.poppins(
              fontSize: ResponsiveUtils.getBodyFontSize(context) + 2,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Text(
            'Humidity',
            style: GoogleFonts.poppins(
              fontSize: ResponsiveUtils.getBodyFontSize(context) - 2,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherTip() {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(
            ResponsiveUtils.getSpacing(context)),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: Colors.white, size: 20),
          SizedBox(width: ResponsiveUtils.getSpacing(
              context, mobile: 12, tablet: 14, desktop: 16)),
          Expanded(
            child: Text(
              _weatherSummary,
              style: GoogleFonts.poppins(
                fontSize: ResponsiveUtils.getBodyFontSize(context),
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSection() {
    return Container(
      key: _videoKey,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ResponsiveUtils.getSpacing(
            context, mobile: 20, tablet: 22, desktop: 24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Featured Learning',
            style: GoogleFonts.poppins(
              fontSize: ResponsiveUtils.getSubHeaderFontSize(context) + 2,
              fontWeight: FontWeight.w600,
              color: darkGreen,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(
              context, mobile: 12, tablet: 14, desktop: 16)),
          GestureDetector(
            onTap: () {},
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ResponsiveUtils.getSpacing(
                    context, mobile: 20, tablet: 22, desktop: 24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(ResponsiveUtils.getSpacing(
                    context, mobile: 20, tablet: 22, desktop: 24)),
                child: AspectRatio(
                  aspectRatio: ResponsiveUtils.isDesktop(context)
                      ? 16 / 10
                      : 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        _randomVideo!['thumbnail'] ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                              color: softGreen,
                              child: Icon(
                                Icons.agriculture,
                                size: ResponsiveUtils.isDesktop(context)
                                    ? 64
                                    : 48,
                                color: primaryGreen,
                              ),
                            ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.3),
                              Colors.transparent,
                              Colors.black.withOpacity(0.6),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          padding: EdgeInsets.all(ResponsiveUtils.getSpacing(
                              context)),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_arrow,
                            size: ResponsiveUtils.isDesktop(context) ? 40 : 32,
                            color: primaryGreen,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: ResponsiveUtils.getSpacing(context),
                        left: ResponsiveUtils.getSpacing(context),
                        right: ResponsiveUtils.getSpacing(context),
                        child: Text(
                          _randomVideo!['title'] ?? 'Agricultural Tips',
                          style: GoogleFonts.poppins(
                            fontSize: ResponsiveUtils.getBodyFontSize(context) +
                                2,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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

  Widget _buildMarketDemand(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MarketUpdatesScreen(), // pass token if needed
          ),
        );
      },
      borderRadius: BorderRadius.circular(ResponsiveUtils.getSpacing(
          context, mobile: 20, tablet: 22, desktop: 24)),
      child: Container(
        key: _marketKey,
        padding: EdgeInsets.all(ResponsiveUtils.getSpacing(
            context, mobile: 20, tablet: 24, desktop: 28)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryGreen.withOpacity(0.1),
              accentGreen.withOpacity(0.1)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(ResponsiveUtils.getSpacing(
              context, mobile: 20, tablet: 22, desktop: 24)),
          border: Border.all(color: accentGreen.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveUtils.getSpacing(
                  context, mobile: 12, tablet: 14, desktop: 16)),
              decoration: BoxDecoration(
                color: primaryGreen,
                borderRadius: BorderRadius.circular(ResponsiveUtils.getSpacing(
                    context, mobile: 12, tablet: 14, desktop: 16)),
              ),
              child: Icon(
                Icons.trending_up,
                color: Colors.white,
                size: ResponsiveUtils.isDesktop(context) ? 28 : 24,
              ),
            ),
            SizedBox(width: ResponsiveUtils.getSpacing(context)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today\'s Market Trends',
                    style: GoogleFonts.poppins(
                      fontSize: ResponsiveUtils.getBodyFontSize(context) + 2,
                      fontWeight: FontWeight.w600,
                      color: darkGreen,
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveUtils.getSpacing(
                        context, mobile: 4, tablet: 6, desktop: 8),
                  ),
                  Text(
                    _marketDemand.isNotEmpty
                        ? _marketDemand
                        : 'Loading market data...',
                    style: GoogleFonts.poppins(
                      fontSize: ResponsiveUtils.getBodyFontSize(context),
                      color: earthBrown.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: primaryGreen,
              size: ResponsiveUtils.isDesktop(context) ? 18 : 16,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildTopCropsSection() {
    return Container(
      key: _cropsKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Crops',
                style: GoogleFonts.poppins(
                  fontSize: ResponsiveUtils.getSubHeaderFontSize(context) + 2,
                  fontWeight: FontWeight.w600,
                  color: darkGreen,
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            MarketplaceScreen(
                              userData: widget.userData,
                              token: widget.token,
                              categoryId: 0,
                            ),
                      ),
                    ),
                icon: Icon(
                  Icons.arrow_forward,
                  color: primaryGreen,
                  size: ResponsiveUtils.isDesktop(context) ? 18 : 16,
                ),
                label: Text(
                  'View All',
                  style: GoogleFonts.poppins(
                    fontSize: ResponsiveUtils.getBodyFontSize(context),
                    fontWeight: FontWeight.w500,
                    color: primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(context)),
          ResponsiveUtils.isDesktop(context)
              ? _buildCropsGrid()
              : _buildCropsHorizontalList(),
        ],
      ),
    );
  }

  Widget _buildCropsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveUtils.getCropGridColumns(context),
        crossAxisSpacing: ResponsiveUtils.getSpacing(context),
        mainAxisSpacing: ResponsiveUtils.getSpacing(context),
        childAspectRatio: 0.8,
      ),
      itemCount: _topCrops.length,
      itemBuilder: (context, index) => _buildCropItem(_topCrops[index]),
    );
  }

  Widget _buildCropsHorizontalList() {
    return SizedBox(
      height: ResponsiveUtils.isTablet(context) ? 140 : 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _topCrops.length,
        itemBuilder: (context, index) {
          return Container(
            width: ResponsiveUtils.isTablet(context) ? 110 : 90,
            margin: EdgeInsets.only(right: ResponsiveUtils.getSpacing(context)),
            child: _buildCropItem(_topCrops[index]),
          );
        },
      ),
    );
  }

  Widget _buildCropItem(dynamic crop) {
    final cropSize = ResponsiveUtils.isDesktop(context) ? 80.0 : ResponsiveUtils
        .isTablet(context) ? 75.0 : 70.0;

    return Column(
      children: [
        Container(
          width: cropSize,
          height: cropSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: accentGreen.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.network(
              crop['image'] ??
                  'https://via.placeholder.com/100x100.png?text=No+Image',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(
                    color: softGreen,
                    child: Icon(
                      Icons.eco,
                      color: primaryGreen,
                      size: ResponsiveUtils.isDesktop(context) ? 36 : 30,
                    ),
                  ),
            ),
          ),
        ),
        SizedBox(height: ResponsiveUtils.getSpacing(
            context, mobile: 8, tablet: 10, desktop: 12)),
        Text(
          crop['name'] ?? 'Unknown',
          style: GoogleFonts.poppins(
            fontSize: ResponsiveUtils.getBodyFontSize(context) - 2,
            fontWeight: FontWeight.w500,
            color: darkGreen,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildCommunitySection() {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.getSpacing(
          context, mobile: 20, tablet: 24, desktop: 28)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveUtils.getSpacing(
            context, mobile: 20, tablet: 22, desktop: 24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ResponsiveUtils.isMobile(context)
          ? Column(
        children: [
          _buildCommunityIcon(),
          SizedBox(height: ResponsiveUtils.getSpacing(context)),
          _buildCommunityContent(),
          SizedBox(height: ResponsiveUtils.getSpacing(context)),
          _buildCommunityButton(),
        ],
      )
          : Row(
        children: [
          _buildCommunityIcon(),
          SizedBox(width: ResponsiveUtils.getSpacing(context)),
          Expanded(child: _buildCommunityContent()),
          SizedBox(width: ResponsiveUtils.getSpacing(
              context, mobile: 12, tablet: 16, desktop: 20)),
          _buildCommunityButton(),
        ],
      ),
    );
  }

  Widget _buildCommunityIcon() {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context)),
      decoration: BoxDecoration(
        color: skyBlue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(
            ResponsiveUtils.getSpacing(context)),
      ),
      child: Icon(
        Icons.groups,
        color: skyBlue,
        size: ResponsiveUtils.isDesktop(context) ? 32 : 28,
      ),
    );
  }

  Widget _buildCommunityContent() {
    return Column(
      crossAxisAlignment: ResponsiveUtils.isMobile(context) ? CrossAxisAlignment
          .center : CrossAxisAlignment.start,
      children: [
        Text(
          'Community Forum',
          style: GoogleFonts.poppins(
            fontSize: ResponsiveUtils.getSubHeaderFontSize(context),
            fontWeight: FontWeight.w600,
            color: darkGreen,
          ),
          textAlign: ResponsiveUtils.isMobile(context)
              ? TextAlign.center
              : TextAlign.start,
        ),
        SizedBox(height: ResponsiveUtils.getSpacing(
            context, mobile: 4, tablet: 6, desktop: 8)),
        Text(
          'Connect, share, and learn from fellow farmers',
          style: GoogleFonts.poppins(
            fontSize: ResponsiveUtils.getBodyFontSize(context),
            color: earthBrown.withOpacity(0.7),
          ),
          textAlign: ResponsiveUtils.isMobile(context)
              ? TextAlign.center
              : TextAlign.start,
        ),
      ],
    );
  }

  Widget _buildCommunityButton() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: skyBlue, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton(
        onPressed: () =>
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ForumScreen(
                      userData: widget.userData,
                      token: widget.token,
                    ),
              ),
            ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.getSpacing(
                context, mobile: 20, tablet: 24, desktop: 28),
            vertical: ResponsiveUtils.getSpacing(
                context, mobile: 12, tablet: 14, desktop: 16),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          'Join',
          style: GoogleFonts.poppins(
            fontSize: ResponsiveUtils.getBodyFontSize(context),
            fontWeight: FontWeight.w600,
            color: skyBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildHelpSupport() {
    return Container(
      key: _helpKey,
      padding: EdgeInsets.all(ResponsiveUtils.getSpacing(
          context, mobile: 20, tablet: 24, desktop: 28)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveUtils.getSpacing(
            context, mobile: 20, tablet: 22, desktop: 24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ResponsiveUtils.isMobile(context)
          ? Column(
        children: [
          _buildHelpIcon(),
          SizedBox(height: ResponsiveUtils.getSpacing(context)),
          _buildHelpContent(),
          SizedBox(height: ResponsiveUtils.getSpacing(context)),
          _buildHelpButton(),
        ],
      )
          : Row(
        children: [
          _buildHelpIcon(),
          SizedBox(width: ResponsiveUtils.getSpacing(context)),
          Expanded(child: _buildHelpContent()),
          SizedBox(width: ResponsiveUtils.getSpacing(
              context, mobile: 12, tablet: 16, desktop: 20)),
          _buildHelpButton(),
        ],
      ),
    );
  }

  Widget _buildHelpIcon() {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context)),
      decoration: BoxDecoration(
        color: primaryGreen.withOpacity(0.2),
        borderRadius: BorderRadius.circular(
            ResponsiveUtils.getSpacing(context)),
      ),
      child: Icon(
        Icons.support_agent,
        color: primaryGreen,
        size: ResponsiveUtils.isDesktop(context) ? 32 : 28,
      ),
    );
  }

  Widget _buildHelpContent() {
    return Column(
      crossAxisAlignment: ResponsiveUtils.isMobile(context) ? CrossAxisAlignment
          .center : CrossAxisAlignment.start,
      children: [
        Text(
          'Help & Support',
          style: GoogleFonts.poppins(
            fontSize: ResponsiveUtils.getSubHeaderFontSize(context),
            fontWeight: FontWeight.w600,
            color: darkGreen,
          ),
          textAlign: ResponsiveUtils.isMobile(context)
              ? TextAlign.center
              : TextAlign.start,
        ),
        SizedBox(height: ResponsiveUtils.getSpacing(
            context, mobile: 4, tablet: 6, desktop: 8)),
        Text(
          '24/7 assistance for all your farming needs',
          style: GoogleFonts.poppins(
            fontSize: ResponsiveUtils.getBodyFontSize(context),
            color: earthBrown.withOpacity(0.7),
          ),
          textAlign: ResponsiveUtils.isMobile(context)
              ? TextAlign.center
              : TextAlign.start,
        ),
      ],
    );
  }

  Widget _buildHelpButton() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: primaryGreen, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.getSpacing(
                context, mobile: 20, tablet: 24, desktop: 28),
            vertical: ResponsiveUtils.getSpacing(
                context, mobile: 12, tablet: 14, desktop: 16),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          'Visit',
          style: GoogleFonts.poppins(
            fontSize: ResponsiveUtils.getBodyFontSize(context),
            fontWeight: FontWeight.w600,
            color: primaryGreen,
          ),
        ),
      ),
    );
  }
}