import 'dart:convert';
import 'package:http/http.dart' as http;

class CameraTranslationService {
  final String _baseUrl = 'http://10.131.77.109:7860/api/predict';

  Future<String> translate(String text, {String toLang = 'English'}) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'data': [text, toLang],
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> data = responseData['data'];
        return data[0] as String;
      } else {
        throw Exception('Failed to translate text');
      }

      // if (response.statusCode == 200) {
      //   final responseData = json.decode(response.body);
      //   if (responseData.containsKey('text')) {
      //     return responseData['text'];
      //   } else {
      //     throw Exception('Unexpected response format: missing "text" field');
      //   }
      // } else {
      //   throw Exception('Failed to translate text. Status code: ${response.statusCode}');
      // }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }
}
