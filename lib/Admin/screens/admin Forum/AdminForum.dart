import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class AdminForumScreen extends StatefulWidget {
  const AdminForumScreen({Key? key}) : super(key: key);

  @override
  State<AdminForumScreen> createState() => _AdminForumScreenState();
}

class _AdminForumScreenState extends State<AdminForumScreen> with SingleTickerProviderStateMixin {
  List<dynamic> messages = [];
  bool isLoading = false;
  int page = 1;
  bool hasMore = true;
  String searchQuery = "";
  late AnimationController _animationController;
  final TextEditingController _newMessageController = TextEditingController();
  File? _selectedImage;
  bool _isComposingMessage = false;

  final String baseUrl = 'http://51.75.31.246:3000';
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    fetchMessages();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8 &&
          !isLoading &&
          hasMore) {
        fetchMessages();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    searchController.dispose();
    _newMessageController.dispose();
    super.dispose();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<void> fetchMessages({bool reset = false}) async {
    if (isLoading) return;
    setState(() => isLoading = true);

    final token = await getToken();
    if (reset) {
      page = 1;
      hasMore = true;
      messages.clear();
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/forum?page=$page&limit=10&search=$searchQuery'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newMessages = List.from(data['messages']);
        setState(() {
          messages.addAll(newMessages);
          isLoading = false;
          hasMore = newMessages.length == 10;
          page++;
        });
      } else {
        _showErrorSnackBar("Failed to load messages");
        setState(() => isLoading = false);
      }
    } catch (e) {
      _showErrorSnackBar("Network error: ${e.toString()}");
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteMessage(int messageId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this message?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _showLoadingDialog("Deleting message...");

              final token = await getToken();
              try {
                final response = await http.delete(
                  Uri.parse('$baseUrl/api/admin/forum/$messageId'),
                  headers: {'Authorization': 'Bearer $token'},
                );

                Navigator.pop(context); // Close loading dialog

                if (response.statusCode == 200) {
                  _showSuccessSnackBar("Message deleted successfully");
                  fetchMessages(reset: true);
                } else {
                  _showErrorSnackBar("Failed to delete message");
                }
              } catch (e) {
                Navigator.pop(context); // Close loading dialog
                _showErrorSnackBar("Network error: ${e.toString()}");
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("DELETE"),
          ),
        ],
      ),
    );
  }

  Future<void> postMessage(String text, File? imageFile) async {
    if (text.trim().isEmpty && imageFile == null) {
      _showErrorSnackBar("Message cannot be empty");
      return;
    }

    _showLoadingDialog("Posting message...");

    final token = await getToken();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/admin/forum'));
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['text'] = text;

    if (imageFile != null) {
      final image = await http.MultipartFile.fromPath('image', imageFile.path);
      request.files.add(image);
    }

    try {
      final response = await request.send();
      Navigator.pop(context); // Close loading dialog

      if (response.statusCode == 201) {
        _showSuccessSnackBar("Message posted successfully");
        fetchMessages(reset: true);
        setState(() {
          _isComposingMessage = false;
          _selectedImage = null;
          _newMessageController.clear();
        });
      } else {
        _showErrorSnackBar("Failed to post message");
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showErrorSnackBar("Network error: ${e.toString()}");
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text(message),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(8),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 10),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(8),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5,
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 8,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 100,
                      height: 8,
                      color: Colors.white,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageComposer() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isComposingMessage ? 200 : 0,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "New Message",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _isComposingMessage = false;
                        _selectedImage = null;
                        _newMessageController.clear();
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _newMessageController,
                decoration: InputDecoration(
                  hintText: 'Type your message here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  isDense: true,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery);
                      if (picked != null) {
                        setState(() => _selectedImage = File(picked.path));
                      }
                    },
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _selectedImage != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                          : const Icon(Icons.image, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => postMessage(_newMessageController.text, _selectedImage),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("POST"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageItem(dynamic message, int index) {
    final user = message['user'];
    final fullName = user != null ? user['full_name'] : 'Unknown';
    final profileImage = user != null ? user['profile_image'] : null;
    final DateTime createdAt = message['created_at'] != null
        ? DateTime.parse(message['created_at'])
        : DateTime.now();
    final timeAgo = timeago.format(createdAt);

    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 375),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Card(
            elevation: 0,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: profileImage != null
                            ? CachedNetworkImageProvider(
                            profileImage.startsWith('http')
                                ? profileImage
                                : '$baseUrl$profileImage')
                            : null,
                        child: profileImage == null
                            ? const Icon(Icons.person, color: Colors.grey, size: 20)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              timeAgo,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        onPressed: () => deleteMessage(message['id']),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  if (message['text'] != null && message['text'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: Text(
                        message['text'],
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  if (message['image_url'] != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: message['image_url'].toString().startsWith('http')
                            ? message['image_url']
                            : '$baseUrl${message['image_url']}',
                        placeholder: (context, url) => Container(
                          height: 180,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 180,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, size: 40),
                        ),
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Admin Forum",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    top: 20,
                    left: 20,
                    right: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Search Messages",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Enter search keywords...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                        autofocus: true,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            searchQuery = searchController.text.trim();
                          });
                          fetchMessages(reset: true);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text("SEARCH"),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          ),
          if (searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  searchQuery = "";
                  searchController.clear();
                });
                fetchMessages(reset: true);
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isComposingMessage = true;
          });
        },
        elevation: 4,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (searchQuery.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.amber[100],
              child: Row(
                children: [
                  const Icon(Icons.filter_list, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filtered by: "$searchQuery"',
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                if (isLoading && messages.isEmpty)
                  _buildShimmerLoading()
                else
                  RefreshIndicator(
                    onRefresh: () => fetchMessages(reset: true),
                    child: messages.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.forum_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            searchQuery.isEmpty
                                ? "No messages yet"
                                : "No results found for \"$searchQuery\"",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (searchQuery.isNotEmpty)
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  searchQuery = "";
                                  searchController.clear();
                                });
                                fetchMessages(reset: true);
                              },
                              child: const Text("Clear Search"),
                            ),
                        ],
                      ),
                    )
                        : AnimationLimiter(
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: messages.length + (hasMore ? 1 : 0),
                        padding: EdgeInsets.only(
                            top: 8,
                            bottom: _isComposingMessage ? 208 : 80
                        ),
                        itemBuilder: (context, index) {
                          if (index == messages.length) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ),
                            );
                          }
                          return _buildMessageItem(messages[index], index);
                        },
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildMessageComposer(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}