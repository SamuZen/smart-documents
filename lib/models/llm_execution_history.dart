import 'llm_provider.dart';

/// Modelo para histórico de execuções de LLM
class LLMExecutionHistory {
  final String id;
  final DateTime timestamp;
  final LLMProvider provider;
  final String model;
  final String prompt;
  final String response;
  final Map<String, dynamic> metadata; // tokens, tempo, custo, etc.

  LLMExecutionHistory({
    required this.id,
    required this.timestamp,
    required this.provider,
    required this.model,
    required this.prompt,
    required this.response,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'provider': provider.toJson(),
      'model': model,
      'prompt': prompt,
      'response': response,
      'metadata': metadata,
    };
  }

  /// Cria a partir de JSON
  static LLMExecutionHistory fromJson(Map<String, dynamic> json) {
    return LLMExecutionHistory(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      provider: LLMProvider.fromJson(json['provider'] as String),
      model: json['model'] as String,
      prompt: json['prompt'] as String,
      response: json['response'] as String,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Cria um novo histórico com ID gerado automaticamente
  factory LLMExecutionHistory.create({
    required LLMProvider provider,
    required String model,
    required String prompt,
    required String response,
    Map<String, dynamic>? metadata,
  }) {
    return LLMExecutionHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      provider: provider,
      model: model,
      prompt: prompt,
      response: response,
      metadata: metadata,
    );
  }

  /// Retorna tokens usados (se disponível)
  int? get tokensUsed => metadata['tokens_used'] as int?;

  /// Retorna tokens de input/prompt (se disponível)
  int? get promptTokens => metadata['prompt_tokens'] as int?;

  /// Retorna tokens de output/completion (se disponível)
  int? get completionTokens => metadata['completion_tokens'] as int?;

  /// Retorna tempo de resposta em milissegundos (se disponível)
  int? get responseTimeMs => metadata['response_time_ms'] as int?;

  /// Retorna custo estimado (se disponível)
  double? get cost => metadata['cost'] as double?;
}

