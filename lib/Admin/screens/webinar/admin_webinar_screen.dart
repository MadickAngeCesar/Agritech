import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';

class AdminWebinarManagementScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> userData;

  const AdminWebinarManagementScreen({
    super.key,
    required this.token,
    required this.userData,
  });

  @override
  State<AdminWebinarManagementScreen> createState() => _AdminWebinarManagementScreenState();
}

class _AdminWebinarManagementScreenState extends State<AdminWebinarManagementScreen> {
  List<dynamic> pendingRequests = [];
  bool isLoading = true;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  DateTime? selectedDate;
  File? selectedImage;

  @override
  void initState() {
    super.initState();
    fetchPendingRequests();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> fetchPendingRequests() async {
    setState(() => isLoading = true);
    final url = Uri.parse('http://51.75.31.246:3000/api/webinars/requests/pending');

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer ${widget.token}',
    });

    if (response.statusCode == 200) {
      setState(() {
        pendingRequests = json.decode(response.body)['requests'];
        isLoading = false;
      });
    } else {
      print('❌ Failed to load requests: ${response.body}');
      setState(() => isLoading = false);
    }
  }

  Future<void> approveRequest(int requestId) async {
    final url = Uri.parse('http://51.75.31.246:3000/api/webinars/approve/$requestId');

    final response = await http.post(url, headers: {
      'Authorization': 'Bearer ${widget.token}',
    });

    if (response.statusCode == 201) {
      _showSuccessSnackBar('✅ Webinar approved and created!');
      fetchPendingRequests();
    } else {
      print('❌ Approval failed: ${response.body}');
      _showErrorSnackBar('❌ Failed to approve request');
    }
  }

  Future<void> rejectRequest(int requestId, String reason) async {
    final url = Uri.parse('http://51.75.31.246:3000/api/webinars/reject/$requestId');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: json.encode({'reason': reason}),
    );

    if (response.statusCode == 200) {
      _showSuccessSnackBar('Request rejected successfully');
      fetchPendingRequests();
    } else {
      print('❌ Rejection failed: ${response.body}');
      _showErrorSnackBar('❌ Failed to reject request');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void showRejectionDialog(int requestId) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Reject Webinar Request',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: _getResponsiveFontSize(context, 20),
            color: Colors.red[700],
          ),
        ),
        content: Container(
          constraints: BoxConstraints(
            maxWidth: _getResponsiveWidth(context, 400),
          ),
          child: TextFormField(
            controller: reasonController,
            maxLines: 4,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              labelText: 'Reason for rejection',
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red[400]!, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isNotEmpty) {
                Navigator.pop(context);
                rejectRequest(requestId, reason);
              } else {
                _showErrorSnackBar('Please enter a reason.');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
            ),
            child: Text(
              'Reject',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showCreateWebinarDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Create New Webinar',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: _getResponsiveFontSize(context, 22),
            color: Colors.blue[700],
          ),
        ),
        content: Container(
          constraints: BoxConstraints(
            maxWidth: _getResponsiveWidth(context, 500),
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField(
                  controller: titleController,
                  label: 'Webinar Title',
                  icon: Icons.title,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: descriptionController,
                  label: 'Description',
                  icon: Icons.description,
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                _buildImagePickerButton(),
                const SizedBox(height: 16),
                _buildDateTimePickerButton(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearForm();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: createWebinar,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
            ),
            child: Text(
              'Create Webinar',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue[600]),
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          color: Colors.grey[600],
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[400]!, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildImagePickerButton() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
      ),
      child: ListTile(
        leading: Icon(
          selectedImage != null ? Icons.check_circle : Icons.image,
          color: selectedImage != null ? Colors.green : Colors.blue[600],
        ),
        title: Text(
          selectedImage != null ? 'Image Selected' : 'Pick Cover Image',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            color: selectedImage != null ? Colors.green : Colors.grey[700],
          ),
        ),
        subtitle: selectedImage != null
            ? Text(
          selectedImage!.path.split('/').last,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w400,
            fontSize: 12,
          ),
        )
            : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
          if (picked != null) {
            setState(() {
              selectedImage = File(picked.path);
            });
          }
        },
      ),
    );
  }

  Widget _buildDateTimePickerButton() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
      ),
      child: ListTile(
        leading: Icon(
          selectedDate != null ? Icons.check_circle : Icons.calendar_today,
          color: selectedDate != null ? Colors.green : Colors.blue[600],
        ),
        title: Text(
          selectedDate != null ? 'Date & Time Selected' : 'Pick Date & Time',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            color: selectedDate != null ? Colors.green : Colors.grey[700],
          ),
        ),
        subtitle: selectedDate != null
            ? Text(
          '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year} at ${selectedDate!.hour}:${selectedDate!.minute.toString().padLeft(2, '0')}',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w400,
            fontSize: 12,
          ),
        )
            : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: DateTime.now().add(const Duration(days: 1)),
            firstDate: DateTime.now(),
            lastDate: DateTime(2100),
          );
          if (date != null) {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (time != null) {
              setState(() {
                selectedDate = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                );
              });
            }
          }
        },
      ),
    );
  }

  void _clearForm() {
    titleController.clear();
    descriptionController.clear();
    selectedDate = null;
    selectedImage = null;
  }

  Future<void> createWebinar() async {
    if (titleController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty ||
        selectedDate == null) {
      _showErrorSnackBar('Please fill all required fields');
      return;
    }

    final url = Uri.parse('http://51.75.31.246:3000/api/webinars');
    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer ${widget.token}';

    request.fields['title'] = titleController.text.trim();
    request.fields['description'] = descriptionController.text.trim();
    request.fields['date'] = selectedDate!.toIso8601String();

    if (selectedImage != null) {
      request.files.add(await http.MultipartFile.fromPath('image', selectedImage!.path));
    }

    final response = await request.send();

    if (response.statusCode == 201) {
      Navigator.pop(context);
      _clearForm();
      _showSuccessSnackBar('✅ Webinar created successfully');
    } else {
      print('❌ Create failed: ${response.statusCode}');
      _showErrorSnackBar('❌ Failed to create webinar');
    }
  }

  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return baseSize * 0.9;
    } else if (screenWidth < 1200) {
      return baseSize;
    } else {
      return baseSize * 1.1;
    }
  }

  double _getResponsiveWidth(BuildContext context, double baseWidth) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth > baseWidth ? baseWidth : screenWidth * 0.9;
  }

  int _getCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) return 1;
    if (screenWidth < 900) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[800],
        title: Text(
          'Webinar Management',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: _getResponsiveFontSize(context, 20),
            color: Colors.grey[800],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: showCreateWebinarDialog,
              icon: const Icon(Icons.add, size: 20),
              label: Text(
                isWideScreen ? 'Create Webinar' : 'Create',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                padding: EdgeInsets.symmetric(
                  horizontal: isWideScreen ? 20 : 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchPendingRequests,
        child: isLoading
            ? const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        )
            : pendingRequests.isEmpty
            ? _buildEmptyState()
            : _buildRequestsList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Pending Requests',
            style: GoogleFonts.poppins(
              fontSize: _getResponsiveFontSize(context, 24),
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All webinar requests have been processed',
            style: GoogleFonts.poppins(
              fontSize: _getResponsiveFontSize(context, 16),
              fontWeight: FontWeight.w400,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList() {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > 1200) {
      // Desktop layout - Grid view
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _getCrossAxisCount(context),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: pendingRequests.length,
          itemBuilder: (context, index) => _buildRequestCard(pendingRequests[index]),
        ),
      );
    } else {
      // Mobile/Tablet layout - List view
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pendingRequests.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildRequestCard(pendingRequests[index]),
        ),
      );
    }
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;

    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey[50]!],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.video_call,
                      color: Colors.blue[600],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child:                     Text(
                      request['title'] ?? 'Untitled Webinar',
                      style: GoogleFonts.poppins(
                        fontSize: _getResponsiveFontSize(context, isCompact ? 16 : 18),
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                request['description'] ?? 'No description provided',
                style: GoogleFonts.poppins(
                  fontSize: _getResponsiveFontSize(context, 14),
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                icon: Icons.person,
                label: 'Requested by',
                value: request['requestedBy']?['full_name'] ?? 'Unknown',
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                icon: Icons.schedule,
                label: 'Preferred Date',
                value: request['preferred_date'] ?? 'Not specified',
              ),
              if (request['image_url'] != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.network(
                      request['image_url'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey[400],
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _buildActionButtons(request['id'], isCompact),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[500],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[600],
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(int requestId, bool isCompact) {
    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: () => approveRequest(requestId),
            icon: const Icon(Icons.check, size: 18),
            label: Text(
              'Approve',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => showRejectionDialog(requestId),
            icon: const Icon(Icons.close, size: 18),
            label: Text(
              'Reject',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red[600],
              side: BorderSide(color: Colors.red[300]!),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => approveRequest(requestId),
              icon: const Icon(Icons.check, size: 18),
              label: Text(
                'Approve',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => showRejectionDialog(requestId),
              icon: const Icon(Icons.close, size: 18),
              label: Text(
                'Reject',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red[600],
                side: BorderSide(color: Colors.red[300]!),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      );
    }
  }
}