// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../model/category_model.dart';
import '../model/ebook_model.dart';
import '../model/video_model.dart';


class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000/api';
  static const Duration timeoutDuration = Duration(seconds: 15);

  final String? _token;

  ApiService({String? token}) : _token = token;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // Generic HTTP methods
  Future<http.Response> _get(String endpoint, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$baseUrl/$endpoint').replace(queryParameters: queryParams);
    return await http.get(uri, headers: _headers).timeout(timeoutDuration);
  }

  Future<http.Response> _post(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    return await http.post(
      uri,
      headers: _headers,
      body: body != null ? json.encode(body) : null,
    ).timeout(timeoutDuration);
  }

  // Category methods
  Future<List<Category>> getEbookCategories() async {
    try {
      final response = await _get('ebooks/categories');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Category.fromJson({
          ...json,
          'type': 'ebook',
        })).toList();
      }
      throw Exception('Failed to load ebook categories: ${response.statusCode}');
    } catch (e) {
      print('Error fetching ebook categories: $e');
      rethrow;
    }
  }

  Future<List<Category>> getVideoCategories() async {
    try {
      final response = await _get('videos/categories');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Category.fromJson({
          ...json,
          'type': 'video',
        })).toList();
      }
      throw Exception('Failed to load video categories: ${response.statusCode}');
    } catch (e) {
      print('Error fetching video categories: $e');
      rethrow;
    }
  }

  Future<List<Category>> getAllCategories() async {
    try {
      final futures = await Future.wait([
        getEbookCategories(),
        getVideoCategories(),
      ]);

      final ebookCategories = futures[0];
      final videoCategories = futures[1];

      final Map<String, Category> categoryMap = {};

      // Add ebook categories
      for (final category in ebookCategories) {
        categoryMap[category.name] = category;
      }

      // Merge video categories
      for (final category in videoCategories) {
        if (categoryMap.containsKey(category.name)) {
          // Update existing category to 'both' type
          final existing = categoryMap[category.name]!;
          categoryMap[category.name] = Category(
            id: existing.id,
            name: existing.name,
            type: 'both',
            videoId: category.id,
          );
        } else {
          categoryMap[category.name] = category;
        }
      }

      return categoryMap.values.toList();
    } catch (e) {
      print('Error fetching all categories: $e');
      rethrow;
    }
  }

  // Ebook methods
  Future<List<Ebook>> getEbooks({int? categoryId, bool? approved}) async {
    try {
      final queryParams = <String, String>{};
      if (categoryId != null && categoryId > 0) {
        queryParams['category_id'] = categoryId.toString();
      }
      if (approved != null) {
        queryParams['approved'] = approved.toString();
      }

      final response = await _get('ebooks', queryParams: queryParams);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Ebook.fromJson(json)).toList();
      }
      throw Exception('Failed to load ebooks: ${response.statusCode}');
    } catch (e) {
      print('Error fetching ebooks: $e');
      rethrow;
    }
  }

  Future<bool> purchaseEbook(int ebookId) async {
    try {
      final response = await _post('ebooks/purchase', body: {
        'ebook_id': ebookId,
      });

      if (response.statusCode == 201) {
        return true;
      }

      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? errorData['message'] ?? 'Purchase failed');
    } catch (e) {
      print('Error purchasing ebook: $e');
      rethrow;
    }
  }

  // Video methods
  Future<List<Video>> getVideos({int? categoryId}) async {
    try {
      final queryParams = <String, String>{};
      if (categoryId != null && categoryId > 0) {
        queryParams['category_id'] = categoryId.toString();
      }

      final response = await _get('videos', queryParams: queryParams);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Video.fromJson(json)).toList();
      }
      throw Exception('Failed to load videos: ${response.statusCode}');
    } catch (e) {
      print('Error fetching videos: $e');
      rethrow;
    }
  }

  Future<bool> uploadEbook({
    required String title,
    required String description,
    required String price,
    required int categoryId,
    File? pdfFile,
    required File coverImage,
  }) async {
    try {
      print('📚 =================================');
      print('📚 EBOOK UPLOAD DEBUG SESSION');
      print('📚 =================================');

      print('📝 Input Parameters:');
      print('  Title: "$title" (${title.length} chars)');
      print('  Description: "$description" (${description.length} chars)');
      print('  Price: "$price"');
      print('  Category ID: $categoryId');
      print('  PDF File: ${pdfFile?.path ?? "null"}');
      print('  Cover Image: ${coverImage.path}');
      print('  Token available: ${_token != null}');

      final uri = Uri.parse('$baseUrl/ebooks');
      print('📡 Target URL: $uri');

      final request = http.MultipartRequest('POST', uri);

      if (_token != null && _token!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $_token';
        print('🔐 Authorization header added (${_token!.length} chars)');
      } else {
        print('⚠️ WARNING: No authorization token!');
      }

      // Add form fields
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['price'] = price;
      request.fields['category_id'] = categoryId.toString();

      print('📋 Added text fields: title, description, price, category_id');

      // Add cover image file
      final coverStream = http.ByteStream(coverImage.openRead());
      final coverLength = await coverImage.length();
      final coverMultipartFile = http.MultipartFile(
        'cover_image', // backend must accept `cover_image` as file
        coverStream,
        coverLength,
        filename: coverImage.path.split('/').last,
      );
      request.files.add(coverMultipartFile);
      print('📎 Cover image added as multipart file: ${coverImage.path.split('/').last}');

      // Add PDF file if available
      if (pdfFile != null) {
        final fileStream = http.ByteStream(pdfFile.openRead());
        final fileSize = await pdfFile.length();
        final multipartFile = http.MultipartFile(
          'file',
          fileStream,
          fileSize,
          filename: pdfFile.path.split('/').last,
        );
        request.files.add(multipartFile);
        print('📎 PDF file added as multipart file: ${pdfFile.path.split('/').last}');
      } else {
        print('📎 No PDF file (optional)');
      }

      print(' SENDING REQUEST...');
      final streamedResponse = await request.send().timeout(Duration(minutes: 5));
      final response = await http.Response.fromStream(streamedResponse);

      print('📨 Response received: ${response.statusCode}');
      print('📄 Body: ${response.body}');

      if (response.statusCode == 201) {
        print('✅ Ebook uploaded successfully!');
        return true;
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error'] ?? errorData['message'] ?? response.body;
        throw Exception(errorMessage);
      }
    } catch (e) {
      print(' Exception during upload: $e');
      rethrow;
    }
  }


  Future<bool> uploadVideo({
    required String title,
    required String description,
    required int categoryId,
    required File videoFile,
    // Removed thumbnailImage parameter - backend generates it automatically
  }) async {
    try {
      print('🎥 Starting video upload...');
      print('Title: $title');
      print('Category ID: $categoryId');
      print('Video file size: ${await videoFile.length()} bytes');

      final uri = Uri.parse('$baseUrl/videos');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
        print('Authorization header added');
      }

      // Add fields
      request.fields['title'] = title.trim();
      request.fields['description'] = description.trim();
      request.fields['category_id'] = categoryId.toString();

      print('Form fields added: ${request.fields}');

      // Add video file only - no thumbnail required
      final videoStream = http.ByteStream(videoFile.openRead());
      final videoSize = await videoFile.length();
      final videoMultipartFile = http.MultipartFile(
        'video_url',
        videoStream,
        videoSize,
        filename: videoFile.path.split('/').last,
      );
      request.files.add(videoMultipartFile);
      print('Video file added: ${videoFile.path.split('/').last}, Size: $videoSize bytes');

      print('Sending request to: $uri');
      final streamedResponse = await request.send().timeout(Duration(minutes: 10)); // Longer timeout for videos
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        print('✅ Video upload successful!');
        return true;
      } else {
        print(' Video upload failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('💥 Error uploading video: $e');
      rethrow;
    }
  }




  static const String baseUrlImage = 'http://10.0.2.2:3000';

  static String getFullUrl(String? path) {
    print('🔍 ApiService.getFullUrl called with: "$path"');

    if (path == null || path.trim().isEmpty) {
      print('⚠️ Path is null or empty, returning empty string');
      return '';
    }

    // If it's already a full URL, return as is
    if (path.startsWith('http://') || path.startsWith('https://')) {
      print('✅ Path is already a full URL: $path');
      return path;
    }

    // Normalize: replace backslashes with slashes and remove multiple slashes
    String normalizedPath = path
        .replaceAll('\\', '/')
        .replaceAll(RegExp(r'^/+'), '')      // remove leading slashes
        .replaceAll(RegExp(r'/+'), '/');     // collapse multiple slashes

    print('🔄 Normalized path: "$normalizedPath"');

    String fullUrl = '$baseUrlImage/$normalizedPath';
    print('🌐 Final URL: "$fullUrl"');

    return fullUrl;
  }


  Future<bool> submitPurchaseForm({
    required String ebookId,
    required String address,
    required String phone,
    String? note,
  }) async {
    final url = Uri.parse('$baseUrl/ebooks/$ebookId/purchase');
    final token = _token;
    if (token == null) throw Exception('Missing auth token');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'address': address,
        'phone': phone,
        'note': note ?? '',
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print('❌ Purchase form failed: ${response.body}');
      return false;
    }
  }




  Future<List<Video>> getRandomVideos() async {
    try {
      final response = await _get('videos/random-multiple');
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);

        // Handle both array and object responses
        List<dynamic> data;
        if (responseBody is List) {
          data = responseBody;
        } else if (responseBody is Map<String, dynamic>) {
          // Check for common keys that might contain the video array
          if (responseBody.containsKey('videos')) {
            data = responseBody['videos'] as List<dynamic>;
          } else if (responseBody.containsKey('data')) {
            data = responseBody['data'] as List<dynamic>;
          } else {
            throw Exception('Unexpected response format for videos');
          }
        } else {
          throw Exception('Invalid response format for videos');
        }

        return data.map((json) => Video.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        return []; // Return empty list if no videos found
      }
      throw Exception('Failed to load random videos: ${response.statusCode}');
    } catch (e) {
      print('Error fetching random videos: $e');
      rethrow;
    }
  }



  Future<List<Ebook>> getRandomEbooks() async {
    try {
      final response = await _get('ebooks/random');
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);

        // Handle both array and object responses
        List<dynamic> data;
        if (responseBody is List) {
          data = responseBody;
        } else if (responseBody is Map<String, dynamic>) {
          // Check for common keys that might contain the ebook array
          if (responseBody.containsKey('ebooks')) {
            data = responseBody['ebooks'] as List<dynamic>;
          } else if (responseBody.containsKey('data')) {
            data = responseBody['data'] as List<dynamic>;
          } else {
            throw Exception('Unexpected response format for ebooks');
          }
        } else {
          throw Exception('Invalid response format for ebooks');
        }

        return data.map((json) => Ebook.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        return []; // Return empty list if no ebooks found
      }
      throw Exception('Failed to load random ebooks: ${response.statusCode}');
    } catch (e) {
      print('Error fetching random ebooks: $e');
      rethrow;
    }
  }



  Future<List<dynamic>> getRandomWebinars() async {
    try {
      final response = await _get('webinars/random');
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);

        // Handle both array and object responses
        List<dynamic> data;
        if (responseBody is List) {
          data = responseBody;
        } else if (responseBody is Map<String, dynamic>) {
          // Based on your controller, webinars are returned as { "webinars": [...] }
          if (responseBody.containsKey('webinars')) {
            data = responseBody['webinars'] as List<dynamic>;
          } else if (responseBody.containsKey('data')) {
            data = responseBody['data'] as List<dynamic>;
          } else {
            throw Exception('Unexpected response format for webinars. Expected "webinars" key.');
          }
        } else {
          throw Exception('Invalid response format for webinars');
        }

        return data;
      } else if (response.statusCode == 404) {
        return []; // Return empty list if no webinars found
      }
      throw Exception('Failed to load random webinars: ${response.statusCode}');
    } catch (e) {
      print('Error fetching random webinars: $e');
      rethrow;
    }
  }


}
