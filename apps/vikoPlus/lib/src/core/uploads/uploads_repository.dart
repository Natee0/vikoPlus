import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../api/api_client.dart';

final uploadsRepositoryProvider = Provider<UploadsRepository>((ref) {
  return UploadsRepository(ref.watch(apiClientProvider));
});

class UploadsRepository {
  const UploadsRepository(this._dio);

  final Dio _dio;

  Future<UploadedImage> uploadGroupImage({
    required String groupId,
    required XFile image,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/uploads/groups/$groupId/image',
      data: await _imageFormData(image),
      options: Options(contentType: Headers.multipartFormDataContentType),
    );
    return UploadedImage.fromJson(_responseBody(response.data));
  }

  Future<UploadedImage> uploadProfilePicture(XFile image) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/uploads/profile-picture',
      data: await _imageFormData(image),
      options: Options(contentType: Headers.multipartFormDataContentType),
    );
    return UploadedImage.fromJson(_responseBody(response.data));
  }

  Future<FormData> _imageFormData(XFile image) async {
    return FormData.fromMap({
      'file': await MultipartFile.fromFile(
        image.path,
        filename: image.name.isEmpty ? 'image.jpg' : image.name,
      ),
    });
  }

  Map<String, dynamic> _responseBody(Map<String, dynamic>? json) {
    if (json == null) {
      throw const FormatException('API returned an empty response.');
    }

    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }

    return json;
  }
}

class UploadedImage {
  const UploadedImage({
    required this.objectKey,
    required this.url,
    required this.folder,
    required this.bytes,
  });

  factory UploadedImage.fromJson(Map<String, dynamic> json) {
    final objectKey = json['objectKey'];
    final url = json['url'];
    if (objectKey is! String ||
        objectKey.isEmpty ||
        url is! String ||
        url.isEmpty) {
      throw const FormatException('Upload response did not include an image.');
    }

    return UploadedImage(
      objectKey: objectKey,
      url: url,
      folder: json['folder'] as String? ?? '',
      bytes: json['bytes'] as int? ?? 0,
    );
  }

  final String objectKey;
  final String url;
  final String folder;
  final int bytes;
}
