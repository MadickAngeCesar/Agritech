import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_feather_icons/flutter_feather_icons.dart';

class CategoryManagementScreen extends StatefulWidget {
  final String token;

  const CategoryManagementScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  List categories = [];
  bool isLoading = true;

  final categoryUrl = 'http://51.75.31.246:3000/api/categories';
  final subCategoryUrl = 'http://51.75.31.246:3000/api/subcategories';

  // Color scheme
  final Color primaryColor = Color(0xFF2E7D32); // Deep green
  final Color accentColor = Color(0xFF7CB342); // Light green
  final Color backgroundColor = Color(0xFFF5F5F5); // Light gray background
  final Color cardColor = Colors.white;
  final Color textColor = Color(0xFF333333);
  final Color secondaryTextColor = Color(0xFF666666);

  @override
  void initState() {
    super.initState();
    fetchCategoriesWithSubcategories();
  }

  Future<void> fetchCategoriesWithSubcategories() async {
    setState(() => isLoading = true);

    try {
      final res = await http.get(Uri.parse(categoryUrl));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        List catWithSubs = [];

        for (var cat in data) {
          final subRes = await http.get(Uri.parse('$subCategoryUrl/category/${cat['id']}'));
          if (subRes.statusCode == 200) {
            cat['subcategories'] = json.decode(subRes.body);
          } else {
            cat['subcategories'] = [];
          }
          catWithSubs.add(cat);
        }

        setState(() {
          categories = catWithSubs;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load');
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          )
      );
    }
  }

  Future<void> saveCategory({int? id, required String name}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${widget.token}',
    };

    final body = jsonEncode({'name': name});

    final res = id == null
        ? await http.post(Uri.parse(categoryUrl), headers: headers, body: body)
        : await http.put(Uri.parse('$categoryUrl/$id'), headers: headers, body: body);

    if (res.statusCode == 200 || res.statusCode == 201) {
      Navigator.of(context).pop();
      await fetchCategoriesWithSubcategories();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save category'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          )
      );
    }
  }

  Future<void> deleteCategory(int id) async {
    final res = await http.delete(
      Uri.parse('$categoryUrl/$id'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (res.statusCode == 204 || res.statusCode == 200) {
      await fetchCategoriesWithSubcategories();
    }
  }

  Future<void> saveSubCategory({
    int? id,
    required int categoryId,
    required String name,
    required String description,
  }) async {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${widget.token}',
    };

    final body = jsonEncode({
      'name': name,
      'description': description,
      'category_id': categoryId,
    });

    final res = id == null
        ? await http.post(Uri.parse(subCategoryUrl), headers: headers, body: body)
        : await http.put(Uri.parse('$subCategoryUrl/$id'), headers: headers, body: body);

    if (res.statusCode == 200 || res.statusCode == 201) {
      Navigator.of(context).pop();
      await fetchCategoriesWithSubcategories();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save subcategory'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          )
      );
    }
  }

  Future<void> deleteSubCategory(int id) async {
    final res = await http.delete(
      Uri.parse('$subCategoryUrl/$id'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (res.statusCode == 204 || res.statusCode == 200) {
      await fetchCategoriesWithSubcategories();
    }
  }

  void showCategoryDialog({Map? category}) {
    final controller = TextEditingController(text: category?['name'] ?? '');

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        backgroundColor: cardColor,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                category != null ? 'Edit Category' : 'Add Category',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                style: GoogleFonts.poppins(),
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  labelStyle: GoogleFonts.poppins(color: secondaryTextColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: secondaryTextColor,
                      textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: () async {
                      final name = controller.text.trim();
                      if (name.isNotEmpty) {
                        await saveCategory(id: category?['id'], name: name);
                      }
                    },
                    child: Text(
                      'Save',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
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
  }

  void showSubCategoryDialog({Map? sub, required int categoryId}) {
    final nameController = TextEditingController(text: sub?['name'] ?? '');
    final descController = TextEditingController(text: sub?['description'] ?? '');

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        backgroundColor: cardColor,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                sub != null ? 'Edit Subcategory' : 'Add Subcategory',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                style: GoogleFonts.poppins(),
                decoration: InputDecoration(
                  labelText: 'Subcategory Name',
                  labelStyle: GoogleFonts.poppins(color: secondaryTextColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: descController,
                style: GoogleFonts.poppins(),
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: GoogleFonts.poppins(color: secondaryTextColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: secondaryTextColor,
                      textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: () async {
                      final name = nameController.text.trim();
                      final description = descController.text.trim();
                      if (name.isNotEmpty) {
                        await saveSubCategory(
                          id: sub != null ? sub['id'] : null,
                          categoryId: categoryId,
                          name: name,
                          description: description,
                        );
                      }
                    },
                    child: Text(
                      'Save',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Manage Categories',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
        ),
      )
          : categories.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FeatherIcons.folder,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No categories found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first category by tapping the + button',
              style: GoogleFonts.poppins(
                color: secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (_, index) {
          final cat = categories[index];
          final subs = cat['subcategories'] ?? [];

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: ExpansionTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  FeatherIcons.folder,
                  color: primaryColor,
                ),
              ),
              title: Text(
                cat['name'],
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              children: [
                _buildActionTile(
                  icon: FeatherIcons.edit,
                  title: 'Edit Category',
                  onTap: () => showCategoryDialog(category: cat),
                ),
                _buildActionTile(
                  icon: FeatherIcons.trash2,
                  title: 'Delete Category',
                  isDestructive: true,
                  onTap: () => deleteCategory(cat['id']),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                if (subs.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 8),
                    child: Text(
                      'Subcategories',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: secondaryTextColor,
                      ),
                    ),
                  ),
                ...subs.map<Widget>((sub) => ListTile(
                  contentPadding: const EdgeInsets.only(left: 32),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      FeatherIcons.list,
                      size: 18,
                      color: accentColor,
                    ),
                  ),
                  title: Text(
                    sub['name'],
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: sub['description'] != null && sub['description'].isNotEmpty
                      ? Text(
                    sub['description'],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: secondaryTextColor,
                    ),
                  )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          FeatherIcons.edit,
                          size: 18,
                          color: primaryColor,
                        ),
                        onPressed: () => showSubCategoryDialog(
                          sub: sub,
                          categoryId: cat['id'],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          FeatherIcons.trash2,
                          size: 18,
                          color: Colors.red.shade400,
                        ),
                        onPressed: () => deleteSubCategory(sub['id']),
                      ),
                    ],
                  ),
                )),
                _buildActionTile(
                  icon: FeatherIcons.plus,
                  title: 'Add Subcategory',
                  isAccent: true,
                  onTap: () => showSubCategoryDialog(categoryId: cat['id']),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showCategoryDialog(),
        tooltip: 'Add Category',
        backgroundColor: primaryColor,
        child: const Icon(FeatherIcons.plus, color: Colors.white),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    bool isDestructive = false,
    bool isAccent = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 16),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isAccent
              ? accentColor.withOpacity(0.1)
              : isDestructive
              ? Colors.red.shade50
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isAccent
              ? accentColor
              : isDestructive
              ? Colors.red.shade400
              : secondaryTextColor,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: isDestructive ? Colors.red.shade400 : textColor,
        ),
      ),
      onTap: onTap,
    );
  }
}