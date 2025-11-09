import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  final Function(Map<String, dynamic>) onProfileUpdated;

  const EditProfileScreen({
    Key? key,
    required this.userData,
    required this.token,
    required this.onProfileUpdated,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  String? errorMessage;

  // Controllers for text fields
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _bioController;
  late TextEditingController _facebookController;
  late TextEditingController _instagramController;
  late TextEditingController _twitterController;
  late TextEditingController _tiktokController;
  late TextEditingController _profileImageController;

  // Modern color scheme (same as ProfileScreen)
  static const Color primaryColor = Color(0xFF2E7D32); // Deep forest green
  static const Color accentColor = Color(0xFF66BB6A);  // Medium green
  static const Color backgroundColor = Color(0xFFF5F5F5); // Light grey background
  static const Color cardColor = Colors.white;
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkCardColor = Color(0xFF1E1E1E);
  static const Color darkTextColor = Color(0xFFE0E0E0);
  static const Color lightTextColor = Color(0xFF424242);

  static const String apiUrl = 'http://51.75.31.246:3000/api/myprofile';

  @override
  void initState() {
    super.initState();

    // Initialize controllers with user data
    _fullNameController = TextEditingController(text: widget.userData['full_name'] ?? '');
    _phoneController = TextEditingController(text: widget.userData['phone'] ?? '');
    _addressController = TextEditingController(text: widget.userData['address'] ?? '');
    _bioController = TextEditingController(text: widget.userData['bio'] ?? '');
    _facebookController = TextEditingController(text: widget.userData['facebook'] ?? '');
    _instagramController = TextEditingController(text: widget.userData['instagram'] ?? '');
    _twitterController = TextEditingController(text: widget.userData['twitter'] ?? '');
    _tiktokController = TextEditingController(text: widget.userData['tiktok'] ?? '');
    _profileImageController = TextEditingController(text: widget.userData['profile_image'] ?? '');
  }

  @override
  void dispose() {
    // Dispose all controllers
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _twitterController.dispose();
    _tiktokController.dispose();
    _profileImageController.dispose();
    super.dispose();
  }

  // Function to update profile
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? widget.token;

      if (token.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'No authentication token found';
        });
        return;
      }

      final Map<String, dynamic> updateData = {
        'full_name': _fullNameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'bio': _bioController.text,
        'facebook': _facebookController.text,
        'instagram': _instagramController.text,
        'twitter': _twitterController.text,
        'tiktok': _tiktokController.text,
        'profile_image': _profileImageController.text,
      };

      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final updatedUser = responseData['user'];

        // Update the data in the parent screen
        widget.onProfileUpdated({
          ...widget.userData,
          ...updatedUser,
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Return to previous screen
        Navigator.pop(context);
      } else {
        final responseData = json.decode(response.body);
        setState(() {
          errorMessage = responseData['message'] ?? 'Failed to update profile';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? darkTextColor : lightTextColor;
    final bgColor = isDarkMode ? darkBackgroundColor : backgroundColor;
    final cardBackgroundColor = isDarkMode ? darkCardColor : cardColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: isLoading ? null : _updateProfile,
            child: Text(
              'Save',
              style: GoogleFonts.poppins(
                color: primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            // Profile Image URL
            _buildSectionHeader('Profile Image URL', textColor),
            _buildTextField(
              controller: _profileImageController,
              hintText: 'Enter image URL',
              icon: Icons.image_outlined,
              validator: (value) => null,
              bgColor: cardBackgroundColor,
              textColor: textColor,
            ),
            const SizedBox(height: 24),

            // Personal Information
            _buildSectionHeader('Personal Information', textColor),

            // Full Name
            _buildTextField(
              controller: _fullNameController,
              hintText: 'Full Name',
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
              bgColor: cardBackgroundColor,
              textColor: textColor,
            ),
            const SizedBox(height: 16),

            // Phone
            _buildTextField(
              controller: _phoneController,
              hintText: 'Phone Number',
              icon: Icons.phone_outlined,
              validator: (value) => null,
              bgColor: cardBackgroundColor,
              textColor: textColor,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // Address
            _buildTextField(
              controller: _addressController,
              hintText: 'Address',
              icon: Icons.location_on_outlined,
              validator: (value) => null,
              bgColor: cardBackgroundColor,
              textColor: textColor,
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Bio
            _buildSectionHeader('About Me', textColor),
            _buildTextField(
              controller: _bioController,
              hintText: 'Tell something about yourself...',
              icon: Icons.description_outlined,
              validator: (value) => null,
              bgColor: cardBackgroundColor,
              textColor: textColor,
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            // Social Media Links
            _buildSectionHeader('Social Media Links', textColor),

            // Facebook
            _buildTextField(
              controller: _facebookController,
              hintText: 'Facebook username or link',
              icon: Icons.facebook,
              validator: (value) => null,
              bgColor: cardBackgroundColor,
              textColor: textColor,
            ),
            const SizedBox(height: 16),

            // Instagram
            _buildTextField(
              controller: _instagramController,
              hintText: 'Instagram username',
              icon: Icons.camera_alt_outlined,
              validator: (value) => null,
              bgColor: cardBackgroundColor,
              textColor: textColor,
            ),
            const SizedBox(height: 16),

            // Twitter
            _buildTextField(
              controller: _twitterController,
              hintText: 'Twitter/X username',
              icon: Icons.messenger_outline,
              validator: (value) => null,
              bgColor: cardBackgroundColor,
              textColor: textColor,
            ),
            const SizedBox(height: 16),

            // TikTok
            _buildTextField(
              controller: _tiktokController,
              hintText: 'TikTok username',
              icon: Icons.music_note_outlined,
              validator: (value) => null,
              bgColor: cardBackgroundColor,
              textColor: textColor,
            ),

            // Error message
            if (errorMessage != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(
                  errorMessage!,
                  style: GoogleFonts.poppins(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 40),

            // Save Button
            ElevatedButton(
              onPressed: isLoading ? null : _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Save Changes',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required String? Function(String?) validator,
    required Color bgColor,
    required Color textColor,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: GoogleFonts.poppins(
          color: textColor,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(
            color: textColor.withOpacity(0.5),
            fontSize: 15,
          ),
          prefixIcon: Icon(
            icon,
            color: primaryColor,
            size: 22,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}