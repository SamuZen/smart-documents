import 'llm_provider.dart';

/// Modelo para representar um modelo LLM específico
class LLMModel {
  final LLMProvider provider;
  final String name; // Ex: "gpt-4", "grok-beta", "gemini-pro"
  final String? version; // Versão específica se aplicável

  const LLMModel({
    required this.provider,
    required this.name,
    this.version,
  });

  /// Retorna nome completo do modelo
  String get fullName => version != null ? '$name-$version' : name;

  /// Retorna nome para exibição
  String get displayName => fullName;

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'provider': provider.toJson(),
      'name': name,
      if (version != null) 'version': version,
    };
  }

  /// Cria a partir de JSON
  static LLMModel fromJson(Map<String, dynamic> json) {
    return LLMModel(
      provider: LLMProvider.fromJson(json['provider'] as String),
      name: json['name'] as String,
      version: json['version'] as String?,
    );
  }

  /// Lista de modelos disponíveis por provedor
  static List<LLMModel> getAvailableModels(LLMProvider provider) {
    switch (provider) {
      case LLMProvider.openai:
        return [
          const LLMModel(provider: LLMProvider.openai, name: 'gpt-4o'),
          const LLMModel(provider: LLMProvider.openai, name: 'gpt-4-turbo'),
          const LLMModel(provider: LLMProvider.openai, name: 'gpt-4'),
          const LLMModel(provider: LLMProvider.openai, name: 'gpt-3.5-turbo'),
          const LLMModel(provider: LLMProvider.openai, name: 'gpt-3.5-turbo-16k'),
        ];
      case LLMProvider.grok:
        return [
          const LLMModel(provider: LLMProvider.grok, name: 'grok-beta'),
          const LLMModel(provider: LLMProvider.grok, name: 'grok-2'),
          const LLMModel(provider: LLMProvider.grok, name: 'grok-2-1212'),
        ];
      case LLMProvider.gemini:
        return [
          const LLMModel(provider: LLMProvider.gemini, name: 'gemini-1.5-pro'),
          const LLMModel(provider: LLMProvider.gemini, name: 'gemini-1.5-flash'),
          const LLMModel(provider: LLMProvider.gemini, name: 'gemini-pro'),
        ];
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LLMModel &&
        other.provider == provider &&
        other.name == name &&
        other.version == version;
  }

  @override
  int get hashCode => Object.hash(provider, name, version);
}

