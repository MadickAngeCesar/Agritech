import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class ForgotResetScreen extends StatefulWidget {
  const ForgotResetScreen({super.key});

  @override
  State<ForgotResetScreen> createState() => _ForgotResetScreenState();
}

class _ForgotResetScreenState extends State<ForgotResetScreen> {
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

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
        _showSnack('OTP sent');
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
          _showSnack('OTP verified. You can now reset your password');
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

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'resetToken': _resetToken, 'newPassword': newPass}),
      );

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        _showSnack('Password reset successful');
        Navigator.pop(context);
      } else {
        _showSnack(data['message']);
      }
    } catch (_) {
      _showSnack('Reset failed');
    }
  }

  Widget _buildInput(String label, TextEditingController controller, IconData icon, {bool obscure = false, VoidCallback? toggle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            suffixIcon: toggle != null
                ? IconButton(
              icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
              onPressed: toggle,
            )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: Colors.green[700],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: _loading ? null : onPressed,
        child: _loading
            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
            : Text(label, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reset Password', style: GoogleFonts.poppins()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            _buildInput('Phone Number', _phoneController, Icons.phone),
            const SizedBox(height: 16),
            if (!_otpSent)
              _buildButton('Send OTP', _sendOtp)
            else if (!_otpVerified) ...[
              _buildInput('Enter OTP', _otpController, Icons.password),
              const SizedBox(height: 16),
              _buildButton('Verify OTP', _verifyOtp),
            ] else ...[
              _buildInput('New Password', _newPasswordController, Icons.lock,
                  obscure: _obscureNew,
                  toggle: () => setState(() => _obscureNew = !_obscureNew)),
              const SizedBox(height: 16),
              _buildInput('Confirm Password', _confirmPasswordController, Icons.lock,
                  obscure: _obscureConfirm,
                  toggle: () => setState(() => _obscureConfirm = !_obscureConfirm)),
              const SizedBox(height: 24),
              _buildButton('Reset Password', _resetPassword),
            ],
          ],
        ),
      ),
    );
  }
}
