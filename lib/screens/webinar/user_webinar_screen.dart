import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'modal/RequestWebinarModal.dart';

class UserWebinarScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> userData;

  const UserWebinarScreen({
    super.key,
    required this.token,
    required this.userData,
  });

  @override
  State<UserWebinarScreen> createState() => _UserWebinarScreenState();
}

class _UserWebinarScreenState extends State<UserWebinarScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> webinars = [];
  bool isLoading = true;
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    fetchWebinars();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> fetchWebinars() async {
    setState(() => isLoading = true);
    final url = Uri.parse('http://51.75.31.246:3000/api/webinars/upcoming');

    debugPrint("📱 Fetching webinars from: $url");

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      debugPrint("✅ Response Status: ${response.statusCode}");
      debugPrint("📟 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          webinars = data['webinars'] ?? [];
          isLoading = false;
        });
        _animationController?.forward();
      } else {
        showErrorSnackBar('Failed to load webinars.');
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("❌ Error fetching webinars: $e");
      showErrorSnackBar('Connection error.');
      setState(() => isLoading = false);
    }
  }

  Future<void> joinWebinar(int webinarId, String jitsiUrl) async {
    final url = Uri.parse('http://51.75.31.246:3000/api/webinars/$webinarId/join');

    debugPrint("🎯 Attempting to join webinar: ID=$webinarId, URL=$jitsiUrl");

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'user_id': widget.userData['id']}),
      );

      debugPrint("✅ Join POST Status: ${response.statusCode}");
      debugPrint("📟 Join POST Body: ${response.body}");

      if (response.statusCode == 200) {
        final success = await launchUrlString(jitsiUrl, mode: LaunchMode.externalApplication);
        if (!success) {
          debugPrint("❌ Failed to launch webinar link: $jitsiUrl");
          showErrorSnackBar("Could not launch webinar link.");
        } else {
          debugPrint("🚀 Launched webinar successfully.");
        }
      } else {
        showErrorSnackBar("Failed to join webinar.");
      }
    } catch (e) {
      debugPrint("❌ Error joining webinar: $e");
      showErrorSnackBar("Connection error.");
    }
  }

  void showErrorSnackBar(String message) {
    debugPrint("⚠️ SnackBar Error: $message");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xFFE74C3C), // Keep error red
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _openRequestModal() {
    debugPrint("📤 Opening RequestWebinarModal for user ${widget.userData['id']}");
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => RequestWebinarModal(
        token: widget.token,
        userId: widget.userData['id'],
        onSuccess: () {
          fetchWebinars();
          debugPrint("🔄 Webinar request submitted. Refreshing list...");
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final crossAxisCount = isTablet ? 2 : 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7), // Light green-tinted background
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF2D7D32), // Deep forest green
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Upcoming Webinars',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: isLoading
                ? SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)), // Agriculture green
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading webinars...',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: const Color(0xFF558B2F), // Medium agriculture green
                      ),
                    ),
                  ],
                ),
              ),
            )
                : webinars.isEmpty
                ? SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E8), // Light agriculture green
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.agriculture_outlined, // Agriculture icon
                        size: 64,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Agricultural Webinars',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1B5E20), // Dark green
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check back for farming tips, crop guidance, and expert sessions',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: const Color(0xFF558B2F), // Medium green
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
                : SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: isTablet ? 0.8 : 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final webinar = webinars[index];
                  return _fadeAnimation != null
                      ? FadeTransition(
                    opacity: _fadeAnimation!,
                    child: _WebinarCard(
                      webinar: webinar,
                      onJoin: () => joinWebinar(
                        webinar['id'],
                        webinar['stream_url'] ?? '',
                      ),
                      index: index,
                    ),
                  )
                      : _WebinarCard(
                    webinar: webinar,
                    onJoin: () => joinWebinar(
                      webinar['id'],
                      webinar['stream_url'] ?? '',
                    ),
                    index: index,
                  );
                },
                childCount: webinars.length,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)], // Agriculture green gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _openRequestModal,
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text(
            'Request Agricultural Webinar',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _WebinarCard extends StatelessWidget {
  final Map<String, dynamic> webinar;
  final VoidCallback onJoin;
  final int index;

  const _WebinarCard({
    required this.webinar,
    required this.onJoin,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final String title = webinar['title'] ?? 'Untitled';
    final String description = webinar['description'] ?? 'No description.';
    final String date = webinar['scheduled_date'] ?? 'Unknown date';
    final String host = webinar['host']?['full_name'] ?? 'Admin';
    final String? imageUrl = webinar['image_url'];

    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutBack,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E293B).withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: imageUrl == null
                      ? const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)], // Agriculture green gradient
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                      : null,
                ),
                child: imageUrl != null
                    ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)], // Agriculture theme
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.eco_rounded, // Eco/agriculture icon
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
                    : const Center(
                  child: Icon(
                    Icons.eco_rounded, // Agriculture/eco icon
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),

              // Content Section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1B5E20), // Dark forest green
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Description
                      Expanded(
                        child: Text(
                          description,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF64748B),
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Date and Host Info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.schedule_rounded,
                                  size: 16,
                                  color: Color(0xFF2E7D32), // Dark agriculture green
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    date,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF2E7D32), // Consistent dark green
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.person_rounded,
                                  size: 16,
                                  color: Color(0xFF2E7D32), // Dark agriculture green
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    host,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF2E7D32), // Consistent dark green
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Join Button
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)], // Agriculture green gradient
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: onJoin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Join Session',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}