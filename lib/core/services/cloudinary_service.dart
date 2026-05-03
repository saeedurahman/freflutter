import 'dart:io';
import 'package:dio/dio.dart';

class CloudinaryService {
  static const String _uploadPreset = 'freshorder';
  static const String _uploadUrl = 
    'https://api.cloudinary.com/v1_1/dboixaq55/image/upload';

  static Future<String> uploadImage(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imageFile.path),
        'upload_preset': _uploadPreset,
      });

      final response = await Dio().post(_uploadUrl, data: formData);

      if (response.statusCode == 200) {
        return response.data['secure_url'];
      } else {
        throw 'Upload failed: ${response.statusMessage}';
      }
    } catch (e) {
      throw 'Upload failed: $e';
    }
  }
}