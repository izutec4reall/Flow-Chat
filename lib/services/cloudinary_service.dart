import 'dart:typed_data';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  final _cloudinary = CloudinaryPublic(
    'dvdehwhwf',
    'flow-preset',
    cache: false,
  );

  Future<String?> uploadFile(Uint8List fileBytes, String fileName, String folder) async {
    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromByteData(
          ByteData.view(fileBytes.buffer),
          identifier: fileName,
          folder: folder,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      return null;
    }
  }

  Future<String?> uploadFromFile(String path, String folder) async {
    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          path,
          folder: folder,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      return null;
    }
  }

  Future<String?> uploadVideo(Uint8List bytes, String fileName, String folder) async {
    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromByteData(
          ByteData.view(bytes.buffer),
          identifier: fileName,
          folder: folder,
          resourceType: CloudinaryResourceType.Video, // Capitalized V might be the issue in some versions
        ),
      );
      return response.secureUrl;
    } catch (e) {
      // Try again with auto if Video fails
      try {
        CloudinaryResponse response = await _cloudinary.uploadFile(
          CloudinaryFile.fromByteData(
            ByteData.view(bytes.buffer),
            identifier: fileName,
            folder: folder,
          ),
        );
        return response.secureUrl;
      } catch (_) {
        return null;
      }
    }
  }

  Future<String?> uploadRaw(String filePath, String fileName, String folder) async {
    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          filePath,
          identifier: fileName,
          folder: folder,
          resourceType: CloudinaryResourceType.Raw,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      return null;
    }
  }
}
