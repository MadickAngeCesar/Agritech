import 'dart:convert';
import 'dart:io';
import 'package:agritech/screens/advisory/advisory.dart';
import 'package:agritech/screens/contact%20us/contact%20us.dart';
import 'package:agritech/screens/ebooks/ebooks.dart';
import 'package:agritech/screens/educational%20library/EducationalLibraryScreen.dart';
import 'package:agritech/screens/video/videoTips.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../about us/about_us.dart';
import '../chat bot/chat.dart';
import '../chat forum/forum.dart';
import '../disease detection/CameraCaptureScreen.dart';
import '../my Products/my_products_screen.dart';
import '../my Products/userProductDetailScreen.dart';
import '../navigation bar/navigation_bar.dart';
import '../privacy policy/privacyscreen.dart';
import '../users orders/my_orders.dart';
import '../webinar/user_webinar_screen.dart';
import 'edit_profile.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;

  const ProfileScreen({
    Key? key,
    required this.userData,
    required this.token,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  late AnimationController _animationController;

  // Collapse states for each section
  bool isBusinessExpanded = false;
  bool isLearningExpanded = false;
  bool isToolsExpanded = false;
  bool isSettingsExpanded = false;
  bool isHelpExpanded = false;

  // Modern AgriTech color scheme
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF66BB6A);
  static const Color accentGreen = Color(0xFFE8F5E8);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color backgroundColor = Color(0xFFF8FDF8);
  static const Color cardColor = Colors.white;
  static const Color warningOrange = Color(0xFFFF8A65);

  static const String apiUrl = 'http://10.0.2.2:3000/api/myprofile';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    fetchUserProfile();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchUserProfile() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? widget.token;

      if (token.isEmpty) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          userData = jsonDecode(response.body);
          isLoading = false;
        });
        _animationController.forward();
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Navigator.of(context).pushNamedAndRemoveUntil('/signin', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed. Try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

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

  Widget _buildModernProfileHeader() {
    return _buildAnimatedContainer(
      delay: 0,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Profile Avatar
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryGreen,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: userData!['profile_image'] != null
                    ? Image.network(
                  userData!['profile_image'],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: accentGreen.withOpacity(0.8),
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white,
                      ),
                    );
                  },
                )
                    : Container(
                  color: accentGreen.withOpacity(0.8),
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // User Name
            Text(
              userData!['full_name'] ?? userData!['name'] ?? 'Unknown',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: darkGreen,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            // User Email
            Text(
              userData!['email'] ?? 'No email provided',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Edit Profile Button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(
                      userData: userData!,
                      token: widget.token,
                      onProfileUpdated: (updatedData) {
                        setState(() {
                          userData = updatedData;
                        });
                      },
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(
                'Edit Profile',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialMediaSection() {
    return _buildAnimatedContainer(
      delay: 1,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.share_outlined,
                    color: primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Connect With Me',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: darkGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Facebook
                if (userData!['facebook'] != null && userData!['facebook'].isNotEmpty)
                  _buildSocialMediaIcon(
                    icon: Icons.facebook,
                    backgroundColor: const Color(0xFF1877F2),
                    platformName: 'facebook',
                    username: userData!['facebook'] ?? '',
                    label: 'Facebook',
                  ),

                // Instagram
                if (userData!['instagram'] != null && userData!['instagram'].isNotEmpty)
                  _buildSocialMediaIcon(
                    icon: Icons.camera_alt_rounded,
                    backgroundColor: const Color(0xFFE1306C),
                    platformName: 'instagram',
                    username: userData!['instagram'] ?? '',
                    label: 'Instagram',
                  ),

                // Twitter
                if (userData!['twitter'] != null && userData!['twitter'].isNotEmpty)
                  _buildSocialMediaIcon(
                    icon: Icons.alternate_email,
                    backgroundColor: const Color(0xFF1DA1F2),
                    platformName: 'twitter',
                    username: userData!['twitter'] ?? '',
                    label: 'Twitter',
                  ),

                // TikTok
                if (userData!['tiktok'] != null && userData!['tiktok'].isNotEmpty)
                  _buildSocialMediaIcon(
                    icon: Icons.music_note_rounded,
                    backgroundColor: const Color(0xFF000000),
                    platformName: 'tiktok',
                    username: userData!['tiktok'] ?? '',
                    label: 'TikTok',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialMediaIcon({
    required IconData icon,
    required Color backgroundColor,
    required String platformName,
    required String username,
    required String label,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _launchSocialMedia(platformName, username),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: backgroundColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  bool _hasSocialLinks() {
    return (userData!['facebook'] != null && userData!['facebook'].isNotEmpty) ||
        (userData!['instagram'] != null && userData!['instagram'].isNotEmpty) ||
        (userData!['twitter'] != null && userData!['twitter'].isNotEmpty) ||
        (userData!['tiktok'] != null && userData!['tiktok'].isNotEmpty);
  }

  Future<void> _launchSocialMedia(String platform, String username) async {
    String url = '';

    switch (platform) {
      case 'facebook':
        url = 'https://www.facebook.com/$username';
        break;
      case 'instagram':
        url = 'https://www.instagram.com/$username';
        break;
      case 'twitter':
        url = 'https://twitter.com/$username';
        break;
      case 'tiktok':
        url = 'https://www.tiktok.com/@$username';
        break;
      default:
        return;
    }

    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open $platform'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildQuickStatsRow() {
    return _buildAnimatedContainer(
      delay: 2,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildStatCard("Products", "12", Icons.inventory_2_outlined),
            const SizedBox(width: 12),
            _buildStatCard("Orders", "8", Icons.shopping_bag_outlined),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
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
            Icon(icon, color: primaryGreen, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: darkGreen,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsibleMenuSection({
    required String title,
    required IconData titleIcon,
    required List<MenuItemData> items,
    required bool isExpanded,
    required VoidCallback onToggle,
    required int delay,
    Color? titleColor,
    String? badge,
  }) {
    return _buildAnimatedContainer(
      delay: delay,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Collapsible Header
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (titleColor ?? primaryGreen).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          titleIcon,
                          color: titleColor ?? primaryGreen,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: darkGreen,
                          ),
                        ),
                      ),
                      if (badge != null)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: warningOrange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            badge,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.grey[600],
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Expandable Content
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  const Divider(height: 1),
                  ...items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return _buildMenuItem(
                      icon: item.icon,
                      title: item.title,
                      subtitle: item.subtitle,
                      onTap: item.onTap,
                      iconColor: item.iconColor ?? (titleColor ?? primaryGreen),
                      isLast: index == items.length - 1,
                      badge: item.badge,
                    );
                  }).toList(),
                ],
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    required Color iconColor,
    bool isLast = false,
    String? badge,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: warningOrange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isLast)
          const Divider(
            indent: 66,
            endIndent: 20,
            height: 1,
          ),
      ],
    );
  }

  Widget _buildLogoutSection() {
    return _buildAnimatedContainer(
      delay: 8,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showLogoutConfirmation,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.logout_rounded,
                    color: Colors.red,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Logout',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
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

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Text(
            'Logout',
            style: GoogleFonts.poppins(
              color: darkGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: GoogleFonts.poppins(
              color: Colors.grey[700],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: Text(
                'Logout',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                logout();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: primaryGreen,
          ),
        ),
      );
    }

    if (userData == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 80,
                color: primaryGreen.withOpacity(0.6),
              ),
              const SizedBox(height: 16),
              Text(
                'Could not load profile',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: darkGreen,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: fetchUserProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  'Retry',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: RefreshIndicator(
        color: primaryGreen,
        onRefresh: fetchUserProfile,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Custom App Bar
            SliverAppBar(
              backgroundColor: backgroundColor,
              elevation: 0,
              floating: true,
              snap: true,
              title: Text(
                'My Profile',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: darkGreen,
                ),
              ),
              centerTitle: true,
            ),

            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Profile Header
                  _buildModernProfileHeader(),

                  const SizedBox(height: 16),

                  // Social Media Section (if user has social links)
                  if (_hasSocialLinks()) _buildSocialMediaSection(),

                  const SizedBox(height: 16),

                  // Quick Stats
                  _buildQuickStatsRow(),

                  const SizedBox(height: 24),

                  // My Business Section (Collapsible)
                  _buildCollapsibleMenuSection(
                    title: "My Business",
                    titleIcon: Icons.business_center_outlined,
                    isExpanded: isBusinessExpanded,
                    onToggle: () => setState(() => isBusinessExpanded = !isBusinessExpanded),
                    delay: 3,
                    badge: "3",
                    items: [
                      MenuItemData(
                        icon: Icons.inventory_2_outlined,
                        title: "My Products",
                        subtitle: "Manage your product listings",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MyProductsScreen(
                                userData: widget.userData,
                                token: widget.token,
                              ),
                            ),
                          );
                        },
                      ),
                      MenuItemData(
                        icon: Icons.shopping_bag_outlined,
                        title: "My Orders",
                        subtitle: "Track your orders and sales",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MyOrdersScreen(
                                userData: widget.userData,
                                token: widget.token,
                              ),
                            ),
                          );
                        },
                        badge: "3",
                      ),
                    ],
                  ),

                  // Learning & Support Section (Collapsible)
                  _buildCollapsibleMenuSection(
                    title: "Learning & Support",
                    titleIcon: Icons.school_outlined,
                    isExpanded: isLearningExpanded,
                    onToggle: () => setState(() => isLearningExpanded = !isLearningExpanded),
                    delay: 4,
                    items: [
                      MenuItemData(
                        icon: Icons.forum_outlined,
                        title: "Community Forums",
                        subtitle: "Connect with other farmers",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ForumScreen(
                                userData: userData!,
                                token: widget.token,
                              ),
                            ),
                          );
                        },
                      ),
                      MenuItemData(
                        icon: Icons.smart_toy_outlined,
                        title: "FAQ & Chat Bot",
                        subtitle: "get a tour an dhelp around your app",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatBotScreen(
                                userData: widget.userData,
                                token: widget.token,
                              ),
                            ),
                          );
                        },
                      ),
                      MenuItemData(
                        icon: Icons.library_books_outlined,
                        title: "Educational Library",
                        subtitle: "Access farming resources",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EducationalLibraryScreen(userData: {}, token: '',),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  // Smart Tools Section (Collapsible)
                  _buildCollapsibleMenuSection(
                    title: "Smart Tools",
                    titleIcon: Icons.build_outlined,
                    isExpanded: isToolsExpanded,
                    onToggle: () => setState(() => isToolsExpanded = !isToolsExpanded),
                    delay: 5,
                    titleColor: lightGreen,
                    items: [
                      MenuItemData(
                        icon: Icons.camera_alt_outlined,
                        title: "Disease Detection",
                        subtitle: "AI-powered crop analysis",
                        iconColor: lightGreen,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CameraCaptureScreen(onImageCaptured: (File image) {  },),
                            ),
                          );
                        },
                      ),
                      MenuItemData(
                        icon: Icons.camera_alt_outlined,
                        title: "AI Advisory",
                        subtitle: "AI-powered real time advice",
                        iconColor: lightGreen,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdvisoryScreen(userData: {}, token: ''),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  // Account Settings Section (Collapsible)
                  _buildCollapsibleMenuSection(
                    title: "Account Settings",
                    titleIcon: Icons.settings_outlined,
                    isExpanded: isSettingsExpanded,
                    onToggle: () => setState(() => isSettingsExpanded = !isSettingsExpanded),
                    delay: 6,
                    titleColor: Colors.blueGrey,
                    items: [
                      MenuItemData(
                        icon: Icons.lock_outline,
                        title: "Change Password",
                        subtitle: "Update your security",
                        iconColor: Colors.blueGrey,
                        onTap: () {
                          _showChangePasswordDialog();
                        },
                      ),
                      MenuItemData(
                        icon: Icons.notifications_outlined,
                        title: "Notifications",
                        subtitle: "Manage your preferences",
                        iconColor: Colors.blueGrey,
                        onTap: () {
                          // Implement notifications settings
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Notification settings coming soon!'),
                              backgroundColor: primaryGreen,
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  // Help & About Section (Collapsible)
                  _buildCollapsibleMenuSection(
                    title: "Help & About",
                    titleIcon: Icons.help_outline,
                    isExpanded: isHelpExpanded,
                    onToggle: () => setState(() => isHelpExpanded = !isHelpExpanded),
                    delay: 7,
                    titleColor: Colors.grey,
                    items: [
                      MenuItemData(
                        icon: Icons.phone_outlined,
                        title: "Contact Us",
                        subtitle: "Get support and help",
                        iconColor: Colors.grey,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ContactUsScreen(),
                            ),
                          );
                        },
                      ),
                      MenuItemData(
                        icon: Icons.info_outline,
                        title: "About Agri_Tracker",
                        subtitle: "Learn about our mission",
                        iconColor: Colors.grey,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AboutUsScreen(
                                userData: widget.userData,
                                token: widget.token,
                              ),
                            ),
                          );
                        },
                      ),
                      MenuItemData(
                        icon: Icons.privacy_tip_outlined,
                        title: "Privacy Policy",
                        subtitle: "Read our privacy terms",
                        iconColor: Colors.grey,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PrivacyPolicyScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  // Logout Section
                  _buildLogoutSection(),

                  // Version Info
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'AgroMarket v1.0.2',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: FarmConnectNavBar(
        isDarkMode: false,
        darkColor: Colors.black,
        primaryColor: primaryGreen,
        textColor: darkGreen,
        currentIndex: 3,
        userData: userData ?? {},
        token: widget.token,
      ),
    );
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool hideOld = true;
    bool hideNew = true;
    bool hideConfirm = true;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Change Password',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: primaryGreen,
                        ),
                      ),
                      SizedBox(height: 24),
                      _buildPasswordField(
                        controller: oldPasswordController,
                        label: 'Current Password',
                        hideText: hideOld,
                        onToggle: () => setState(() => hideOld = !hideOld),
                      ),
                      SizedBox(height: 16),
                      _buildPasswordField(
                        controller: newPasswordController,
                        label: 'New Password',
                        hideText: hideNew,
                        onToggle: () => setState(() => hideNew = !hideNew),
                      ),
                      SizedBox(height: 16),
                      _buildPasswordField(
                        controller: confirmPasswordController,
                        label: 'Confirm Password',
                        hideText: hideConfirm,
                        onToggle: () => setState(() => hideConfirm = !hideConfirm),
                      ),
                      SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: isLoading ? null : () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                color: Color(0xFF666666),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            onPressed: isLoading ? null : () async {
                              final oldPass = oldPasswordController.text.trim();
                              final newPass = newPasswordController.text.trim();
                              final confirmPass = confirmPasswordController.text.trim();

                              if (newPass.isEmpty || confirmPass.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Please fill all fields'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                                return;
                              }

                              if (newPass != confirmPass) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('New passwords do not match'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                                return;
                              }

                              setState(() => isLoading = true);

                              try {
                                final response = await http.post(
                                  Uri.parse('http://10.0.2.2:3000/api/users/change-password'),
                                  headers: {
                                    'Content-Type': 'application/json',
                                    'Authorization': 'Bearer ${widget.token}',
                                  },
                                  body: jsonEncode({
                                    'oldPassword': oldPass,
                                    'newPassword': newPass,
                                    'phone': userData?['phone'],
                                  }),
                                );

                                if (response.statusCode == 200) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Password changed successfully'),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                } else {
                                  final err = jsonDecode(response.body);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(err['message'] ?? 'Password change failed'),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Network error occurred'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              } finally {
                                setState(() => isLoading = false);
                              }
                            },
                            child: isLoading
                                ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : Text(
                              'Update',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool hideText,
    required VoidCallback onToggle,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: hideText,
      style: GoogleFonts.poppins(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Color(0xFF666666)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryGreen, width: 1.5),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            hideText ? Icons.visibility_off : Icons.visibility,
            color: Color(0xFF666666),
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}

// Data class for menu items
class MenuItemData {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final String? badge;

  MenuItemData({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.iconColor,
    this.badge,
  });
}