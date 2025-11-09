import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ForumScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;

  const ForumScreen({
    super.key,
    required this.userData,
    required this.token,
  });

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> with SingleTickerProviderStateMixin {
  List<dynamic> posts = [];
  bool isLoading = true;
  late AnimationController _animationController;

  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  final TextEditingController _postController = TextEditingController();

  final String baseUrl = 'http://51.75.31.246:3000';

  // AgriTech Color Palette
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color accentGreen = Color(0xFF66BB6A);
  static const Color backgroundGreen = Color(0xFFF1F8E9);
  static const Color cardGreen = Color(0xFFE8F5E8);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    fetchPosts();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _postController.dispose();
    super.dispose();
  }

  // Helper method to construct proper image URLs
  String getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';

    // Clean the input path
    String cleanPath = imagePath.trim();

    // Debug logging
    print('🔍 Original image path: "$imagePath"');

    // If the path already contains the full URL, return as is but validate it
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      // Check for doubled base URLs and fix them
      if (cleanPath.contains('$baseUrl$baseUrl')) {
        cleanPath = cleanPath.replaceFirst('$baseUrl$baseUrl', baseUrl);
        print('🔧 Fixed doubled base URL: "$cleanPath"');
      }

      // Check for malformed URLs like "http://51.75.31.246:3000uploads/"
      if (cleanPath.contains('${baseUrl}uploads/') && !cleanPath.contains('$baseUrl/uploads/')) {
        cleanPath = cleanPath.replaceFirst('${baseUrl}uploads/', '$baseUrl/uploads/');
        print('🔧 Fixed missing slash in uploads: "$cleanPath"');
      }

      // Fix port issues like "http://51.75.31.246:30001750101703312"
      RegExp portIssueRegex = RegExp(r'http://[\d\.]+:3000(\d+.*)');
      if (portIssueRegex.hasMatch(cleanPath)) {
        cleanPath = cleanPath.replaceAllMapped(portIssueRegex, (match) {
          String filename = match.group(1) ?? '';
          String result = '$baseUrl/uploads/$filename';
          print('🔧 Fixed port issue: "${match.group(0)}" -> "$result"');
          return result;
        });
      }

      print('✅ Final URL: "$cleanPath"');
      return cleanPath;
    }

    // Remove leading slash if present to avoid double slashes
    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }

    // Construct the full URL
    String finalUrl = '$baseUrl/$cleanPath';
    print('✅ Constructed URL: "$finalUrl"');
    return finalUrl;
  }

  Future<void> fetchPosts() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/posts'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      final data = jsonDecode(res.body);
      if (data['success']) {
        setState(() {
          posts = data['data'];
        });
        _animationController.forward();
      } else {
        showError('Failed to load community posts');
      }
    } catch (e) {
      showError('Connection error: ${e.toString()}');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> createPost() async {
    final text = _postController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    try {
      final uri = Uri.parse('$baseUrl/api/posts');
      final req = http.MultipartRequest('POST', uri);
      req.headers['Authorization'] = 'Bearer ${widget.token}';

      req.fields['user_id'] = widget.userData['id'].toString();
      req.fields['text'] = text;

      if (_selectedImage != null) {
        req.files.add(await http.MultipartFile.fromPath(
          'image',
          _selectedImage!.path,
        ));
      }

      final res = await req.send();
      if (res.statusCode == 201) {
        _postController.clear();
        setState(() => _selectedImage = null);
        showSuccess('Post shared with the community! 🌱');
        fetchPosts();
      } else {
        final body = await res.stream.bytesToString();
        showError('Failed to share post: $body');
      }
    } catch (e) {
      showError(e.toString());
    }
  }

  Future<void> createComment(int postId, String text) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/comments'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': widget.userData['id'],
          'post_id': postId,
          'text': text,
        }),
      );
      if (res.statusCode == 201) {
        showSuccess('Comment added! 💬');
        fetchPosts();
      } else {
        showError('Failed to add comment');
      }
    } catch (e) {
      showError(e.toString());
    }
  }

  Future<void> likePost(int postId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/posts/$postId/like'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'user_id': widget.userData['id']}),
      );
      if (res.statusCode == 200) {
        fetchPosts();
      } else {
        showError('Failed to like post');
      }
    } catch (e) {
      showError(e.toString());
    }
  }

  Future<void> likeComment(int commentId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/comments/$commentId/like'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'user_id': widget.userData['id']}),
      );
      if (res.statusCode == 200) {
        fetchPosts();
      } else {
        showError('Failed to like comment');
      }
    } catch (e) {
      showError(e.toString());
    }
  }

  Future<void> pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  String formatTime(String timestamp) {
    final date = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  Widget buildCreatePostCard() {
    final userProfileImageUrl = getImageUrl(widget.userData['profile_image']);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_selectedImage != null)
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Image.file(
                      _selectedImage!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedImage = null),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: cardGreen,
                      child: userProfileImageUrl.isNotEmpty
                          ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: userProfileImageUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Icon(Icons.agriculture, color: primaryGreen, size: 20),
                          errorWidget: (_, __, ___) => Icon(Icons.agriculture, color: primaryGreen, size: 20),
                        ),
                      )
                          : Icon(Icons.agriculture, color: primaryGreen, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: backgroundGreen,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: TextField(
                          controller: _postController,
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: "Share your farming insights...",
                            hintStyle: TextStyle(color: Colors.grey.shade600),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.photo_camera,
                      label: "Photo",
                      color: accentGreen,
                      onTap: pickImage,
                    ),

                    _buildActionButton(
                      icon: Icons.send,
                      label: "Share",
                      color: primaryGreen,
                      onTap: createPost,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPostCard(dynamic post) {
    final user = post['User'];
    final comments = post['Comments'] ?? [];
    final commentController = TextEditingController();

    final userProfileImageUrl = getImageUrl(user['profile_image']);
    final postImageUrl = getImageUrl(post['image_url']);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: cardGreen,
                  child: userProfileImageUrl.isNotEmpty
                      ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: userProfileImageUrl,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Icon(Icons.agriculture, color: primaryGreen),
                      errorWidget: (_, __, ___) => Icon(Icons.agriculture, color: primaryGreen),
                    ),
                  )
                      : Icon(Icons.agriculture, color: primaryGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['full_name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        formatTime(post['createdAt']),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: backgroundGreen,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.eco,
                    color: primaryGreen,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),

          // Content
          if (post['text'] != null && post['text'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                post['text'],
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),

          if (post['text'] != null && post['text'].toString().isNotEmpty)
            const SizedBox(height: 12),

          // Image
          if (postImageUrl.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: postImageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 200,
                    color: backgroundGreen,
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    child: Icon(Icons.broken_image, color: Colors.grey.shade400),
                  ),
                ),
              ),
            ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _buildInteractionButton(
                  icon: Icons.favorite,
                  count: post['likes_count'],
                  color: Colors.red.shade400,
                  onTap: () => likePost(post['id']),
                ),
                const SizedBox(width: 20),
                _buildInteractionButton(
                  icon: Icons.chat_bubble_outline,
                  count: comments.length,
                  color: primaryGreen,
                  onTap: () {},
                ),
                const Spacer(),
                Icon(Icons.share_outlined, color: Colors.grey.shade500),
              ],
            ),
          ),

          // Comments Section
          if (comments.isNotEmpty) ...[
            Container(
              width: double.infinity,
              height: 1,
              color: Colors.grey.shade200,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Comments",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...comments.take(3).map<Widget>((c) {
                    final commentUser = c['User'];
                    final commentUserProfileImageUrl = getImageUrl(commentUser['profile_image']);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: backgroundGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: cardGreen,
                            child: commentUserProfileImageUrl.isNotEmpty
                                ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: commentUserProfileImageUrl,
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Icon(Icons.person, size: 16, color: primaryGreen),
                                errorWidget: (_, __, ___) => Icon(Icons.person, size: 16, color: primaryGreen),
                              ),
                            )
                                : Icon(Icons.person, size: 16, color: primaryGreen),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  commentUser['full_name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  c['text'],
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                '${c['likes_count']}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              InkWell(
                                onTap: () => likeComment(c['id']),
                                child: Icon(
                                  Icons.thumb_up,
                                  size: 16,
                                  color: accentGreen,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  if (comments.length > 3)
                    TextButton(
                      onPressed: () {}, // TODO: Show all comments
                      child: Text(
                        "View ${comments.length - 3} more comments",
                        style: TextStyle(color: primaryGreen),
                      ),
                    ),
                ],
              ),
            ),
          ],

          // Add Comment
          Container(
            width: double.infinity,
            height: 1,
            color: Colors.grey.shade200,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: cardGreen,
                  child: getImageUrl(widget.userData['profile_image']).isNotEmpty
                      ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: getImageUrl(widget.userData['profile_image']),
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Icon(Icons.agriculture, size: 16, color: primaryGreen),
                      errorWidget: (_, __, ___) => Icon(Icons.agriculture, size: 16, color: primaryGreen),
                    ),
                  )
                      : Icon(Icons.agriculture, size: 16, color: primaryGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: backgroundGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: commentController,
                      decoration: InputDecoration(
                        hintText: "Add a comment...",
                        hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: () {
                      if (commentController.text.trim().isNotEmpty) {
                        createComment(post['id'], commentController.text.trim());
                        commentController.clear();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGreen,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.agriculture, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              "AgriCommunity",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: cardGreen,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.refresh, color: primaryGreen),
              onPressed: fetchPosts,
            ),
          ),
        ],
      ),
      body: isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
            ),
            const SizedBox(height: 16),
            Text(
              "Loading community posts...",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: fetchPosts,
        color: primaryGreen,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: buildCreatePostCard(),
            ),
            if (posts.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.agriculture,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No posts yet",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Be the first to share your farming insights!",
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    return FadeTransition(
                      opacity: _animationController,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                            (index / posts.length) * 0.5,
                            ((index + 1) / posts.length) * 0.5 + 0.5,
                            curve: Curves.easeOut,
                          ),
                        )),
                        child: buildPostCard(posts[index]),
                      ),
                    );
                  },
                  childCount: posts.length,
                ),
              ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
    );
  }
}