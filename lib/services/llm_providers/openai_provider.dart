import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/llm_service.dart';

/// Provider para OpenAI
class OpenAIProvider {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  /// Chama a API da OpenAI
  static Future<LLMResponse> call({
    required String prompt,
    required String model,
    required String apiKey,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(
          'Erro na API OpenAI: ${errorBody['error']?['message'] ?? response.statusCode}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List;
      if (choices.isEmpty) {
        throw Exception('Resposta vazia da OpenAI');
      }

      final content = choices[0]['message']['content'] as String;
      final usage = data['usage'] as Map<String, dynamic>?;

      return LLMResponse(
        content: content,
        metadata: {
          'tokens_used': usage?['total_tokens'] as int?,
          'prompt_tokens': usage?['prompt_tokens'] as int?,
          'completion_tokens': usage?['completion_tokens'] as int?,
          'model_used': data['model'] as String?,
        },
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Erro ao chamar OpenAI: $e');
    }
  }
}

