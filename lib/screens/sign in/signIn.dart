import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Admin/screens/dashboard.dart';
import '../../services/api_service.dart';
import 'package:agritech/services/auth_provider.dart' as myAuth;
import '../../services/cart_provider.dart';
import '../feature page/feature_page.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _isEmailLogin = true; // Toggle between email and phone login
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(); // Added for phone login
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  // Animation Controller and Animations
  AnimationController? _animationController;
  Animation<double>? _scaleAnimation;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  // Plant Green Color Palette - same as original
  final Color _primaryGreen = const Color(0xFF2E7D32);
  final Color _lightGreen = const Color(0xFF4CAF50);
  final Color _darkGreen = const Color(0xFF1B5E20);

  @override
  void initState() {
    super.initState();

    // Setup animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Scale animation
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeOutCubic,
      ),
    );

    // Fade animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    // Slide animation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeOutQuint,
      ),
    );

    // Start the animation
    _animationController!.forward();
  }

  void _toggleAuthMode() {
    if (_animationController == null) return;

    setState(() {
      _isLogin = !_isLogin;
      // Reset and replay animation
      _animationController!.reset();
      _animationController!.forward();
    });
  }

  // Toggle between email and phone login
  void _toggleLoginMethod() {
    setState(() {
      _isEmailLogin = !_isEmailLogin;
    });
  }

  Future<void> _handleGoogleSignIn() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
      await firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final response = await http.post(
          Uri.parse('http://51.75.31.246:3000/api/auth/google-login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': user.email,
            'full_name': user.displayName,
            'profile_image': user.photoURL,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final token = data['token'];
          final userData = data['user'];

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', token);
          await prefs.setString('user_id', userData['id'].toString());

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(userData: userData, token: token),
            ),
          );
        } else {
          print("❌ Backend error: ${response.body}");
        }
      }
    } catch (e) {
      print("⚠️ Google Sign-in error: $e");
    }
  }


  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      String identifier = _isEmailLogin ? _emailController.text.trim() : _phoneController.text.trim();
      String password = _passwordController.text.trim();

      final body = _isEmailLogin
          ? {'email': identifier, 'password': password}
          : {'phone': identifier, 'password': password};

      try {
        final response = await http.post(
          Uri.parse('http://51.75.31.246:3000/api/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final token = responseData['token'];
          final user = responseData['user'];

          print('✅ Login successful. Token: $token');

          final authProvider = Provider.of<myAuth.AuthProvider>(context, listen: false);
          authProvider.setToken(token);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', token);
          await prefs.setString('user_role', user['role']);
          await prefs.setString('user_id', user['id'].toString());

          if (user['role'] == 'admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AdminDashboardScreen(
                  userData: user,
                  token: token,
                ),
              ),
            );
          }else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(
                  userData: user,
                  token: token,
                ),
              ),
            );
          }
        }
        else {
          final error = jsonDecode(response.body);
          print('❌ Login failed: ${error['message']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error['message'] ?? 'Login failed')),
          );
        }
      } catch (e) {
        print('⚠️ Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Something went wrong. Please try again.')),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Safety check to prevent null animations
    if (_animationController == null ||
        _scaleAnimation == null ||
        _fadeAnimation == null ||
        _slideAnimation == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background with pattern
          Container(
            width: double.infinity,
            height: double.infinity,
            color: _darkGreen,
            child: CustomPaint(
              painter: BackgroundPatternPainter(
                primaryColor: _primaryGreen,
                secondaryColor: _lightGreen,
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // Logo and title section
                    SizedBox(height: size.height * 0.05),
                    ScaleTransition(
                      scale: _scaleAnimation!,
                      child: FadeTransition(
                        opacity: _fadeAnimation!,
                        child: Column(
                          children: [
                            // Logo with glowing effect
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _lightGreen.withOpacity(0.6),
                                    blurRadius: 25,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/logo.jpg',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Animated title
                            AnimatedTextKit(
                              animatedTexts: [
                                TypewriterAnimatedText(
                                  _isLogin ? 'Welcome Back' : 'Join Us Today',
                                  textStyle: GoogleFonts.poppins(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                  speed: const Duration(milliseconds: 100),
                                ),
                              ],
                              totalRepeatCount: 1,
                            ),

                            // Subtitle
                            Text(
                              _isLogin
                                  ? 'Sign in to continue your journey'
                                  : 'Create an account to get started',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.05),

                    // Auth card
                    SlideTransition(
                      position: _slideAnimation!,
                      child: FadeTransition(
                        opacity: _fadeAnimation!,
                        child: Card(
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          shadowColor: Colors.black.withOpacity(0.3),
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryGreen.withOpacity(0.1),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Title inside card
                                  Text(
                                    _isLogin ? 'Login' : 'Sign Up',
                                    style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: _darkGreen,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Login method toggle (only for Login screen)
                                  if (_isLogin) ...[
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Row(
                                        children: [
                                          // Email tab
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () {
                                                if (!_isEmailLogin) _toggleLoginMethod();
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                decoration: BoxDecoration(
                                                  color: _isEmailLogin ? _primaryGreen : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(15),
                                                ),
                                                child: Text(
                                                  'Email',
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.poppins(
                                                    color: _isEmailLogin ? Colors.white : Colors.grey.shade700,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Phone tab
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () {
                                                if (_isEmailLogin) _toggleLoginMethod();
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                decoration: BoxDecoration(
                                                  color: !_isEmailLogin ? _primaryGreen : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(15),
                                                ),
                                                child: Text(
                                                  'Phone',
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.poppins(
                                                    color: !_isEmailLogin ? Colors.white : Colors.grey.shade700,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                  ],

                                  // Name Field (Only for Signup)
                                  if (!_isLogin) ...[
                                    _buildTextField(
                                      controller: _nameController,
                                      label: 'Full Name',
                                      icon: Icons.person_outline,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your name';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                  ],

                                  // Email Field (only if email login is selected or for signup)
                                  if (_isEmailLogin || !_isLogin) ...[
                                    _buildTextField(
                                      controller: _emailController,
                                      label: 'Email Address',
                                      icon: Icons.email_outlined,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                          return 'Please enter a valid email';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                  ],

                                  // Phone Field (only if phone login is selected)
                                  if (!_isEmailLogin && _isLogin) ...[
                                    _buildTextField(
                                      controller: _phoneController,
                                      label: 'Phone Number',
                                      icon: Icons.phone_outlined,
                                      keyboardType: TextInputType.phone,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your phone number';
                                        }
                                        if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(value)) {
                                          return 'Please enter a valid phone number';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                  ],

                                  // Password Field
                                  _buildTextField(
                                    controller: _passwordController,
                                    label: 'Password',
                                    icon: Icons.lock_outline,
                                    isPassword: true,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      if (value.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                  ),

                                  // Forgot password (only for login)
                                  if (_isLogin) ...[
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.pushNamed(context, '/forgot-reset');
                                        },
                                        child: Text(
                                          'Forgot Password?',
                                          style: GoogleFonts.poppins(
                                            color: _primaryGreen,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 30),

                                  // Submit Button with double infinity (full width)
                                  Container(
                                    width: double.infinity, // Full width
                                    child: ElevatedButton(
                                      onPressed: _submitForm,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        minimumSize: Size(double.infinity, 50), // Ensure full width
                                      ),
                                      child: Ink(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [_primaryGreen, _darkGreen],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: Container(
                                          width: double.infinity, // Ensure inner container takes full width
                                          padding: const EdgeInsets.symmetric(vertical: 15),
                                          child: Text(
                                            _isLogin ? 'LOGIN' : 'SIGN UP',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Divider with text
                    FadeTransition(
                      opacity: _fadeAnimation!,
                      child: Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.white.withOpacity(0.5),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.white.withOpacity(0.5),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Google Sign In Button
                    FadeTransition(
                      opacity: _fadeAnimation!,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: TextButton.icon(
                          onPressed: _handleGoogleSignIn,
                          icon: Container(
                            padding: const EdgeInsets.all(2),
                            child: Image.asset(
                              'assets/google.png',
                              width: 24,
                              height: 24,
                              errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.account_circle, size: 24),
                            ),
                          ),
                          label: Text(
                            _isLogin ? 'Continue with Google' : 'Sign up with Google',
                            style: GoogleFonts.poppins(
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        )
                        ,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Toggle between Login and Signup
                    FadeTransition(
                      opacity: _fadeAnimation!,
                      child: TextButton(
                        onPressed: _toggleAuthMode,
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            children: [
                              TextSpan(
                                text: _isLogin
                                    ? 'Don\'t have an account? '
                                    : 'Already have an account? ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              TextSpan(
                                text: _isLogin ? 'Sign Up' : 'Login',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  decoration: TextDecoration.underline,
                                  decorationThickness: 2,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {

                                    if (_isLogin) {
                                      Navigator.pushNamed(context, '/signup');
                                    } else {
                                      Navigator.pushNamed(context, '/login');
                                    }
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: size.height * 0.05),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Custom text field widget
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: Colors.grey.shade600,
            fontSize: 15,
          ),
          prefixIcon: Icon(icon, color: _primaryGreen),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: _primaryGreen, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        validator: validator,
      ),
    );
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose(); // Dispose phone controller
    super.dispose();
  }
}

// Custom painter for background pattern
class BackgroundPatternPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  BackgroundPatternPainter({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create gradients
    final Paint paint = Paint();

    // Draw base gradient
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final Gradient gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        primaryColor,
        secondaryColor.withOpacity(0.8),
      ],
    );

    paint.shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);

    // Draw decorative circles
    final Paint circlePaint = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..style = PaintingStyle.fill;

    // Draw a wave pattern
    final waveHeight = size.height / 2;
    final waveWidth = size.width;

    // Draw large waves
    Path wavePath = Path();
    wavePath.moveTo(0, size.height);

    for (int i = 0; i < 4; i++) {
      final waveSegmentWidth = waveWidth / 4;
      final x1 = waveSegmentWidth * i;
      final y1 = size.height - (i % 2 == 0 ? waveHeight * 0.5 : waveHeight * 0.8);
      final x2 = waveSegmentWidth * (i + 1);
      final y2 = size.height - (i % 2 == 0 ? waveHeight * 0.8 : waveHeight * 0.5);

      wavePath.quadraticBezierTo(
          (x1 + x2) / 2,
          size.height - waveHeight * 1.2,
          x2,
          y2
      );
    }

    wavePath.lineTo(size.width, size.height);
    wavePath.close();

    final Gradient waveGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        secondaryColor.withOpacity(0.3),
        secondaryColor.withOpacity(0.1),
      ],
    );

    final wavePaint = Paint()
      ..shader = waveGradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawPath(wavePath, wavePaint);

    // Draw circles
    final random = math.Random(42); // Fixed seed for consistent pattern
    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 30 + 5;

      canvas.drawCircle(
        Offset(x, y),
        radius,
        circlePaint,
      );
    }

    // Add a few larger circles with gradient
    final List<Offset> largeCirclePositions = [
      Offset(size.width * 0.1, size.height * 0.1),
      Offset(size.width * 0.85, size.height * 0.2),
      Offset(size.width * 0.2, size.height * 0.85),
      Offset(size.width * 0.7, size.height * 0.75),
    ];

    for (final position in largeCirclePositions) {
      final circleRadius = size.width * 0.15;
      final Rect circleRect = Rect.fromCircle(
        center: position,
        radius: circleRadius,
      );

      final Gradient circleGradient = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          Colors.white.withOpacity(0.15),
          Colors.white.withOpacity(0.05),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      );

      paint.shader = circleGradient.createShader(circleRect);
      canvas.drawCircle(position, circleRadius, paint);
    }

    // Add subtle horizontal lines
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < size.height; i += 20) {
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(size.width, i.toDouble()),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}