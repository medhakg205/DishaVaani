// translation.dart — fetches translated narration audio from backend
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

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final audioUrl = (decoded['audioUrl'] as String?)?.trim() ?? '';
    if (audioUrl.isEmpty) {
      throw Exception('Server returned an empty audioUrl');
    }
    return audioUrl;
  }
}
