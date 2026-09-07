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
    Map<String, dynamic>? interestProfile,
    void Function(String script)? onScriptResolved,
  }) async {
    final payload = <String, dynamic>{
      'poiId': poiId,
      'sourceScript': sourceScript,
      'sourceLang': sourceLang,
      'targetLanguage': targetLanguage,
    };
    if (interestProfile != null && interestProfile.isNotEmpty) {
      payload['interestProfile'] = interestProfile;
    }

    print('[TranslationService] 🚀 Sending request to $_functionUrl');
    print('[TranslationService] 📦 Payload: ${jsonEncode(payload)}');

    final response = await http.post(
      Uri.parse(_functionUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    print('[TranslationService] 📥 Response (${response.statusCode}): ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to get translated audio (${response.statusCode}): ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final audioUrl = (decoded['audioUrl'] as String?)?.trim() ?? '';
    final script = (decoded['script'] as String?)?.trim();
    if (script != null && script.isNotEmpty && onScriptResolved != null) {
      onScriptResolved(script);
    }
    if (audioUrl.isEmpty) {
      throw Exception('Server returned an empty audioUrl');
    }
    return audioUrl;
  }
}
