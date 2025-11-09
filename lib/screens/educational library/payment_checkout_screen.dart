// lib/screens/payment_checkout_screen.dart
import 'package:agritech/screens/educational%20library/services/cart_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'model/ebook_model.dart';
import 'order_confirmation_screen.dart';

class PaymentCheckoutScreen extends StatefulWidget {
  final List<Ebook> ebooks; // List of ebooks to purchase
  final bool isFromCart; // Whether this came from cart checkout

  const PaymentCheckoutScreen({
    Key? key,
    required this.ebooks,
    this.isFromCart = false,
  }) : super(key: key);

  // Constructor for single ebook purchase
  PaymentCheckoutScreen.singleEbook({
    Key? key,
    required Ebook ebook,
  }) : this(
    key: key,
    ebooks: [ebook],
    isFromCart: false,
  );

  // Constructor for cart checkout
  PaymentCheckoutScreen.fromCart({
    Key? key,
    required List<Ebook> cartEbooks,
  }) : this(
    key: key,
    ebooks: cartEbooks,
    isFromCart: true,
  );

  @override
  State<PaymentCheckoutScreen> createState() => _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends State<PaymentCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedPaymentMethod = 'mobile_money';
  bool _isProcessing = false;

  double get _totalAmount => widget.ebooks.fold(0.0, (sum, ebook) =>
  sum + (double.tryParse(ebook.price.toString()) ?? 0.0));

  // Helper method to get full URL
  String _getFullUrl(String? path) {
    const String baseUrlImage = 'http://51.75.31.246:3000';

    if (path == null || path.trim().isEmpty) {
      return '';
    }

    // If it's already a full URL, return as is
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    // Normalize: replace backslashes with slashes and remove multiple slashes
    String normalizedPath = path
        .replaceAll('\\', '/')
        .replaceAll(RegExp(r'^/+'), '')      // remove leading slashes
        .replaceAll(RegExp(r'/+'), '/');     // collapse multiple slashes

    return '$baseUrlImage/$normalizedPath';
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Checkout',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOrderSummary(),
                    const SizedBox(height: 24),
                    _buildContactInformation(),
                    const SizedBox(height: 24),
                    _buildPaymentMethods(),
                    const SizedBox(height: 24),
                    _buildAdditionalNotes(),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Fixed value instead of AppConstants.borderRadius
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Order Summary',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87, // Fixed color instead of AppColorss.textPrimary
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Ebook items
            ...widget.ebooks.map((ebook) => _buildEbookItem(ebook)),

            const Divider(height: 24),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total (${widget.ebooks.length} item${widget.ebooks.length > 1 ? 's' : ''})',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87, // Fixed color
                  ),
                ),
                Text(
                  'XAF ${_totalAmount.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEbookItem(Ebook ebook) {
    // Use helper method instead of ApiService.getFullUrl
    final coverImageUrl = ebook.coverImage != null
        ? _getFullUrl(ebook.coverImage!)
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Cover image
          Container(
            width: 50,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: coverImageUrl != null && coverImageUrl.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: coverImageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: Icon(Icons.book, color: Colors.grey[400], size: 20),
                ),
              )
                  : Container(
                color: Colors.grey[200],
                child: Icon(Icons.book, color: Colors.grey[400], size: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Ebook details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ebook.title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87, // Fixed color
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (ebook.categoryName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    ebook.categoryName!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.blue[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Price
          Text(
            'XAF ${ebook.price}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInformation() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Fixed value
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.contact_mail, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Contact Information',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87, // Fixed color
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'your.email@example.com',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), // Fixed value
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email address';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                hintText: '+237 6XX XXX XXX',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), // Fixed value
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Address
            TextFormField(
              controller: _addressController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Delivery Address',
                hintText: 'Enter your full address for digital delivery confirmation',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), // Fixed value
                ),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your address';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Fixed value
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Payment Method',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87, // Fixed color
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildPaymentOption(
              value: 'mobile_money',
              title: 'Mobile Money',
              subtitle: 'MTN Mobile Money, Orange Money',
              icon: Icons.phone_android,
              color: Colors.orange,
            ),
            const SizedBox(height: 8),
            _buildPaymentOption(
              value: 'bank_transfer',
              title: 'Bank Transfer',
              subtitle: 'Direct bank transfer',
              icon: Icons.account_balance,
              color: Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildPaymentOption(
              value: 'card',
              title: 'Credit/Debit Card',
              subtitle: 'Visa, Mastercard',
              icon: Icons.credit_card,
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      borderRadius: BorderRadius.circular(12), // Fixed value
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12), // Fixed value
          border: Border.all(
            color: _selectedPaymentMethod == value ? color : Colors.grey[300]!,
            width: 2,
          ),
          color: _selectedPaymentMethod == value
              ? color.withOpacity(0.05)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87, // Fixed color
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black54, // Fixed color
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedPaymentMethod,
              onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalNotes() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Fixed value
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note_alt, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Additional Notes (Optional)',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87, // Fixed color
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Any special instructions or notes for your order...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), // Fixed value
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87, // Fixed color
                  ),
                ),
                Text(
                  'XAF ${_totalAmount.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _processPayment,
                icon: _isProcessing
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Icon(Icons.lock),
                label: Text(
                  _isProcessing ? 'Processing...' : 'Complete Purchase',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Fixed value
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      // If from cart, clear cart items
      if (widget.isFromCart) {
        for (final ebook in widget.ebooks) {
          await CartService.instance.removeFromCart(ebook.id.toString());
        }
      }

      // Navigate to order confirmation
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderConfirmationScreen(
              ebooks: widget.ebooks,
              orderDetails: {
                'email': _emailController.text,
                'phone': _phoneController.text,
                'address': _addressController.text,
                'paymentMethod': _selectedPaymentMethod,
                'note': _noteController.text,
                'totalAmount': _totalAmount,
                'orderId': 'ORD${DateTime.now().millisecondsSinceEpoch}',
              },
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Payment failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Payment Error',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}