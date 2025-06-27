import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class MarketUpdatesScreen extends StatefulWidget {
  @override
  State<MarketUpdatesScreen> createState() => _MarketUpdatesScreenState();
}

class _MarketUpdatesScreenState extends State<MarketUpdatesScreen>
    with TickerProviderStateMixin {
  // AgriTech color scheme
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF66BB6A);
  static const Color accentGreen = Color(0xFFE8F5E8);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color backgroundColor = Color(0xFFF8FDF8);
  static const Color cardColor = Colors.white;

  // Loading states
  bool isLoadingCategories = true;
  bool isLoadingChart = false;
  bool isLoadingMarketData = true;

  // Market data
  List<dynamic> categories = [];
  List<dynamic> topProducts = [];
  List<dynamic> topSellers = [];
  String errorMessage = '';

  // Chart data
  String? selectedCategoryId;
  DateTime? selectedFrom;
  DateTime? selectedTo;
  List<String> chartDates = [];
  List<double> chartPrices = [];

  // Animation
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Initialize data
    fetchCategories();
    fetchMarketUpdates();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // API calls
  Future<void> fetchCategories() async {
    try {
      setState(() {
        isLoadingCategories = true;
      });

      final res = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/categories'),
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          categories = data;
          isLoadingCategories = false;
        });
      } else {
        setState(() {
          isLoadingCategories = false;
        });
        print('Failed to load categories');
      }
    } catch (e) {
      setState(() {
        isLoadingCategories = false;
      });
      print('Error loading categories: $e');
    }
  }

  Future<void> fetchChartData() async {
    if (selectedCategoryId == null || selectedFrom == null || selectedTo == null) {
      return;
    }

    setState(() {
      isLoadingChart = true;
    });

    final fromStr = DateFormat('yyyy-MM-dd').format(selectedFrom!);
    final toStr = DateFormat('yyyy-MM-dd').format(selectedTo!);

    try {
      final res = await http.get(
        Uri.parse(
          'http://10.0.2.2:3000/api/market/category-trend?category_id=$selectedCategoryId&from=$fromStr&to=$toStr',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          chartDates = List<String>.from(data['dates']);
          chartPrices = List<double>.from(
            data['avg_prices'].map((e) => (e as num).toDouble()),
          );
          isLoadingChart = false;
        });
      } else {
        setState(() {
          isLoadingChart = false;
        });
        print('Failed to load chart data');
      }
    } catch (e) {
      setState(() {
        isLoadingChart = false;
      });
      print('Error loading chart data: $e');
    }
  }

  Future<void> fetchMarketUpdates() async {
    const baseUrl = 'http://10.0.2.2:3000/api/market';

    try {
      setState(() {
        isLoadingMarketData = true;
        errorMessage = '';
      });

      final productResponse = await http.get(
        Uri.parse('$baseUrl/top-products'),
        headers: {'Content-Type': 'application/json'},
      );

      final sellerResponse = await http.get(
        Uri.parse('$baseUrl/top-sellers'),
        headers: {'Content-Type': 'application/json'},
      );

      if (productResponse.statusCode == 200 && sellerResponse.statusCode == 200) {
        setState(() {
          topProducts = json.decode(productResponse.body);
          topSellers = json.decode(sellerResponse.body);
          isLoadingMarketData = false;
        });
        _animationController.forward();
      } else {
        setState(() {
          errorMessage = 'Unable to load market data. Please check your connection and try again.';
          isLoadingMarketData = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error. Please check your internet connection.';
        isLoadingMarketData = false;
      });
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([
      fetchCategories(),
      fetchMarketUpdates(),
    ]);
  }

  // Date picker
  Future<void> _pickDate(BuildContext context, bool isFrom) async {
    final initialDate = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          selectedFrom = picked;
        } else {
          selectedTo = picked;
        }
      });
    }
  }

  // UI Components
  Widget _buildAnimatedContainer({
    required Widget child,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 500 + (delay * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, _) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
    );
  }

  Widget _buildMarketInsightCard() {
    return _buildAnimatedContainer(
      delay: 0,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryGreen, lightGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryGreen.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    "Market Intelligence Hub",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "Comprehensive market insights combining real-time trends, top performers, and price analytics to help you make informed agricultural business decisions.",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
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
                      Icon(
                        Icons.access_time,
                        color: Colors.white.withOpacity(0.8),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Live Data",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.analytics,
                        color: Colors.white.withOpacity(0.8),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Analytics",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
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
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Market Trends Tab Components
  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Price Trend Analysis",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: darkGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Analyze price trends for specific product categories over time",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          _buildCategoryDropdown(),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildDateSelector("From Date", selectedFrom, true),
              const SizedBox(width: 12),
              _buildDateSelector("To Date", selectedTo, false),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: (selectedCategoryId != null &&
                  selectedFrom != null &&
                  selectedTo != null) ? fetchChartData : null,
              icon: Icon(Icons.show_chart),
              label: Text(
                "Generate Trend Chart",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildChart(),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    if (isLoadingCategories) {
      return Container(
        height: 60,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: CircularProgressIndicator(color: primaryGreen, strokeWidth: 2),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: selectedCategoryId,
        decoration: InputDecoration(
          labelText: "Select Product Category",
          prefixIcon: Icon(Icons.category, color: primaryGreen),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: cardColor,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: categories.map<DropdownMenuItem<String>>((cat) {
          return DropdownMenuItem<String>(
            value: cat['id'].toString(),
            child: Text(
              cat['name'],
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            selectedCategoryId = value;
          });
        },
      ),
    );
  }

  Widget _buildDateSelector(String label, DateTime? selected, bool isFrom) {
    return Expanded(
      child: InkWell(
        onTap: () => _pickDate(context, isFrom),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: 18, color: primaryGreen),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      selected != null
                          ? DateFormat('MMM dd, yyyy').format(selected)
                          : 'Select date',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: selected != null ? Colors.grey[800] : Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChart() {
    if (isLoadingChart) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: primaryGreen),
              SizedBox(height: 16),
              Text(
                "Generating trend analysis...",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (chartDates.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, size: 64, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                "No trend data available",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Select a category and date range to view price trends",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: primaryGreen, size: 24),
              SizedBox(width: 8),
              Text(
                "Price Trend Analysis",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkGreen,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            "Average prices over selected period",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 1.6,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: chartPrices.isNotEmpty
                      ? (chartPrices.reduce((a, b) => a > b ? a : b) / 5)
                      : 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < chartDates.length) {
                          return Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('MM/dd').format(DateTime.parse(chartDates[index])),
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade600,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          'XAF ${value.toInt()}',
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade600,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(chartPrices.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: chartPrices[i],
                        width: 16,
                        color: primaryGreen,
                        borderRadius: BorderRadius.circular(4),
                      )
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Market Overview Tab Components
  Widget _buildOverviewTab() {
    if (isLoadingMarketData) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return _buildErrorState();
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Row
          _buildAnimatedContainer(
            delay: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildStatsCard(
                    "Trending Products",
                    "${topProducts.length}",
                    Icons.inventory,
                    primaryGreen,
                  ),
                  const SizedBox(width: 12),
                  _buildStatsCard(
                    "Top Sellers",
                    "${topSellers.length}",
                    Icons.people,
                    lightGreen,
                  ),
                  const SizedBox(width: 12),
                  _buildStatsCard(
                    "Categories",
                    "${categories.length}",
                    Icons.category,
                    Colors.orange,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Top Products Section
          _buildTopProducts(),

          const SizedBox(height: 32),

          // Top Sellers Section
          _buildTopSellers(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTopProducts() {
    return _buildAnimatedContainer(
      delay: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Trending Products',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: darkGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Most popular products in the marketplace right now',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (topProducts.isEmpty)
            _buildEmptyState(
              icon: Icons.shopping_cart_outlined,
              title: "No trending products yet",
              subtitle: "Be the first to list your products!",
            )
          else
            ...topProducts.asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;
              final p = product['Product'];
              return _buildProductCard(p, index);
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: accentGreen,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: product['images'] != null && product['images'].isNotEmpty
                    ? Image.network(
                  product['images'][0],
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.image_not_supported, color: Colors.grey[400]),
                )
                    : Icon(Icons.agriculture, color: primaryGreen, size: 28),
              ),
            ),
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#${index + 1}',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          product['name'] ?? 'Unnamed Product',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  product['market_region'] ?? 'Unknown Region',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'XAF ${product['price'] ?? '0'}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: primaryGreen,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopSellers() {
    return _buildAnimatedContainer(
      delay: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.people, color: primaryGreen, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Top Performers',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: darkGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Connect with the most successful sellers in your region',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (topSellers.isEmpty)
            _buildEmptyState(
              icon: Icons.person_outline,
              title: "No top sellers yet",
              subtitle: "Start selling to appear in this list!",
            )
          else
            ...topSellers.asMap().entries.map((entry) {
              final index = entry.key;
              final seller = entry.value;
              final u = seller['User'];
              return _buildSellerCard(u, index);
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildSellerCard(Map<String, dynamic> user, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: accentGreen,
              backgroundImage: user['profile_image'] != null && user['profile_image'].isNotEmpty
                  ? NetworkImage(user['profile_image'])
                  : null,
              child: user['profile_image'] == null || user['profile_image'].isEmpty
                  ? Icon(Icons.person, color: primaryGreen, size: 28)
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: index < 3 ? Colors.amber : primaryGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#${index + 1}',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          user['full_name'] ?? 'Anonymous Seller',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.email, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    user['email'] ?? 'No email provided',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.star,
            color: primaryGreen,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "Unable to load market data",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: refreshAll,
              icon: const Icon(Icons.refresh),
              label: Text(
                "Try Again",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: Text(
            'Market Intelligence',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: darkGreen,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: darkGreen),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: darkGreen),
              onPressed: refreshAll,
            ),
          ],
          bottom: TabBar(
            labelColor: primaryGreen,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: primaryGreen,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            tabs: [
              Tab(
                icon: Icon(Icons.trending_up, size: 20),
                text: 'Market Trends',
              ),
              Tab(
                icon: Icon(Icons.dashboard, size: 20),
                text: 'Market Overview',
              ),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: refreshAll,
          color: primaryGreen,
          child: Column(
            children: [
              // Market Intelligence Card
              _buildMarketInsightCard(),

              // Tab Content
              Expanded(
                child: TabBarView(
                  children: [
                    _buildTrendsTab(),
                    _buildOverviewTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}