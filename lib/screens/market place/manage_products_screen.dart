// lib/screens/market_place/add_product_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/category.dart';
import '../../services/api_service.dart';

class AddProductScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  final List<Category> categories;
  final VoidCallback onProductAdded;

  const AddProductScreen({
    Key? key,
    required this.userData,
    required this.token,
    required this.categories,
    required this.onProductAdded,
  }) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _unitController = TextEditingController();
  int? _selectedCategoryId;
  int? _selectedSubCategoryId;
  List<File> _selectedImages = [];
  bool _isFeatured = false;
  bool _isSubmitting = false;
  late ApiService _apiService;

  // Animation controllers
  double _formOpacity = 0.0;

  // Theme colors
  final Color _primaryGreen = const Color(0xFF2E7D32); // Deep forest green
  final Color _accentGreen = const Color(0xFF66BB6A); // Medium green
  final Color _highlightColor = const Color(0xFFFFD54F); // Golden yellow for highlights

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(
      baseUrl: 'http://51.75.31.246:3000', // Replace with your actual API URL
      token: widget.token,
    );
    // Animate form entrance
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        _formOpacity = 1.0;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((image) => File(image.path)).toList());
      });
    }
  }

  Future<void> _takePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      setState(() {
        _selectedImages.add(File(photo.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategoryId == null) {
        _showErrorSnackBar('Please select a category');
        return;
      }

      if (_selectedImages.isEmpty) {
        _showErrorSnackBar('Please add at least one image');
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        // Create product data
        final productData = {
          'name': _nameController.text,
          'description': _descriptionController.text,
          'price': _priceController.text,
          'stock': _stockController.text,
          'unit': _unitController.text,
          'categoryId': _selectedCategoryId,
          'subCategoryId': _selectedSubCategoryId,
          'isFeatured': _isFeatured,
          'sellerId': widget.userData['id'],
        };

        // Submit product with images
        await _apiService.createProduct(productData, _selectedImages);

        // Call the callback to refresh the marketplace
        widget.onProductAdded();

        // Show success message
        _showSuccessSnackBar('Product added successfully');

        // Navigate back to marketplace
        Navigator.pop(context);
      } catch (e) {
        // Show error message
        _showErrorSnackBar('Error adding product: $e');
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.lato(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.lato(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: _primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.grey[800]!;
    final backgroundColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final surfaceColor = isDarkMode ? Colors.grey[850]! : Colors.grey[100]!;

    // Get screen size for responsive layout
    final Size screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.width > 600;
    final double horizontalPadding = screenSize.width * (isTablet ? 0.08 : 0.05);

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_primaryGreen.withOpacity(0.9), _primaryGreen],
            ),
          ),
        ),
        title: Text(
          'Add New Product',
          style: GoogleFonts.raleway(
            textStyle: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isSubmitting
          ? Container(
        color: backgroundColor,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: _primaryGreen,
                strokeWidth: 3,
              ),
              const SizedBox(height: 24),
              Text(
                'Adding your product...',
                style: GoogleFonts.raleway(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      )
          : Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          image: DecorationImage(
            image: const AssetImage('assets/images/subtle_farm_pattern.png'),
            opacity: 0.05,
            repeat: ImageRepeat.repeat,
          ),
        ),
        child: SafeArea(
          child: AnimatedOpacity(
            opacity: _formOpacity,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            child: Form(
              key: _formKey,
              child: CustomScrollView(
                slivers: [
                  // Header space
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 20),
                  ),

                  // Image Upload Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.collections,
                                color: _primaryGreen,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Product Images',
                                style: GoogleFonts.raleway(
                                  fontSize: isTablet ? 22 : 20,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add high-quality images to showcase your product',
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Image Upload Area
                          Container(
                            height: screenSize.height * 0.22,
                            decoration: BoxDecoration(
                              color: surfaceColor.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _primaryGreen.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: _selectedImages.isEmpty
                                ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 48,
                                    color: _primaryGreen.withOpacity(0.6),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Add product images',
                                    style: GoogleFonts.lato(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildImageSourceButton(
                                        icon: Icons.photo_library_rounded,
                                        label: 'Gallery',
                                        onTap: _pickImages,
                                        isDarkMode: isDarkMode,
                                      ),
                                      const SizedBox(width: 16),
                                      _buildImageSourceButton(
                                        icon: Icons.camera_alt_rounded,
                                        label: 'Camera',
                                        onTap: _takePicture,
                                        isDarkMode: isDarkMode,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                                : Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${_selectedImages.length} ${_selectedImages.length == 1 ? 'image' : 'images'} selected',
                                        style: GoogleFonts.lato(
                                          fontWeight: FontWeight.w500,
                                          color: _primaryGreen,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          _buildSmallActionButton(
                                            icon: Icons.add_photo_alternate,
                                            onTap: _pickImages,
                                          ),
                                          const SizedBox(width: 8),
                                          _buildSmallActionButton(
                                            icon: Icons.camera_alt,
                                            onTap: _takePicture,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _selectedImages.length,
                                      itemBuilder: (context, index) {
                                        return Container(
                                          margin: const EdgeInsets.only(right: 12),
                                          width: 120,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: Image.file(
                                                  _selectedImages[index],
                                                  width: 120,
                                                  height: double.infinity,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: GestureDetector(
                                                  onTap: () => _removeImage(index),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black.withOpacity(0.6),
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: const Icon(
                                                      Icons.close,
                                                      size: 16,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),

                  // Product Information Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: _primaryGreen,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Product Information',
                                style: GoogleFonts.raleway(
                                  fontSize: isTablet ? 22 : 20,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _nameController,
                            label: 'Product Name',
                            icon: Icons.inventory_2_outlined,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a product name';
                              }
                              return null;
                            },
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _descriptionController,
                            label: 'Description',
                            icon: Icons.description_outlined,
                            maxLines: 4,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a description';
                              }
                              return null;
                            },
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(height: 16),

                          // Responsive layout for smaller fields
                          isTablet
                              ? Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _priceController,
                                  label: 'Price',
                                  icon: Icons.attach_money_rounded,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Enter price';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Invalid price';
                                    }
                                    return null;
                                  },
                                  isDarkMode: isDarkMode,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  controller: _stockController,
                                  label: 'Stock',
                                  icon: Icons.inventory_outlined,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Enter stock';
                                    }
                                    if (int.tryParse(value) == null) {
                                      return 'Invalid stock';
                                    }
                                    return null;
                                  },
                                  isDarkMode: isDarkMode,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  controller: _unitController,
                                  label: 'Unit (kg, piece, etc.)',
                                  icon: Icons.scale_outlined,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a unit';
                                    }
                                    return null;
                                  },
                                  isDarkMode: isDarkMode,
                                ),
                              ),
                            ],
                          )
                              : Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _priceController,
                                      label: 'Price',
                                      icon: Icons.attach_money_rounded,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Enter price';
                                        }
                                        if (double.tryParse(value) == null) {
                                          return 'Invalid price';
                                        }
                                        return null;
                                      },
                                      isDarkMode: isDarkMode,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _stockController,
                                      label: 'Stock',
                                      icon: Icons.inventory_outlined,
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Enter stock';
                                        }
                                        if (int.tryParse(value) == null) {
                                          return 'Invalid stock';
                                        }
                                        return null;
                                      },
                                      isDarkMode: isDarkMode,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _unitController,
                                label: 'Unit (kg, piece, etc.)',
                                icon: Icons.scale_outlined,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a unit';
                                  }
                                  return null;
                                },
                                isDarkMode: isDarkMode,
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),

                  // Category Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.category_outlined,
                                color: _primaryGreen,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Product Category',
                                style: GoogleFonts.raleway(
                                  fontSize: isTablet ? 22 : 20,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Beautiful category selector
                          Container(
                            decoration: BoxDecoration(
                              color: surfaceColor.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _primaryGreen.withOpacity(0.2),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Main Category',
                                  style: GoogleFonts.lato(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Category chips
                                SizedBox(
                                  height: 50,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: widget.categories.length,
                                    itemBuilder: (context, index) {
                                      final category = widget.categories[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: ChoiceChip(
                                          label: Text(
                                            category.name,
                                            style: GoogleFonts.lato(
                                              fontWeight: FontWeight.w500,
                                              color: _selectedCategoryId == category.id ? Colors.white : textColor,
                                            ),
                                          ),
                                          selected: _selectedCategoryId == category.id,
                                          selectedColor: _primaryGreen,
                                          backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(30),
                                          ),
                                          onSelected: (selected) {
                                            if (selected) {
                                              setState(() {
                                                _selectedCategoryId = category.id;
                                                _selectedSubCategoryId = null;
                                              });
                                            }
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                // Subcategory section (appears only when a category is selected)
                                if (_selectedCategoryId != null)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 16),
                                      const Divider(),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Subcategory',
                                        style: GoogleFonts.lato(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      if (widget.categories
                                          .firstWhere((cat) => cat.id == _selectedCategoryId,
                                          orElse: () => Category(id: -1, name: '', subCategories: []))
                                          .subCategories
                                          ?.isNotEmpty ??
                                          false)
                                        SizedBox(
                                          height: 50,
                                          child: ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: widget.categories
                                                .firstWhere((cat) => cat.id == _selectedCategoryId,
                                                orElse: () => Category(id: -1, name: '', subCategories: []))
                                                .subCategories!
                                                .length,
                                            itemBuilder: (context, index) {
                                              final subCategory = widget.categories
                                                  .firstWhere((cat) => cat.id == _selectedCategoryId,
                                                  orElse: () => Category(id: -1, name: '', subCategories: []))
                                                  .subCategories![index];
                                              return Padding(
                                                padding: const EdgeInsets.only(right: 8.0),
                                                child: ChoiceChip(
                                                  label: Text(
                                                    subCategory.name,
                                                    style: GoogleFonts.lato(
                                                      fontWeight: FontWeight.w500,
                                                      color: _selectedSubCategoryId == subCategory.id
                                                          ? Colors.white
                                                          : textColor,
                                                    ),
                                                  ),
                                                  selected: _selectedSubCategoryId == subCategory.id,
                                                  selectedColor: _accentGreen,
                                                  backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(30),
                                                  ),
                                                  onSelected: (selected) {
                                                    if (selected) {
                                                      setState(() {
                                                        _selectedSubCategoryId = subCategory.id;
                                                      });
                                                    }
                                                  },
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                      else
                                        Text(
                                          'No subcategories available for this category',
                                          style: GoogleFonts.lato(
                                            fontStyle: FontStyle.italic,
                                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Featured Toggle with modern design
                          Container(
                            decoration: BoxDecoration(
                              color: surfaceColor.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _primaryGreen.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

                          ),
                          const SizedBox(height: 24),

                          // Submit Button
                          Container(
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryGreen.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _submitForm,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: _primaryGreen,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_circle_outline, size: 24),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Add Product',
                                    style: GoogleFonts.raleway(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool isDarkMode = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.lato(
          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
        ),
        prefixIcon: Icon(icon, color: _primaryGreen),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _primaryGreen,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: isDarkMode ? Colors.grey[850] : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      style: GoogleFonts.lato(
        fontSize: 16,
        color: isDarkMode ? Colors.white : Colors.grey[800],
      ),
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
    );
  }

  Widget _buildImageSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _primaryGreen.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: _primaryGreen,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: _primaryGreen,
        ),
      ),
    );
  }
}