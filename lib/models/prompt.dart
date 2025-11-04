/// Enum para definir a ordem do prompt na geração final
enum PromptOrder {
  start,
  after,
  end;

  /// Converte para string para serialização
  String toJson() {
    switch (this) {
      case PromptOrder.start:
        return 'start';
      case PromptOrder.after:
        return 'after';
      case PromptOrder.end:
        return 'end';
    }
  }

  /// Cria a partir de string (deserialização)
  static PromptOrder fromJson(String value) {
    switch (value) {
      case 'start':
        return PromptOrder.start;
      case 'after':
        return PromptOrder.after;
      case 'end':
        return PromptOrder.end;
      default:
        throw ArgumentError('Valor inválido para PromptOrder: $value');
    }
  }
}

/// Modelo de dados para prompts que serão inseridos na geração do prompt final
class Prompt {
  final String id;
  final String prompt;
  final PromptOrder order;
  final int index; // Para controle de ordem dentro da categoria

  Prompt({
    required this.id,
    required this.prompt,
    required this.order,
    int? index,
  }) : index = index ?? 0;

  /// Cria uma cópia do prompt com campos opcionais modificados
  Prompt copyWith({
    String? id,
    String? prompt,
    PromptOrder? order,
    int? index,
  }) {
    return Prompt(
      id: id ?? this.id,
      prompt: prompt ?? this.prompt,
      order: order ?? this.order,
      index: index ?? this.index,
    );
  }

  /// Converte o Prompt para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prompt': prompt,
      'order': order.toJson(),
      'index': index,
    };
  }

  /// Cria um Prompt a partir de JSON
  static Prompt fromJson(Map<String, dynamic> json) {
    return Prompt(
      id: json['id'] as String,
      prompt: json['prompt'] as String,
      order: PromptOrder.fromJson(json['order'] as String),
      index: json['index'] as int? ?? 0,
    );
  }
}

