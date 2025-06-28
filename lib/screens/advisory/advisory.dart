import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdvisoryScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;

  const AdvisoryScreen({
    Key? key,
    required this.userData,
    required this.token,
  }) : super(key: key);

  @override
  State<AdvisoryScreen> createState() => _AdvisoryScreenState();
}

class _AdvisoryScreenState extends State<AdvisoryScreen>
    with TickerProviderStateMixin {
  static const String _baseUrl = 'http://10.0.2.2:3000';

  bool _isLoading = false;
  bool _isLoadingAdvisory = false;

  List<String> _regions = [];
  List<String> _seasons = [];
  List<String> _soilTypes = [];

  String? _selectedRegion;
  String? _selectedSeason;
  String? _selectedSoil;

  Map<String, dynamic>? _advisoryData;

  AnimationController? _fadeController;
  AnimationController? _slideController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDropdownData();
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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController!, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController!, curve: Curves.easeOutCubic));

    _fadeController!.forward();
  }

  Future<void> _loadDropdownData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/advisory'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _regions = List<String>.from(data['regions']);
          _seasons = List<String>.from(data['seasons']);
          _soilTypes = List<String>.from(data['soil_types']);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load dropdown data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getAdvisory() async {
    if (_selectedRegion == null || _selectedSeason == null || _selectedSoil == null) {
      _showErrorSnackBar('Please select all required fields');
      return;
    }

    setState(() {
      _isLoadingAdvisory = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/advisory'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'region': _selectedRegion,
          'season': _selectedSeason,
          'soil': _selectedSoil,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Parsed data: $data');

        setState(() {
          _advisoryData = data;
        });
        if (_slideController != null) {
          _slideController!.forward();
        }
      } else if (response.statusCode == 404) {
        final errorData = json.decode(response.body);
        print('404 Error data: $errorData');

        String errorMessage = 'No advisory found for:\n';
        errorMessage += 'Region: $_selectedRegion\n';
        errorMessage += 'Season: $_selectedSeason\n';
        errorMessage += 'Soil: $_selectedSoil\n\n';
        errorMessage += 'Please try a different combination.';

        _showErrorSnackBar(errorMessage);
      } else {
        _showErrorSnackBar('Failed to get advisory. Please try again.');
      }
    } catch (e) {
      print('Network error: $e');
      _showErrorSnackBar('Network error: Please check your connection');
    } finally {
      setState(() {
        _isLoadingAdvisory = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _fadeController?.dispose();
    _slideController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Agricultural Advisory',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: isSmallScreen ? 16 : 18,
          ),
        ),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _fadeAnimation == null
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
        opacity: _fadeAnimation!,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : (isMediumScreen ? 16 : 20),
              vertical: isSmallScreen ? 8 : 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeCard(screenWidth, isSmallScreen),
                SizedBox(height: isSmallScreen ? 16 : 24),
                _buildDebugCard(screenWidth, isSmallScreen),
                SizedBox(height: isSmallScreen ? 16 : 24),
                _buildSelectionCard(screenWidth, isSmallScreen),
                SizedBox(height: isSmallScreen ? 16 : 24),
                if (_advisoryData != null) _buildAdvisoryResults(screenWidth, isSmallScreen),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(double screenWidth, bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.agriculture,
                size: isSmallScreen ? 24 : 32,
                color: Colors.white,
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Expanded(
                child: Text(
                  'Welcome, ${widget.userData['name'] ?? 'Farmer'}!',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Text(
            'Get personalized crop recommendations and financial advice based on your region, season, and soil type.',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.white.withOpacity(0.9),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugCard(double screenWidth, bool isSmallScreen) {
    return Card(
      elevation: 2,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info,
                  color: Colors.blue.shade700,
                  size: isSmallScreen ? 18 : 20,
                ),
                SizedBox(width: isSmallScreen ? 6 : 8),
                Expanded(
                  child: Text(
                    'Quick Test Combinations',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            _buildQuickSelectButton(
              'Littoral + Long Rainy Season (Mar-Jul) + Clay Loam',
              'Littoral',
              'Long Rainy Season (Mar-Jul)',
              'Clay Loam',
              isSmallScreen,
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            _buildQuickSelectButton(
              'East + Long Rainy Season (Apr-Nov) + Ferralitic',
              'East',
              'Long Rainy Season (Apr-Nov)',
              'Ferralitic',
              isSmallScreen,
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            _buildQuickSelectButton(
              'Centre + Long Rainy Season (Mar-Jul) + Clay',
              'Centre',
              'Long Rainy Season (Mar-Jul)',
              'Clay',
              isSmallScreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSelectButton(String label, String region, String season, String soil, bool isSmallScreen) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedRegion = region;
            _selectedSeason = season;
            _selectedSoil = soil;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade100,
          foregroundColor: Colors.blue.shade700,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 12,
            vertical: isSmallScreen ? 8 : 12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: isSmallScreen ? 10 : 12),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ),
    );
  }

  Widget _buildSelectionCard(double screenWidth, bool isSmallScreen) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tune,
                  color: Colors.green.shade700,
                  size: isSmallScreen ? 20 : 24,
                ),
                SizedBox(width: isSmallScreen ? 6 : 8),
                Expanded(
                  child: Text(
                    'Select Your Parameters',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            _buildDropdown(
              'Region',
              _selectedRegion,
              _regions,
                  (value) => setState(() {
                _selectedRegion = value;
              }),
              Icons.location_on,
              isSmallScreen,
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            _buildDropdown(
              'Season',
              _selectedSeason,
              _seasons,
                  (value) => setState(() {
                _selectedSeason = value;
              }),
              Icons.wb_sunny,
              isSmallScreen,
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            _buildDropdown(
              'Soil Type',
              _selectedSoil,
              _soilTypes,
                  (value) => setState(() {
                _selectedSoil = value;
              }),
              Icons.terrain,
              isSmallScreen,
            ),
            SizedBox(height: isSmallScreen ? 20 : 24),
            SizedBox(
              width: double.infinity,
              height: isSmallScreen ? 44 : 50,
              child: ElevatedButton(
                onPressed: _isLoadingAdvisory ? null : _getAdvisory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                  ),
                  elevation: 2,
                ),
                child: _isLoadingAdvisory
                    ? SizedBox(
                  height: isSmallScreen ? 16 : 20,
                  width: isSmallScreen ? 16 : 20,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Text(
                  'Get Advisory',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
      String label,
      String? value,
      List<String> items,
      ValueChanged<String?> onChanged,
      IconData icon,
      bool isSmallScreen,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: Colors.green.shade600,
                size: isSmallScreen ? 18 : 20,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 16,
                vertical: isSmallScreen ? 8 : 12,
              ),
            ),
            hint: Text(
              'Select $label',
              style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
            ),
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              color: Colors.black87,
            ),
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildAdvisoryResults(double screenWidth, bool isSmallScreen) {
    if (_slideAnimation == null) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _slideAnimation!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCropRecommendationsCard(screenWidth, isSmallScreen),
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildRotationPlansCard(screenWidth, isSmallScreen),
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildFinancialAdviceCard(screenWidth, isSmallScreen),
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildAdvisoryNotesCard(screenWidth, isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildCropRecommendationsCard(double screenWidth, bool isSmallScreen) {
    final crops = _advisoryData!['crop_recommendations'] as List;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.grass,
                  color: Colors.green.shade700,
                  size: isSmallScreen ? 20 : 24,
                ),
                SizedBox(width: isSmallScreen ? 6 : 8),
                Expanded(
                  child: Text(
                    'Recommended Crops',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Wrap(
              spacing: isSmallScreen ? 6 : 8,
              runSpacing: isSmallScreen ? 6 : 8,
              children: crops.map((crop) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 10 : 12,
                    vertical: isSmallScreen ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    crop.toString(),
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRotationPlansCard(double screenWidth, bool isSmallScreen) {
    final rotationPlans = _advisoryData!['crop_rotation_plans'] as Map<String, dynamic>;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.autorenew,
                  color: Colors.blue.shade700,
                  size: isSmallScreen ? 20 : 24,
                ),
                SizedBox(width: isSmallScreen ? 6 : 8),
                Expanded(
                  child: Text(
                    'Crop Rotation Plans',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            ...rotationPlans.entries.map((entry) {
              return Container(
                margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 6 : 8),
                    ...(entry.value as List).map((plan) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: isSmallScreen ? 6 : 8),
                        child: Text(
                          plan.toString(),
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            height: 1.4,
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialAdviceCard(double screenWidth, bool isSmallScreen) {
    final advisoryData = _advisoryData!;

    if (!advisoryData.containsKey('financial_advice')) {
      print('⚠️ financial_advice key missing from response');
      return const SizedBox.shrink();
    }

    final financialAdvice = advisoryData['financial_advice'] as Map<String, dynamic>;
    print('💰 Financial advice data: $financialAdvice');

    if (!financialAdvice.containsKey('budget_thresholds') ||
        !financialAdvice.containsKey('allocation_percentages')) {
      print('⚠️ Required financial advice fields missing');
      return const SizedBox.shrink();
    }

    final budgetThresholds = financialAdvice['budget_thresholds'] as List;
    final allocation = financialAdvice['allocation_percentages'] as Map<String, dynamic>;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.monetization_on,
                  color: Colors.orange.shade700,
                  size: isSmallScreen ? 20 : 24,
                ),
                SizedBox(width: isSmallScreen ? 6 : 8),
                Expanded(
                  child: Text(
                    'Financial Advice',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              'Budget Recommendations',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            ...budgetThresholds.map((threshold) {
              final min = threshold['min'];
              final max = threshold['max'];
              final advice = threshold['advice'];

              return Container(
                margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
                padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      max == null
                          ? 'Over ${min.toString()} FCFA'
                          : '${min.toString()} - ${max.toString()} FCFA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 2 : 4),
                    Text(
                      advice.toString(),
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: isSmallScreen ? 11 : 13,
                      ),
                    ),
                  ],
                ),
              );
            }),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              'Budget Allocation',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: allocation.entries.map((entry) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 2 : 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _capitalize(entry.key.toString()),
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                          ),
                        ),
                        Text(
                          '${entry.value}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              'Savings Guidance',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                financialAdvice['savings_guidance'].toString(),
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.4,
                  fontSize: isSmallScreen ? 12 : 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvisoryNotesCard(double screenWidth, bool isSmallScreen) {
    if (_advisoryData!['advisory_notes'] == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: Colors.amber.shade700,
                  size: isSmallScreen ? 20 : 24,
                ),
                SizedBox(width: isSmallScreen ? 6 : 8),
                Expanded(
                  child: Text(
                    'Advisory Notes',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Text(
                _advisoryData!['advisory_notes'].toString(),
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.4,
                  fontSize: isSmallScreen ? 13 : 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}