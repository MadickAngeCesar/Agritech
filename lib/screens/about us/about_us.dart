import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({Key? key, required Map<String, dynamic> userData, required String token}) : super(key: key);

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // AgriTech color scheme
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color darkGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF66BB6A);
  static const Color accentGreen = Color(0xFFE8F5E8);
  static const Color backgroundColor = Color(0xFFF8FDF8);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildAnimatedContainer({
    required Widget child,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (delay * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, _) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required int index,
  }) {
    return _buildAnimatedContainer(
      delay: index,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: primaryGreen,
                size: 24,
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueItem(String title, String description, int index) {
    return _buildAnimatedContainer(
      delay: index,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 8, right: 12),
              decoration: const BoxDecoration(
                color: primaryGreen,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$title: ',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    TextSpan(
                      text: description,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, int delay) {
    return _buildAnimatedContainer(
      delay: delay,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: primaryGreen,
          ),
        ),
      ),
    );
  }

  Widget _buildTextContent(String content, int delay) {
    return _buildAnimatedContainer(
      delay: delay,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          content,
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: Colors.grey[700],
            height: 1.6,
          ),
          textAlign: TextAlign.justify,
        ),
      ),
    );
  }

  Widget _buildQuoteText(String quote, int delay) {
    return _buildAnimatedContainer(
      delay: delay,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: accentGreen.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: primaryGreen.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Text(
          '"$quote"',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontStyle: FontStyle.italic,
            color: darkGreen,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildCommunitySection() {
    return _buildAnimatedContainer(
      delay: 8,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accentGreen.withOpacity(0.6), accentGreen.withOpacity(0.3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(
              "Join our community today!",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: darkGreen,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Connect with fellow farmers, access exclusive resources, and stay updated with the latest agricultural innovations.",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Handle learn more action
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Learn More",
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return _buildAnimatedContainer(
      delay: 9,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Text(
              "Get In Touch",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: primaryGreen,
              ),
            ),
          ),
          InkWell(
            onTap: () => _launchURL('https://facebook.com/agritracker'),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1877F2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.facebook,
                      color: Color(0xFF1877F2),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "Follow us on Facebook",
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: const Color(0xFF1877F2),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return _buildAnimatedContainer(
      delay: 10,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Divider(color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              "© 2024 Agri_Tracker. All rights reserved.",
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: primaryGreen,
            elevation: 0,
            pinned: true,
            expandedHeight: 120,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                "About Agri_Tracker",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Hero Image Section
                _buildAnimatedContainer(
                  delay: 0,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: const DecorationImage(
                        image: AssetImage('assets/about_icon.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            "Empowering farmers to thrive",
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Our Story Section
                _buildSectionTitle("Our Story", 1),
                _buildTextContent(
                  "Agri_Tracker's journey began with a simple but powerful question: How can we help Cameroonian farmers overcome the devastating impact of post-harvest losses? With nearly 40% of produce lost due to inadequate storage, poor market access, and environmental challenges, we sought to create a solution. Agri_Tracker equips farmers with smart tools to optimize storage, monitor conditions, and connect with buyers to ensure every harvest counts.",
                  2,
                ),

                const SizedBox(height: 32),

                // Our Aim Section
                _buildSectionTitle("Our Aim", 3),
                _buildQuoteText(
                  "To provide Cameroonian farmers with innovative tools that enhance productivity, reduce losses, and drive sustainable growth.",
                  4,
                ),

                // Our Mission Section
                _buildSectionTitle("Our Mission", 5),
                _buildTextContent(
                  "To empower Cameroonian farmers with accessible data-driven technology and actionable insights, minimizing post-harvest losses, maximizing productivity, improving livelihoods, and contributing to food security and economic growth across the nation.",
                  6,
                ),

                const SizedBox(height: 32),

                // Our Vision Section
                _buildSectionTitle("Our Vision", 7),
                _buildTextContent(
                  "To revolutionize Cameroonian agriculture by empowering farmers with real-time intelligence and innovative tools, creating a sustainable and prosperous agricultural ecosystem.",
                  8,
                ),

                const SizedBox(height: 32),

                // Our Values Section
                _buildSectionTitle("Our Values", 9),
                const SizedBox(height: 8),
                _buildValueItem(
                  "Empowerment",
                  "Information and tools for thriving farmers",
                  10,
                ),
                _buildValueItem(
                  "Innovation",
                  "Cutting-edge solutions for agricultural challenges",
                  11,
                ),
                _buildValueItem(
                  "Sustainability",
                  "Environmentally conscious practices",
                  12,
                ),
                _buildValueItem(
                  "Collaboration",
                  "Partnership-driven success",
                  13,
                ),
                _buildValueItem(
                  "Excellence",
                  "High-quality, reliable services",
                  14,
                ),

                const SizedBox(height: 32),

                // Key Features Section
                _buildSectionTitle("Key Features of Agri_Tracker", 15),
                const SizedBox(height: 8),
                _buildFeatureCard(
                  icon: Icons.trending_up,
                  title: "Real-time Market Prices",
                  subtitle: "Stay updated with current market trends",
                  index: 16,
                ),
                _buildFeatureCard(
                  icon: Icons.wb_sunny,
                  title: "Weather Forecasts to Plan Ahead",
                  subtitle: "Make informed decisions with weather data",
                  index: 17,
                ),
                _buildFeatureCard(
                  icon: Icons.storage,
                  title: "Track and Optimize Storage Conditions",
                  subtitle: "Monitor and improve storage efficiency",
                  index: 18,
                ),
                _buildFeatureCard(
                  icon: Icons.warning_amber,
                  title: "AI-based Pest and Disease Detection",
                  subtitle: "Early detection and prevention solutions",
                  index: 19,
                ),
                _buildFeatureCard(
                  icon: Icons.people,
                  title: "Connect Directly with Buyers & Sellers",
                  subtitle: "Build direct marketplace relationships",
                  index: 20,
                ),
                _buildFeatureCard(
                  icon: Icons.library_books,
                  title: "Access an Educational Library",
                  subtitle: "Learn best practices and techniques",
                  index: 21,
                ),

                const SizedBox(height: 32),

                // Community Section
                _buildCommunitySection(),

                // Contact Section
                _buildContactSection(),

                // Footer
                _buildFooter(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}