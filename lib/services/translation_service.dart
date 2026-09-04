// translation_service.dart — fetches translated narration audio from backend
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  static const String _functionUrl = 'https://dishavaani.onrender.com/generate_regional_audio';
  static const Duration _timeout = Duration(seconds: 15);

  Future<String> getTranslatedAudioUrl({
    required String poiId,
    required String sourceScript,
    required String targetLanguage,
    String sourceLang = 'en',
  }) async {
    late final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(_functionUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'poiId': poiId,
              'sourceScript': sourceScript,
              'sourceLang': sourceLang,
              'targetLanguage': targetLanguage,
            }),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw Exception('Translation request timed out — the server may be waking up, try again shortly.');
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to get translated audio: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final audioUrl = (data['audioUrl'] as String?)?.trim() ?? '';
    if (audioUrl.isEmpty) {
      throw Exception('Server returned an empty audioUrl');
    }
    return audioUrl;
  }
}