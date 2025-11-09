import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class VideoScreen extends StatefulWidget {
  final String token;
  final int userId;
  const VideoScreen({required this.token, required this.userId, required Map userData});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> with SingleTickerProviderStateMixin {
  final String baseUrl = "http://51.75.31.246:3000/api";
  late TabController _tabController;
  List<dynamic> categories = [];
  List<dynamic> allVideos = [];
  List<dynamic> myVideos = [];

  TextEditingController title = TextEditingController();
  TextEditingController description = TextEditingController();
  int? selectedCategory;
  File? selectedVideo;
  File? selectedThumbnail;
  int? editingVideoId;
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
      fetchApprovedVideos(),
    ]);
  }

  Future<void> fetchCategories() async {
    final res = await http.get(Uri.parse('$baseUrl/videos/categories'));
    if (res.statusCode == 200) setState(() => categories = jsonDecode(res.body));
  }

  Future<void> fetchApprovedVideos() async {
    final res = await http.get(Uri.parse('$baseUrl/videos'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        allVideos = data;
        myVideos = data.where((v) => v['uploaded_by'] == widget.userId).toList();
      });
    }
  }

  Future<void> pickVideoFile() async {
    final picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) setState(() => selectedVideo = File(picked.path));
  }

  Future<void> pickThumbnailImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => selectedThumbnail = File(picked.path));
  }

  Future<void> submitVideo() async {
    if (title.text.isEmpty || selectedVideo == null || selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fill all required fields')));
      return;
    }

    var uri = Uri.parse('$baseUrl/videos');
    var request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer ${widget.token}';
    request.fields['title'] = title.text;
    request.fields['description'] = description.text;
    request.fields['category_id'] = selectedCategory.toString();
    request.files.add(await http.MultipartFile.fromPath('video_url', selectedVideo!.path));

    if (selectedThumbnail != null) {
      request.files.add(await http.MultipartFile.fromPath('thumbnail_image', selectedThumbnail!.path));
    }

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Video submitted for review')));
      clearForm();
      fetchApprovedVideos();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${res.body}')));
    }
  }

  Future<void> deleteVideo(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/videos/$id'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Video deleted')));
      fetchApprovedVideos();
    }
  }

  void openForm({Map? data}) {
    if (data != null) {
      title.text = data['title'];
      description.text = data['description'] ?? '';
      selectedCategory = data['category_id'];
      editingVideoId = data['id'];
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
            Text('Upload Video', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(controller: title, decoration: InputDecoration(labelText: 'Title')),
            TextField(controller: description, decoration: InputDecoration(labelText: 'Description')),
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
                  onPressed: pickVideoFile,
                  icon: Icon(Icons.video_library),
                  label: Text('Select Video'),
                ),
                SizedBox(width: 10),
                if (selectedVideo != null)
                  Expanded(child: Text(selectedVideo!.path.split('/').last)),
              ],
            ),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: pickThumbnailImage,
                  icon: Icon(Icons.image),
                  label: Text('Select Thumbnail'),
                ),
                SizedBox(width: 10),
                if (selectedThumbnail != null)
                  Expanded(child: Text(selectedThumbnail!.path.split('/').last)),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: submitVideo, child: Text('Submit')),
          ]),
        ),
      ),
    );
  }

  void clearForm() {
    title.clear();
    description.clear();
    selectedCategory = null;
    selectedVideo = null;
    selectedThumbnail = null;
    editingVideoId = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Videos'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Marketplace'), Tab(text: 'My Videos')],
        ),
      ),
      body: TabBarView(controller: _tabController, children: [
        buildList(allVideos, isMyList: false),
        Stack(
          children: [
            buildList(myVideos, isMyList: true),
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton.extended(
                onPressed: () => openForm(),
                icon: Icon(Icons.add),
                label: Text("Add Video"),
              ),
            )
          ],
        ),
      ]),
    );
  }

  Widget buildList(List<dynamic> data, {required bool isMyList}) {
    if (data.isEmpty) return Center(child: Text('No videos found.'));

    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (_, index) {
        final video = data[index];
        return Card(
          margin: EdgeInsets.all(10),
          child: ListTile(
            leading: Icon(Icons.ondemand_video),
            title: Text(video['title']),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Description: ${video['description'] ?? ''}"),
                Text("By: ${video['User']?['full_name'] ?? 'Unknown'}"),
                Text("Category: ${video['VideoCategory']?['name'] ?? 'N/A'}"),
              ],
            ),
            trailing: isMyList
                ? PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') deleteVideo(video['id']);
              },
              itemBuilder: (_) => [
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
