import '../models/llm_model.dart';
import '../models/llm_provider.dart';
import 'llm_providers/openai_provider.dart';
import 'llm_providers/grok_provider.dart';
import 'llm_providers/gemini_provider.dart';

/// Resposta de uma chamada LLM
class LLMResponse {
  final String content;
  final Map<String, dynamic> metadata;

  LLMResponse({
    required this.content,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};
}

/// Serviço principal para chamadas LLM
class LLMService {
  /// Chama uma LLM com o prompt fornecido
  /// 
  /// [prompt] - Texto do prompt a ser enviado
  /// [model] - Modelo LLM a ser usado
  /// [apiKey] - Chave de API do provedor
  /// 
  /// Retorna a resposta da LLM com metadados
  static Future<LLMResponse> callLLM({
    required String prompt,
    required LLMModel model,
    required String apiKey,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      switch (model.provider) {
        case LLMProvider.openai:
          final response = await OpenAIProvider.call(
            prompt: prompt,
            model: model.name,
            apiKey: apiKey,
          );
          stopwatch.stop();
          return LLMResponse(
            content: response.content,
            metadata: {
              ...response.metadata,
              'response_time_ms': stopwatch.elapsedMilliseconds,
            },
          );
        case LLMProvider.grok:
          final response = await GrokProvider.call(
            prompt: prompt,
            model: model.name,
            apiKey: apiKey,
          );
          stopwatch.stop();
          return LLMResponse(
            content: response.content,
            metadata: {
              ...response.metadata,
              'response_time_ms': stopwatch.elapsedMilliseconds,
            },
          );
        case LLMProvider.gemini:
          final response = await GeminiProvider.call(
            prompt: prompt,
            model: model.name,
            apiKey: apiKey,
          );
          stopwatch.stop();
          return LLMResponse(
            content: response.content,
            metadata: {
              ...response.metadata,
              'response_time_ms': stopwatch.elapsedMilliseconds,
            },
          );
      }
    } catch (e) {
      stopwatch.stop();
      rethrow;
    }
  }
}

