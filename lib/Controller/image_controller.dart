import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:http/http.dart' as http;
import 'package:malaymate/Model/camera_translation_service.dart';

class ImageController {
  final imageNotifier = ValueNotifier<XFile?>(null);
  final ocrResultNotifier = ValueNotifier<String>('');
  final translatedResultNotifier = ValueNotifier<String>('');
  final CameraTranslationService _translationService = CameraTranslationService();

  late BuildContext context;
  String fromLanguage = 'English';
  String toLanguage = 'Malay';

  void setContext(BuildContext newContext) {
    context = newContext;
  }

  void swapLanguages() {
    String temp = fromLanguage;
    fromLanguage = toLanguage;
    toLanguage = temp;
  }

  Future<void> uploadImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        imageNotifier.value = pickedFile;
      }
    } catch (e, stackTrace) {
      logError('Error uploading image', e, stackTrace);
      _showErrorDialog('Failed to upload image. Please try again.');
    }
  }

  Future<void> captureImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        imageNotifier.value = pickedFile;
      }
    } catch (e, stackTrace) {
      logError('Error capturing image', e, stackTrace);
      _showErrorDialog('Failed to capturing image. Please try again.');
    }
  }

  Future<void> cropImage() async {
    final image = imageNotifier.value;
    if (image != null) {
      try {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          compressFormat: ImageCompressFormat.jpg,
          compressQuality: 100,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Camera Translation',
              toolbarColor: Colors.blue,
              toolbarWidgetColor: Colors.white,
              activeControlsWidgetColor: Colors.blue,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: false,
            ),
          ],
        );
        if (croppedFile != null) {
          imageNotifier.value = XFile(croppedFile.path);
        }
      } catch (e, stackTrace) {
        logError('Error cropping image', e, stackTrace);
        _showErrorDialog('Failed to crop image. Please try again.');
      }
    }
  }

  Future<void> performOCR() async {
    var url = Uri.parse('http://10.131.77.109:5000/ocr');
    final imageFile = imageNotifier.value;
    if (imageFile == null) return;

    try {
      final request = http.MultipartRequest(
        'POST',
        url,
      );
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final result = json.decode(responseData);
        ocrResultNotifier.value = result['text'].toString();

        // Print the OCR text obtained
        print("OCR Text: ${ocrResultNotifier.value}");
      } else {
        ocrResultNotifier.value = 'Failed to perform OCR';
        _showErrorDialog('Failed to perform OCR. Please try again.');
      }
    } catch (e, stackTrace) {
      logError('Error performing OCR', e, stackTrace);
      ocrResultNotifier.value = 'Failed to perform OCR';
      _showErrorDialog('Failed to perform OCR. Please try again.');
    }
  }

  // Future<void> translateText() async {
  //   if (ocrResultNotifier.value.isNotEmpty) {
  //     try {
  //       String translatedText = await _translationService.translate(
  //         ocrResultNotifier.value,
  //         toLang: toLanguage,
  //       );
  //       translatedResultNotifier.value = translatedText;
  //     } catch (e, stackTrace) {
  //       // Handle translation error
  //       logError('Error translating text', e, stackTrace);
  //       _showErrorDialog('Failed to translate text. Please try again.');
  //     }
  //   }
  // }

  Future<void> translateText() async {
    if (ocrResultNotifier.value.isNotEmpty) {
      try {
        String toLangCode = _getLanguageCode(toLanguage);
        String translatedText = await _translationService.translate(
          ocrResultNotifier.value,
          toLang: toLangCode,
        );
        translatedResultNotifier.value = translatedText;
      } catch (e, stackTrace) {
        logError('Error translating text', e, stackTrace);
        _showErrorDialog('Failed to translate text. Please try again.');
      }
    }
  }

  String _getLanguageCode(String language) {
    switch (language) {
      case 'English':
        return 'English'; // Note: Your backend expects 'English' instead of 'en'
      case 'Malay':
        return 'Malay'; // Note: Your backend expects 'Malay' instead of 'ms'
      default:
        return '';
    }
  }

  void clear() {
    imageNotifier.value = null;
    ocrResultNotifier.value = '';
    translatedResultNotifier.value = '';
  }

  void logError(String message, Object error, StackTrace? stackTrace) {
    // Use a logging library or service to log errors
    debugPrint('Error: $message');
    debugPrint('Exception: $error');
    if (stackTrace != null) {
      debugPrint('StackTrace: $stackTrace');
    }
  }

  void _showErrorDialog(String message) {
    if (context != null) {
      showDialog(
        context: context!,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }
}
