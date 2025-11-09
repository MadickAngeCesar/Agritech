import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class EbookScreen extends StatefulWidget {
  final String token;
  final int userId;
  const EbookScreen({required this.token, required this.userId, required Map userData});

  @override
  State<EbookScreen> createState() => _EbookScreenState();
}

class _EbookScreenState extends State<EbookScreen> with SingleTickerProviderStateMixin {
  final String baseUrl = "http://51.75.31.246:3000/api";
  late TabController _tabController;
  List<dynamic> categories = [];
  List<dynamic> allEbooks = [];
  List<dynamic> myEbooks = [];

  TextEditingController title = TextEditingController();
  TextEditingController desc = TextEditingController();
  TextEditingController fileUrl = TextEditingController();
  TextEditingController price = TextEditingController();
  int? selectedCategory;
  int? editingEbookId;
  File? selectedCoverImage;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchAll();
  }

  Future<void> fetchAll() async {
    await Future.wait([
      fetchCategories(),
      fetchApprovedEbooks(),
    ]);
  }

  Future<void> fetchCategories() async {
    final res = await http.get(Uri.parse('$baseUrl/ebooks/categories'));
    if (res.statusCode == 200) setState(() => categories = jsonDecode(res.body));
  }

  Future<void> fetchApprovedEbooks() async {
    final res = await http.get(Uri.parse('$baseUrl/ebooks'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        allEbooks = data;
        myEbooks = data.where((e) => e['author_id'] == widget.userId).toList();
      });
    }
  }

  Future<void> pickCoverImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => selectedCoverImage = File(picked.path));
    }
  }

  Future<void> submitEbook() async {
    if (title.text.isEmpty || price.text.isEmpty || double.tryParse(price.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all fields properly')));
      return;
    }

    var uri = editingEbookId == null
        ? Uri.parse('$baseUrl/ebooks')
        : Uri.parse('$baseUrl/ebooks/$editingEbookId');

    var request = http.MultipartRequest(
      editingEbookId == null ? 'POST' : 'PUT',
      uri,
    );

    request.headers['Authorization'] = 'Bearer ${widget.token}';

    request.fields['title'] = title.text;
    request.fields['description'] = desc.text;
    request.fields['price'] = double.tryParse(price.text)?.toString() ?? '0';
    request.fields['file_url'] = fileUrl.text;
    request.fields['category_id'] = selectedCategory.toString();

    if (selectedCoverImage != null) {
      request.files.add(await http.MultipartFile.fromPath('cover_image', selectedCoverImage!.path));
    }

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode == 201 || res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ebook saved successfully')));
      clearForm();
      fetchApprovedEbooks();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${res.body}')));
    }
  }

  Future<void> deleteEbook(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/ebooks/$id'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ebook deleted')));
      fetchApprovedEbooks();
    }
  }

  void openForm({Map? data}) {
    if (data != null) {
      title.text = data['title'];
      desc.text = data['description'] ?? '';
      price.text = data['price'].toString();
      fileUrl.text = data['file_url'];
      selectedCategory = data['category_id'];
      editingEbookId = data['id'];
      selectedCoverImage = null;
    } else {
      clearForm();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(editingEbookId == null ? 'Submit Ebook' : 'Update Ebook',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(controller: title, decoration: InputDecoration(labelText: 'Title')),
            TextField(controller: desc, decoration: InputDecoration(labelText: 'Description')),
            TextField(controller: fileUrl, decoration: InputDecoration(labelText: 'File URL')),
            TextField(
              controller: price,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Price'),
            ),
            DropdownButtonFormField<int>(
              value: selectedCategory,
              items: categories
                  .map((c) => DropdownMenuItem<int>(value: c['id'], child: Text(c['name'])))
                  .toList(),
              onChanged: (val) => setState(() => selectedCategory = val),
              decoration: InputDecoration(labelText: 'Category'),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: pickCoverImage,
                  icon: Icon(Icons.image),
                  label: Text('Select Cover'),
                ),
                SizedBox(width: 10),
                if (selectedCoverImage != null)
                  Expanded(child: Text(selectedCoverImage!.path.split('/').last)),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: submitEbook,
              child: Text(editingEbookId == null ? 'Submit' : 'Update'),
            )
          ]),
        ),
      ),
    );
  }

  void clearForm() {
    title.clear();
    desc.clear();
    price.clear();
    fileUrl.clear();
    selectedCategory = null;
    selectedCoverImage = null;
    editingEbookId = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ebooks'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Marketplace'), Tab(text: 'My Ebooks')],
        ),
      ),
      body: TabBarView(controller: _tabController, children: [
        buildList(allEbooks, isMyList: false),
        Stack(
          children: [
            buildList(myEbooks, isMyList: true),
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton.extended(
                onPressed: () => openForm(),
                icon: Icon(Icons.add),
                label: Text("Add Ebook"),
              ),
            )
          ],
        ),
      ]),
    );
  }

  Widget buildList(List<dynamic> data, {required bool isMyList}) {
    if (data.isEmpty) return Center(child: Text('No ebooks found.'));

    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (_, index) {
        final ebook = data[index];
        return Card(
          margin: EdgeInsets.all(10),
          child: ListTile(
            leading: Icon(Icons.book),
            title: Text(ebook['title']),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Price: ${ebook['price'] ?? 'N/A'}"),
                Text("Description: ${ebook['description'] ?? ''}"),
                Text("Category: ${ebook['EbookCategory']?['name'] ?? 'N/A'}"),
              ],
            ),
            trailing: isMyList
                ? PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') openForm(data: ebook);
                if (value == 'delete') deleteEbook(ebook['id']);
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            )
                : null,
          ),
        );
      },
    );
  }
}
