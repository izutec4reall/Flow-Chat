import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';

class MediaService {
  final ImagePicker _picker = ImagePicker();

  Future<Uint8List?> pickAndCropImage({
    required BuildContext context,
    required CropStyle cropStyle,
    double? ratioX,
    double? ratioY,
  }) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return null;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: ratioX != null && ratioY != null 
          ? CropAspectRatio(ratioX: ratioX, ratioY: ratioY)
          : null,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Edit Photo',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: ratioX != null,
          cropStyle: cropStyle,
        ),
        IOSUiSettings(
          title: 'Edit Photo',
          cropStyle: cropStyle,
        ),
        WebUiSettings(
          context: context,
          // Use standard size instead of boundary/viewPort if possible, 
          // or leave it default to avoid errors.
        ),
      ],
    );

    if (croppedFile != null) {
      return await croppedFile.readAsBytes();
    }
    return null;
  }
}
