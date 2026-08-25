import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  static const String _functionUrl =
      'https://dishavaani.onrender.com/generate_regional_audio';

  Future<String> getTranslatedAudioUrl({
    required String poiId,
    required String sourceScript,
    required String targetLanguage,
    String sourceLang = 'en',
  }) async {
    final response = await http.post(
      Uri.parse(_functionUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'poiId': poiId,
        'sourceScript': sourceScript,
        'sourceLang': sourceLang,
        'targetLanguage': targetLanguage,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get translated audio: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return data['audioUrl'];
  }
}