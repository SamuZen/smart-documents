/// Serviço para calcular preços de chamadas LLM
class LLMPricingService {
  /// Preços por modelo (por 1M tokens)
  /// Formato: {model_name: {input: preço_por_1M_tokens_input, output: preço_por_1M_tokens_output}}
  /// Valores aproximados baseados em preços públicos das APIs (podem variar)
  static const Map<String, Map<String, double>> _pricing = {
    // OpenAI
    'gpt-4o': {
      'input': 2.50, // $2.50 por 1M tokens de input
      'output': 10.00, // $10.00 por 1M tokens de output
    },
    'gpt-4-turbo': {
      'input': 10.00, // $10.00 por 1M tokens de input
      'output': 30.00, // $30.00 por 1M tokens de output
    },
    'gpt-4': {
      'input': 30.00, // $30.00 por 1M tokens de input
      'output': 60.00, // $60.00 por 1M tokens de output
    },
    'gpt-3.5-turbo': {
      'input': 0.50, // $0.50 por 1M tokens de input
      'output': 1.50, // $1.50 por 1M tokens de output
    },
    'gpt-3.5-turbo-16k': {
      'input': 3.00, // $3.00 por 1M tokens de input
      'output': 4.00, // $4.00 por 1M tokens de output
    },
    // Grok (xAI) - preços podem variar ou não estar disponíveis publicamente
    'grok-beta': {
      'input': 0.0, // Preço não disponível publicamente
      'output': 0.0,
    },
    'grok-2': {
      'input': 0.0,
      'output': 0.0,
    },
    'grok-2-1212': {
      'input': 0.0,
      'output': 0.0,
    },
    // Gemini (Google)
    'gemini-1.5-pro': {
      'input': 1.25, // $1.25 por 1M tokens de input
      'output': 5.00, // $5.00 por 1M tokens de output
    },
    'gemini-1.5-flash': {
      'input': 0.075, // $0.075 por 1M tokens de input
      'output': 0.30, // $0.30 por 1M tokens de output
    },
    'gemini-pro': {
      'input': 0.50, // $0.50 por 1M tokens de input
      'output': 1.50, // $1.50 por 1M tokens de output
    },
  };

  /// Calcula o custo em dólares baseado nos tokens usados
  /// 
  /// [model] - Nome do modelo usado
  /// [promptTokens] - Tokens de input/prompt
  /// [completionTokens] - Tokens de output/completion
  /// 
  /// Retorna o custo em dólares, ou null se o modelo não estiver na tabela de preços
  static double? calculateCost(
    String model,
    int? promptTokens,
    int? completionTokens,
  ) {
    final modelPricing = _pricing[model];
    if (modelPricing == null) {
      return null; // Modelo não encontrado na tabela de preços
    }

    final inputPrice = modelPricing['input'] ?? 0.0;
    final outputPrice = modelPricing['output'] ?? 0.0;

    // Calcula custo: (tokens / 1_000_000) * preço_por_1M
    final inputCost = (promptTokens ?? 0) / 1_000_000 * inputPrice;
    final outputCost = (completionTokens ?? 0) / 1_000_000 * outputPrice;

    return inputCost + outputCost;
  }

  /// Retorna se o modelo tem preços disponíveis
  static bool hasPricing(String model) {
    return _pricing.containsKey(model);
  }
}

