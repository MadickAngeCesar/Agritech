import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({Key? key}) : super(key: key);

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen>
    with TickerProviderStateMixin {
  List<dynamic> users = [];
  bool showBlocked = false;
  bool isLoading = true;
  String? errorMessage;
  TabController? _tabController;
  AnimationController? _fadeController;
  AnimationController? _searchController;

  final TextEditingController _searchFieldController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  final String baseUrl = 'http://51.75.31.246:3000';

  // Modern Agriculture Theme Colors
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color darkGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFE8F5E8);
  static const Color accentOrange = Color(0xFFFF8F00);
  static const Color backgroundGray = Color(0xFFF8F9FA);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color errorRed = Color(0xFFE53E3E);
  static const Color warningOrange = Color(0xFFED8936);
  static const Color successGreen = Color(0xFF38A169);

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(_handleTabChange);
    fetchUsers();

    _searchFieldController.addListener(() {
      setState(() {
        _searchQuery = _searchFieldController.text;
      });
    });
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _searchController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabChange);
    _tabController?.dispose();
    _fadeController?.dispose();
    _searchController?.dispose();
    _searchFieldController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController?.indexIsChanging == true) {
      setState(() {
        showBlocked = _tabController!.index == 1;
      });
      fetchUsers();
    }
  }

  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('jwt_token');
    } catch (e) {
      _setError("Failed to access authentication token: ${e.toString()}");
      return null;
    }
  }

  void _setError(String message) {
    setState(() {
      errorMessage = message;
      isLoading = false;
    });
  }

  void _showSnackBar(String message, {bool isError = false, bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_rounded :
              (isError ? Icons.error_rounded : Icons.info_rounded),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? successGreen :
        (isError ? errorRed : primaryGreen),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 4 : 3),
      ),
    );
  }

  Future<void> fetchUsers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final url = showBlocked
          ? '$baseUrl/api/admin/users/blocked'
          : '$baseUrl/api/admin/users';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          users = showBlocked ? data['blocked_users'] : data['users'];
          isLoading = false;
        });
        _fadeController?.forward();
      } else if (response.statusCode == 401) {
        _setError("Authentication failed. Please log in again.");
      } else {
        _setError("Server error (${response.statusCode}): ${response.reasonPhrase}");
        _showSnackBar("Failed to load users", isError: true);
      }
    } catch (e) {
      _setError("Network error: ${e.toString()}");
      _showSnackBar("Failed to connect to server", isError: true);
    }
  }

  Future<void> _showBlockDialog(dynamic user, bool isBlocking) async {
    final userName = user['full_name'] ?? user['email'] ?? 'this user';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isBlocking ? errorRed.withOpacity(0.1) : successGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isBlocking ? Icons.block_rounded : Icons.lock_open_rounded,
                  color: isBlocking ? errorRed : successGreen,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isBlocking ? 'Block User' : 'Unblock User',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    color: textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(
                        text: isBlocking
                            ? "Are you sure you want to block "
                            : "Are you sure you want to unblock "
                    ),
                    TextSpan(
                      text: userName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                        text: isBlocking
                            ? "? They will no longer be able to access the platform."
                            : "? They will regain access to the platform."
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isBlocking ? errorRed : successGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isBlocking ? 'Block' : 'Unblock',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      if (isBlocking) {
        await _performBlockUser(user);
      } else {
        await _performUnblockUser(user);
      }
    }
  }

  Future<void> _performBlockUser(dynamic user) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Authentication token not found');

      final response = await http.delete(
        Uri.parse('$baseUrl/api/admin/users/${user['id']}/block'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _showSnackBar("User blocked successfully 🚫", isSuccess: true);
        fetchUsers();
      } else {
        _showSnackBar("Failed to block user", isError: true);
      }
    } catch (e) {
      _showSnackBar("Error: ${e.toString()}", isError: true);
    }
  }

  Future<void> _performUnblockUser(dynamic user) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Authentication token not found');

      final response = await http.put(
        Uri.parse('$baseUrl/api/admin/users/${user['id']}/unblock'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _showSnackBar("User unblocked successfully ✅", isSuccess: true);
        fetchUsers();
      } else {
        _showSnackBar("Failed to unblock user", isError: true);
      }
    } catch (e) {
      _showSnackBar("Error: ${e.toString()}", isError: true);
    }
  }

  String _getInitials(dynamic user) {
    final name = user['full_name'] ?? '';
    if (name.isEmpty) return '?';

    final nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.length == 1 && nameParts[0].isNotEmpty) {
      return nameParts[0][0].toUpperCase();
    }
    return '?';
  }

  Color _getAvatarColor(dynamic user) {
    final id = user['id'] ?? 0;
    final colors = [
      primaryGreen,
      accentOrange,
      const Color(0xFF6366F1),
      const Color(0xFFEC4899),
      const Color(0xFF8B5CF6),
      const Color(0xFF06B6D4),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
    ];
    return colors[id % colors.length];
  }

  Widget _buildAvatar(dynamic user) {
    final hasProfileImage = user['profile_image'] != null &&
        user['profile_image'].toString().isNotEmpty;
    final profileUrl = hasProfileImage
        ? (user['profile_image'].toString().startsWith('http')
        ? user['profile_image']
        : '$baseUrl${user['profile_image']}')
        : null;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _getAvatarColor(user).withOpacity(0.3),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 28,
        backgroundColor: hasProfileImage ? Colors.grey.shade200 : _getAvatarColor(user),
        child: hasProfileImage
            ? ClipOval(
          child: CachedNetworkImage(
            imageUrl: profileUrl!,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            placeholder: (context, url) => Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(color: Colors.white),
            ),
            errorWidget: (context, url, error) => Text(
              _getInitials(user),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        )
            : Text(
          _getInitials(user),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(dynamic user, int index) {
    final isVerified = user['is_verified'] ?? false;
    final userRole = user['role'] ?? 'User';
    final joinDate = user['created_at'] != null
        ? DateTime.tryParse(user['created_at'])
        : null;
    final formattedJoinDate = joinDate != null
        ? '${joinDate.day}/${joinDate.month}/${joinDate.year}'
        : 'Unknown';

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: cardWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    // Navigate to user details if needed
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        _buildAvatar(user),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      user['full_name'] ?? 'No name',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isVerified)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: primaryGreen,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user['email'] ?? '',
                                style: const TextStyle(
                                  color: textSecondary,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: userRole.toLowerCase() == 'admin'
                                          ? accentOrange.withOpacity(0.1)
                                          : primaryGreen.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      userRole,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: userRole.toLowerCase() == 'admin'
                                            ? accentOrange
                                            : primaryGreen,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 14,
                                    color: textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Joined $formattedJoinDate',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: showBlocked
                                ? successGreen.withOpacity(0.1)
                                : errorRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(
                              showBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
                              color: showBlocked ? successGreen : errorRed,
                            ),
                            tooltip: showBlocked ? 'Unblock user' : 'Block user',
                            onPressed: () => _showBlockDialog(user, !showBlocked),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: cardWhite,
      foregroundColor: textPrimary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryGreen.withOpacity(0.05),
                accentOrange.withOpacity(0.05),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: lightGreen,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.people_alt_rounded,
                      color: primaryGreen,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'User Management',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Manage platform users',
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isSearching
              ? Container(
            width: 200,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: TextField(
              controller: _searchFieldController,
              autofocus: true,
              style: const TextStyle(color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Search users...',
                hintStyle: const TextStyle(color: textSecondary),
                filled: true,
                fillColor: backgroundGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search, color: textSecondary),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close, color: textSecondary),
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchFieldController.clear();
                    });
                    _searchController?.reverse();
                  },
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          )
              : Row(
            children: [
              IconButton(
                icon: const Icon(Icons.search_rounded),
                tooltip: 'Search users',
                onPressed: () {
                  setState(() {
                    _isSearching = true;
                  });
                  _searchController?.forward();
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh users',
                onPressed: fetchUsers,
              ),
            ],
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          color: cardWhite,
          child: TabBar(
            controller: _tabController!,
            indicatorColor: primaryGreen,
            indicatorWeight: 3,
            labelColor: primaryGreen,
            unselectedLabelColor: textSecondary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people_rounded, size: 20),
                    const SizedBox(width: 8),
                    const Text('Active Users'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.block_rounded, size: 20),
                    const SizedBox(width: 8),
                    const Text('Blocked Users'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        itemCount: 6,
        padding: const EdgeInsets.all(20),
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: errorRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: errorRed,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Failed to load users',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage ?? 'An unknown error occurred',
              style: const TextStyle(
                color: textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: fetchUsers,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: lightGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(
                showBlocked ? Icons.lock_open_rounded : Icons.people_outline_rounded,
                size: 64,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              showBlocked ? 'No blocked users! 🌱' : 'No users found',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              showBlocked
                  ? 'All users are active and contributing to the community'
                  : 'Start building your agricultural community',
              style: const TextStyle(
                color: textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<dynamic> get filteredUsers {
    if (_searchQuery.isEmpty) return users;

    return users.where((user) {
      final name = (user['full_name'] ?? '').toLowerCase();
      final email = (user['email'] ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();

      return name.contains(query) || email.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGray,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [_buildModernAppBar()];
        },
        body: RefreshIndicator(
          onRefresh: fetchUsers,
          color: primaryGreen,
          child: _fadeController != null
              ? AnimatedBuilder(
            animation: _fadeController!,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeController!.value,
                child: isLoading
                    ? _buildLoadingState()
                    : errorMessage != null
                    ? _buildErrorState()
                    : filteredUsers.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                  itemCount: filteredUsers.length,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemBuilder: (context, index) {
                    return _buildUserCard(filteredUsers[index], index);
                  },
                ),
              );
            },
          )
              : isLoading
              ? _buildLoadingState()
              : errorMessage != null
              ? _buildErrorState()
              : filteredUsers.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
            itemCount: filteredUsers.length,
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemBuilder: (context, index) {
              return _buildUserCard(filteredUsers[index], index);
            },
          ),
        ),
      ),
    );
  }
}