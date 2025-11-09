// lib/screens/order_confirmation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'model/ebook_model.dart';


class OrderConfirmationScreen extends StatelessWidget {
  final List<Ebook> ebooks;
  final Map<String, dynamic> orderDetails;

  const OrderConfirmationScreen({
    Key? key,
    required this.ebooks,
    required this.orderDetails,
  }) : super(key: key);

  // Helper method to get full URL if ApiService.getFullUrl doesn't work
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Order Confirmation',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSuccessHeader(),
            const SizedBox(height: 24),
            _buildOrderSummary(),
            const SizedBox(height: 16),
            _buildOrderDetails(),
            const SizedBox(height: 16),
            _buildPurchasedItems(),
            const SizedBox(height: 24),
            _buildNextSteps(),
            const SizedBox(height: 24),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Fixed value instead of AppConstants.borderRadius
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12), // Fixed value
          gradient: LinearGradient(
            colors: [Colors.green[400]!, Colors.green[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green[600],
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Order Successful!',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thank you for your purchase. Your ebooks will be delivered to your email shortly.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
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

            _buildSummaryRow('Order ID:', orderDetails['orderId'] ?? 'N/A'),
            _buildSummaryRow('Date:', _formatDate(DateTime.now())),
            _buildSummaryRow('Items:', '${ebooks.length} ebook${ebooks.length > 1 ? 's' : ''}'),
            _buildSummaryRow('Payment Method:', _getPaymentMethodName(orderDetails['paymentMethod'])),

            const Divider(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount:',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87, // Fixed color
                  ),
                ),
                Text(
                  'XAF ${orderDetails['totalAmount']?.toStringAsFixed(0) ?? '0'}',
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

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black54, // Fixed color instead of AppColorss.textSecondary
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87, // Fixed color
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails() {
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
                  'Delivery Information',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87, // Fixed color
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildDetailRow(Icons.email, 'Email:', orderDetails['email'] ?? 'N/A'),
            _buildDetailRow(Icons.phone, 'Phone:', orderDetails['phone'] ?? 'N/A'),
            _buildDetailRow(Icons.location_on, 'Address:', orderDetails['address'] ?? 'N/A'),

            if (orderDetails['note'] != null && orderDetails['note'].toString().isNotEmpty)
              _buildDetailRow(Icons.note, 'Note:', orderDetails['note']),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black54, // Fixed color
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87, // Fixed color
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchasedItems() {
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
                Icon(Icons.library_books, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Purchased Items',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87, // Fixed color
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ...ebooks.map((ebook) => _buildPurchasedEbookItem(ebook)),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchasedEbookItem(Ebook ebook) {
    // Use helper method instead of ApiService.getFullUrl
    final coverImageUrl = ebook.coverImage != null
        ? _getFullUrl(ebook.coverImage!)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12), // Fixed value
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
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
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Purchased',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Price and download button
          Column(
            children: [
              Text(
                'XAF ${ebook.price}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _downloadEbook(ebook),
                icon: const Icon(Icons.download, size: 16),
                label: Text(
                  'Download',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextSteps() {
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
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'What\'s Next?',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87, // Fixed color
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildNextStepItem(
              icon: Icons.email,
              title: 'Check Your Email',
              description: 'Download links will be sent to ${orderDetails['email'] ?? 'your email'} within 5 minutes.',
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildNextStepItem(
              icon: Icons.download,
              title: 'Download Your Ebooks',
              description: 'Click the download buttons above or use the links in your email.',
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildNextStepItem(
              icon: Icons.support,
              title: 'Need Help?',
              description: 'Contact our support team if you have any issues accessing your purchases.',
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextStepItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87, // Fixed color
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.black54, // Fixed color
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Copy Order ID button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _copyOrderId(context),
            icon: const Icon(Icons.copy),
            label: Text(
              'Copy Order ID',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: const BorderSide(color: Colors.blue),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // Fixed value
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Continue Shopping button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _continueShopping(context),
            icon: const Icon(Icons.shopping_bag),
            label: Text(
              'Continue Shopping',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // Fixed value
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _downloadEbook(Ebook ebook) {
    // Implement download functionality
    // This could open a URL or trigger a download
    print('Downloading ebook: ${ebook.title}');
    // You can implement actual download logic here
  }

  void _copyOrderId(BuildContext context) {
    final orderId = orderDetails['orderId'] ?? '';
    Clipboard.setData(ClipboardData(text: orderId));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Order ID copied to clipboard',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Fixed value
        ),
      ),
    );
  }

  void _continueShopping(BuildContext context) {
    // Navigate back to the main screen or ebook library
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _getPaymentMethodName(String? method) {
    switch (method) {
      case 'mobile_money':
        return 'Mobile Money';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'card':
        return 'Credit/Debit Card';
      default:
        return 'Unknown';
    }
  }
}