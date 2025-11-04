import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/llm_service.dart';

/// Provider para Gemini (Google)
class GeminiProvider {
  static String _getBaseUrl(String model) {
    // Gemini usa diferentes endpoints dependendo do modelo
    if (model.contains('1.5')) {
      return 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';
    }
    return 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';
  }

  /// Chama a API do Gemini
  static Future<LLMResponse> call({
    required String prompt,
    required String model,
    required String apiKey,
  }) async {
    try {
      final url = Uri.parse('${_getBaseUrl(model)}?key=$apiKey');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': prompt,
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(
          'Erro na API Gemini: ${errorBody['error']?['message'] ?? response.statusCode}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('Resposta vazia do Gemini');
      }

      final candidate = candidates[0] as Map<String, dynamic>;
      final content = candidate['content'] as Map<String, dynamic>;
      final parts = content['parts'] as List;
      if (parts.isEmpty) {
        throw Exception('Resposta sem conteúdo do Gemini');
      }

      final text = parts[0]['text'] as String;
      final usageMetadata = data['usageMetadata'] as Map<String, dynamic>?;

      return LLMResponse(
        content: text,
        metadata: {
          'tokens_used': usageMetadata?['totalTokenCount'] as int?,
          'prompt_tokens': usageMetadata?['promptTokenCount'] as int?,
          'completion_tokens': usageMetadata?['candidatesTokenCount'] as int?,
          'model_used': model,
        },
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Erro ao chamar Gemini: $e');
    }
  }
}

