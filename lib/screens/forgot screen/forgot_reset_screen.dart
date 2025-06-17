import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class ForgotResetScreen extends StatefulWidget {
  const ForgotResetScreen({super.key});

  @override
  State<ForgotResetScreen> createState() => _ForgotResetScreenState();
}

class _ForgotResetScreenState extends State<ForgotResetScreen>
    with TickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _resetToken;
  bool _otpSent = false;
  bool _otpVerified = false;
  bool _loading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  final String baseUrl = 'http://10.0.2.2:3000/api/auth';

  AnimationController? _fadeController;
  AnimationController? _slideController;
  AnimationController? _progressController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _progressAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController!, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController!, curve: Curves.easeOutCubic));

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController!, curve: Curves.easeInOut),
    );

    _fadeController!.forward();
    _slideController!.forward();
  }

  @override
  void dispose() {
    _fadeController?.dispose();
    _slideController?.dispose();
    _progressController?.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                msg,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return _showSnack('Enter your phone number');
    setState(() => _loading = true);

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        setState(() => _otpSent = true);
        _updateProgress(0.33);
        _showSnack('OTP sent successfully!', isError: false);
      } else {
        _showSnack(data['message']);
      }
    } catch (_) {
      _showSnack('Failed to send OTP');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();
    if (otp.isEmpty) return _showSnack('Enter OTP');
    setState(() => _loading = true);

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'otp': otp}),
      );

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        final tokenRes = await http.post(
          Uri.parse('$baseUrl/forgot-password'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'identifier': phone}),
        );
        final tokenData = jsonDecode(tokenRes.body);
        if (tokenRes.statusCode == 200) {
          _resetToken = tokenData['resetToken'];
          setState(() => _otpVerified = true);
          _updateProgress(0.66);
          _showSnack('OTP verified successfully!', isError: false);
        } else {
          _showSnack(tokenData['message']);
        }
      } else {
        _showSnack(data['message']);
      }
    } catch (_) {
      _showSnack('OTP verification failed');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (newPass != confirmPass || newPass.length < 6) {
      return _showSnack('Passwords must match and be at least 6 characters');
    }

    if (_resetToken == null) return;

    setState(() => _loading = true);

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'resetToken': _resetToken, 'newPassword': newPass}),
      );

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        _updateProgress(1.0);
        _showSnack('Password reset successful!', isError: false);
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pop(context);
      } else {
        _showSnack(data['message']);
      }
    } catch (_) {
      _showSnack('Reset failed');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _updateProgress(double value) {
    _progressController?.animateTo(value);
  }

  int get _currentStep {
    if (!_otpSent) return 1;
    if (!_otpVerified) return 2;
    return 3;
  }

  double get _progressValue {
    if (!_otpSent) return 0.33;
    if (!_otpVerified) return 0.66;
    return 1.0;
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepIndicator(1, 'Phone', _currentStep >= 1),
              _buildProgressLine(_currentStep >= 2),
              _buildStepIndicator(2, 'Verify', _currentStep >= 2),
              _buildProgressLine(_currentStep >= 3),
              _buildStepIndicator(3, 'Reset', _currentStep >= 3),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _progressAnimation ?? AlwaysStoppedAnimation(0.0),
            builder: (context, child) {
              return LinearProgressIndicator(
                value: (_progressAnimation?.value ?? 0.0) * _progressValue,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                minHeight: 6,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isActive) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.green.shade600 : Colors.grey.shade300,
            boxShadow: isActive
                ? [
              BoxShadow(
                color: Colors.green.shade200,
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ]
                : null,
          ),
          child: Center(
            child: isActive
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
              step.toString(),
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: isActive ? Colors.green.shade600 : Colors.grey.shade500,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.green.shade600 : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    String title, subtitle;
    IconData icon;

    if (!_otpSent) {
      title = 'Forgot Password?';
      subtitle = 'Enter your phone number to receive an OTP';
      icon = Icons.phone_android_rounded;
    } else if (!_otpVerified) {
      title = 'Verify OTP';
      subtitle = 'Enter the verification code sent to your phone';
      icon = Icons.security_rounded;
    } else {
      title = 'Create New Password';
      subtitle = 'Enter your new password to complete the reset';
      icon = Icons.lock_reset_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.shade200,
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(
      String label,
      TextEditingController controller,
      IconData icon, {
        bool obscure = false,
        VoidCallback? toggle,
        TextInputType? keyboardType,
        String? hint,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              obscureText: obscure,
              keyboardType: keyboardType ?? TextInputType.text,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.green.shade600, size: 20),
                ),
                suffixIcon: toggle != null
                    ? IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey.shade500,
                  ),
                  onPressed: toggle,
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.green.shade400, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String label, VoidCallback onPressed, {bool isPrimary = true}) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: isPrimary
            ? LinearGradient(
          colors: [Colors.green.shade500, Colors.green.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        color: !isPrimary ? Colors.grey.shade100 : null,
        boxShadow: [
          BoxShadow(
            color: isPrimary ? Colors.green.shade200 : Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _loading ? null : onPressed,
        child: _loading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isPrimary ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    if (!_otpSent) {
      return Column(
        children: [
          _buildInput(
            'Phone Number',
            _phoneController,
            Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            hint: 'Enter your phone number',
          ),
          const SizedBox(height: 20),
          _buildButton('Send OTP', _sendOtp),
        ],
      );
    } else if (!_otpVerified) {
      return Column(
        children: [
          _buildInput(
            'Verification Code',
            _otpController,
            Icons.security_rounded,
            keyboardType: TextInputType.number,
            hint: 'Enter 6-digit OTP',
          ),
          const SizedBox(height: 20),
          _buildButton('Verify OTP', _verifyOtp),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _loading ? null : _sendOtp,
            child: Text(
              'Didn\'t receive OTP? Resend',
              style: GoogleFonts.poppins(
                color: Colors.green.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          _buildInput(
            'New Password',
            _newPasswordController,
            Icons.lock_rounded,
            obscure: _obscureNew,
            toggle: () => setState(() => _obscureNew = !_obscureNew),
            hint: 'Enter new password',
          ),
          _buildInput(
            'Confirm Password',
            _confirmPasswordController,
            Icons.lock_outline_rounded,
            obscure: _obscureConfirm,
            toggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
            hint: 'Confirm new password',
          ),
          const SizedBox(height: 20),
          _buildButton('Reset Password', _resetPassword),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Reset Password',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.grey.shade600),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _fadeAnimation == null
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
        opacity: _fadeAnimation!,
        child: _slideAnimation == null
            ? const Center(child: CircularProgressIndicator())
            : SlideTransition(
          position: _slideAnimation!,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildProgressIndicator(),
                const SizedBox(height: 20),
                _buildHeaderSection(),
                const SizedBox(height: 30),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _buildFormContent(),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}