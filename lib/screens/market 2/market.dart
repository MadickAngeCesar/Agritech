import 'package:agritech/screens/market%202/widget/category_chip.dart';
import 'package:agritech/screens/market%202/widget/empty_state.dart';
import 'package:agritech/screens/market%202/widget/featured_product_card.dart';
import 'package:agritech/screens/market%202/widget/loading_state.dart';
import 'package:agritech/screens/market%202/widget/market_updates_card.dart';
import 'package:agritech/screens/market%202/widget/product_card.dart';
import 'package:agritech/screens/market%202/widget/subcategory_chip.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:card_swiper/card_swiper.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../services/api_service.dart';
import '../market place/cart_screen.dart';
import '../market place/manage_products_screen.dart';
import '../market place/product_detail.dart';
import '../navigation bar/navigation_bar.dart';
import 'market_updates_screen.dart';
import 'constants/theme_constants.dart';

class MarketplaceScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;

  const MarketplaceScreen({
    Key? key,
    required this.userData,
    required this.token, required int categoryId,
  }) : super(key: key);

  @override
  _MarketplaceScreenState createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late ApiService _apiService;
  List<Category> _categories = [];
  List<Product> _products = [];
  List<Product> _featuredProducts = [];
  bool _isLoading = true;
  int? _selectedCategoryId;
  int? _selectedSubCategoryId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  AnimationController? _animationController;
  Animation<double>? _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller first
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeInOut,
      ),
    );

    _animationController!.forward();

    // Initialize API service and load data
    _apiService = ApiService(
      baseUrl: 'http://10.0.2.2:3000',
      token: widget.token,
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await _apiService.getCategories();
      final products = await _apiService.getAllProducts();
      final featuredProducts = await _apiService.getFeaturedProducts();

      setState(() {
        _categories = categories;
        _products = products;
        _featuredProducts = featuredProducts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading marketplace data: $e');
    }
  }

  Future<void> _filterByCategory(int categoryId) async {
    setState(() {
      _isLoading = true;
      _selectedCategoryId = categoryId;
      _selectedSubCategoryId = null;
    });

    try {
      final products = await _apiService.getProductsByCategory(categoryId);
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error filtering by category: $e');
    }
  }

  Future<void> _filterBySubCategory(int subCategoryId) async {
    setState(() {
      _isLoading = true;
      _selectedSubCategoryId = subCategoryId;
    });

    try {
      final products = await _apiService.getProductsBySubCategory(subCategoryId);
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error filtering by subcategory: $e');
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedCategoryId = null;
      _selectedSubCategoryId = null;
      _searchQuery = '';
      _searchController.clear();
    });
    _loadData();
  }

  void _searchProducts(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  List<Product> get _filteredProducts {
    if (_searchQuery.isEmpty) {
      return _products;
    }
    return _products.where((product) =>
    product.name.toLowerCase().contains(_searchQuery) ||
        (product.description ?? '').toLowerCase().contains(_searchQuery)).toList();
  }

  // Navigate to Market Updates Screen
  void _navigateToMarketUpdates() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => MarketUpdatesScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : MarketplaceTheme.darkColor;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final bgPattern = isDarkMode ? 0.03 : 0.02;

    // Get screen size for responsive layout
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;
    final bool isMediumScreen = screenSize.width >= 600 && screenSize.width < 900;
    final bool isLargeScreen = screenSize.width >= 900;

    // Calculate grid columns based on screen width
    int gridColumns = isSmallScreen ? 2 : (isMediumScreen ? 3 : 4);

    // Calculate dynamic paddings
    final horizontalPadding = screenSize.width * (isSmallScreen ? 0.04 : 0.05);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: backgroundColor,
        systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: backgroundColor,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [MarketplaceTheme.primaryColor, MarketplaceTheme.secondaryColor],
              ),
            ),
          ),
          title: Text(
            'AGRO MARKET',
            style: GoogleFonts.montserrat(
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          actions: [
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined, size: 26),
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => CartScreen(
                          userData: widget.userData,
                          token: widget.token,
                        ),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          const begin = Offset(1.0, 0.0);
                          const end = Offset.zero;
                          const curve = Curves.easeInOut;

                          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                          var offsetAnimation = animation.drive(tween);

                          return SlideTransition(position: offsetAnimation, child: child);
                        },
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: MarketplaceTheme.warningColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '', // Replace with actual cart count
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: _isLoading
            ? MarketplaceLoadingState(isDarkMode: isDarkMode)
            : Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            image: DecorationImage(
              image: const AssetImage('assets/subtle_farm_pattern.jpg'),
              opacity: bgPattern,
              repeat: ImageRepeat.repeat,
            ),
          ),
          // Fixed Issue: Check if animation is initialized before using it
          child: _scaleAnimation == null
              ? const Center(child: CircularProgressIndicator())
              : AnimatedBuilder(
            animation: _scaleAnimation!,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation!.value,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // App Bar Space
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 100),
                    ),

                    // Greeting Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: 12,
                        ),

                      ),
                    ),

                    // Featured Products Hero Section - MOVED TO TOP
                    if (_featuredProducts.isNotEmpty && _selectedCategoryId == null && _searchQuery.isEmpty)
                      SliverToBoxAdapter(
                        child: FeaturedProductsCarousel(
                          featuredProducts: _featuredProducts,
                          onProductTap: (product) {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) =>
                                    ProductDetailScreen(
                                      productId: product.id,
                                      userData: widget.userData,
                                      token: widget.token,
                                    ),
                                transitionsBuilder:
                                    (context, animation, secondaryAnimation, child) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                              ),
                            );
                          },
                          primaryColor: MarketplaceTheme.primaryColor,
                          accentColor: MarketplaceTheme.accentColor,
                          warningColor: MarketplaceTheme.warningColor,
                          textColor: textColor,
                          isDarkMode: isDarkMode,
                        ),
                      ),

                    // Market Updates Card - MOVED AFTER HERO
                    SliverToBoxAdapter(
                      child: MarketUpdatesCard(
                        onTap: _navigateToMarketUpdates,
                        isDarkMode: isDarkMode,
                      ),
                    ),

                    // Category Filter with modern design
                    SliverToBoxAdapter(
                      child: Container(
                        height: screenSize.height * 0.06,
                        margin: const EdgeInsets.only(top: 16, bottom: 4),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                          itemCount: _categories.length + 1, // +1 for "All" option
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return CategoryChip(
                                label: 'All Products',
                                isSelected: _selectedCategoryId == null,
                                onSelected: (selected) {
                                  if (selected) {
                                    _resetFilters();
                                  }
                                },
                                isDarkMode: isDarkMode,
                                textColor: textColor,
                              );
                            }

                            final category = _categories[index - 1];
                            return CategoryChip(
                              label: category.name,
                              isSelected: _selectedCategoryId == category.id,
                              onSelected: (selected) {
                                if (selected) {
                                  _filterByCategory(category.id);
                                }
                              },
                              isDarkMode: isDarkMode,
                              textColor: textColor,
                            );
                          },
                        ),
                      ),
                    ),

                    // Subcategory Filter
                    if (_selectedCategoryId != null && _categories.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Container(
                          height: screenSize.height * 0.05,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                            itemCount: _categories
                                .firstWhere(
                                  (cat) => cat.id == _selectedCategoryId,
                              orElse: () => Category(id: 0, name: '', subCategories: []),
                            )
                                .subCategories
                                ?.length ??
                                0,
                            itemBuilder: (context, index) {
                              final selectedCategory = _categories.firstWhere(
                                    (cat) => cat.id == _selectedCategoryId,
                                orElse: () => Category(id: 0, name: '', subCategories: []),
                              );

                              if (selectedCategory.subCategories == null ||
                                  selectedCategory.subCategories!.isEmpty ||
                                  index >= selectedCategory.subCategories!.length) {
                                return const SizedBox.shrink();
                              }

                              final subCategory = selectedCategory.subCategories![index];
                              return SubcategoryChip(
                                label: subCategory.name,
                                isSelected: _selectedSubCategoryId == subCategory.id,
                                onSelected: (selected) {
                                  if (selected) {
                                    _filterBySubCategory(subCategory.id);
                                  }
                                },
                                isDarkMode: isDarkMode,
                                textColor: textColor,
                              );
                            },
                          ),
                        ),
                      ),

                    // Search Bar - MOVED AFTER CATEGORIES
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: 12,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: isDarkMode
                                ? []
                                : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                                spreadRadius: -5,
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: textColor,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search products...',
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 15,
                                color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                                fontWeight: FontWeight.w400,
                              ),
                              filled: true,
                              fillColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: MarketplaceTheme.primaryColor,
                                size: 22,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  color: MarketplaceTheme.primaryColor,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchProducts('');
                                  FocusScope.of(context).unfocus();
                                },
                              )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: MarketplaceTheme.primaryColor,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
                            ),
                            onChanged: _searchProducts,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (value) {
                              _searchProducts(value);
                              FocusScope.of(context).unfocus();
                            },
                          ),
                        ),
                      ),
                    ),

                    // Available Products Section Title
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          16,
                          horizontalPadding,
                          16,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: MarketplaceTheme.primaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.eco_rounded,
                                color: MarketplaceTheme.primaryColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedCategoryId != null || _searchQuery.isNotEmpty
                                  ? 'Results (${_filteredProducts.length})'
                                  : 'Fresh Products',
                              style: GoogleFonts.montserrat(
                                fontSize: isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Product Grid with modern cards
                    _filteredProducts.isEmpty
                        ? SliverFillRemaining(
                      child: MarketplaceEmptyState(
                        isDarkMode: isDarkMode,
                        onResetFilters: _resetFilters,
                      ),
                    )
                        : SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        0,
                        horizontalPadding,
                        screenSize.height * 0.1,
                      ),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: gridColumns,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: screenSize.width * 0.03,
                          mainAxisSpacing: screenSize.width * 0.03,
                        ),
                        delegate: SliverChildBuilderDelegate(
                              (context, index) {
                            final product = _filteredProducts[index];
                            return ProductCard(
                              product: product,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) =>
                                        ProductDetailScreen(
                                          productId: product.id,
                                          userData: widget.userData,
                                          token: widget.token,
                                        ),
                                    transitionsBuilder:
                                        (context, animation, secondaryAnimation, child) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      );
                                    },
                                  ),
                                );
                              },
                              primaryColor: MarketplaceTheme.primaryColor,
                              accentColor: MarketplaceTheme.accentColor,
                              textColor: textColor,
                              cardColor: cardColor,
                              isDarkMode: isDarkMode,
                            );
                          },
                          childCount: _filteredProducts.length,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => AddProductScreen(
                  userData: widget.userData,
                  token: widget.token,
                  categories: _categories,
                  onProductAdded: () {
                    _loadData();
                  },
                ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(0.0, 1.0);
                  const end = Offset.zero;
                  const curve = Curves.easeOutQuint;

                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                  var offsetAnimation = animation.drive(tween);

                  return SlideTransition(position: offsetAnimation, child: child);
                },
              ),
            );
          },
          backgroundColor: MarketplaceTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.add_rounded, size: 28),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: FarmConnectNavBar(
          isDarkMode: isDarkMode,
          darkColor: MarketplaceTheme.darkColor,
          primaryColor: MarketplaceTheme.primaryColor,
          textColor: textColor,
          currentIndex: 1, // Market tab
          userData: widget.userData,
          token: widget.token,
        ),
      ),
    );
  }
}