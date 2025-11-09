import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'dart:convert';

Future<void> registerUser({
  required String fullName,
  required String email,
  required String phone,
  required String password,
  required String address,
  required DateTime dateOfBirth,
  required File profileImage,
}) async {
  final uri = Uri.parse('http://51.75.31.246:3000/api/users/register');

  var request = http.MultipartRequest('POST', uri);

  // Attach fields
  request.fields['full_name'] = fullName;
  request.fields['email'] = email;
  request.fields['phone'] = phone;
  request.fields['password'] = password;
  request.fields['address'] = address;
  request.fields['date_of_birth'] = dateOfBirth.toIso8601String();

  // Attach image
  var imageStream = http.MultipartFile.fromBytes(
    'profile_image',
    await profileImage.readAsBytes(),
    filename: path.basename(profileImage.path),
  );
  request.files.add(imageStream);

  // Send request
  var response = await request.send();

  if (response.statusCode == 201) {
    final respStr = await response.stream.bytesToString();
    print('✅ Registration successful: $respStr');
  } else {
    final respStr = await response.stream.bytesToString();
    print('❌ Registration failed: ${response.statusCode}');
    print('Response: $respStr');
    throw Exception('Registration failed');
  }
}
