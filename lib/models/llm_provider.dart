/// Enum para representar provedores de LLM disponíveis
enum LLMProvider {
  openai,
  grok,
  gemini;

  /// Converte para string para serialização
  String toJson() {
    switch (this) {
      case LLMProvider.openai:
        return 'openai';
      case LLMProvider.grok:
        return 'grok';
      case LLMProvider.gemini:
        return 'gemini';
    }
  }

  /// Cria a partir de string (deserialização)
  static LLMProvider fromJson(String value) {
    switch (value) {
      case 'openai':
        return LLMProvider.openai;
      case 'grok':
        return LLMProvider.grok;
      case 'gemini':
        return LLMProvider.gemini;
      default:
        throw ArgumentError('Valor inválido para LLMProvider: $value');
    }
  }

  /// Retorna nome amigável do provedor
  String get displayName {
    switch (this) {
      case LLMProvider.openai:
        return 'OpenAI';
      case LLMProvider.grok:
        return 'Grok';
      case LLMProvider.gemini:
        return 'Gemini';
    }
  }
}

