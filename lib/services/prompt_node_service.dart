import '../models/node.dart';
import '../models/prompt.dart';

/// Serviço para converter entre estrutura de Nodes e estrutura antiga de Prompts
class PromptNodeService {
  /// Converte uma estrutura de nodes para lista de prompts (formato antigo)
  /// Extrai prompts de todos os nodes da árvore recursivamente
  static List<Prompt> nodesToPrompts(Node rootNode) {
    final List<Prompt> prompts = [];
    
    void extractPromptsFromNode(Node node) {
      // Se o node tem campo "prompt", é um prompt
      if (node.fields.containsKey('prompt') && node.fields['prompt'] != null) {
        final promptText = node.fields['prompt'].toString();
        final orderStr = node.fields['order']?.toString() ?? 'start';
        final index = node.fields['index'] is int 
            ? node.fields['index'] as int
            : (node.fields['index'] is String 
                ? int.tryParse(node.fields['index'] as String) ?? 0
                : 0);
        
        try {
          final order = PromptOrder.fromJson(orderStr);
          prompts.add(Prompt(
            id: node.id,
            prompt: promptText,
            order: order,
            index: index,
          ));
        } catch (e) {
          print('⚠️ Erro ao converter prompt do node ${node.id}: $e');
        }
      }
      
      // Processa filhos recursivamente
      for (final child in node.children) {
        extractPromptsFromNode(child);
      }
    }
    
    extractPromptsFromNode(rootNode);
    return prompts;
  }

  /// Converte uma lista de prompts para estrutura de nodes
  /// Agrupa por ordem (start, after, end) em grupos hierárquicos
  static Node promptsToNode(List<Prompt> prompts) {
    // Cria grupos por ordem
    final startPrompts = <Prompt>[];
    final afterPrompts = <Prompt>[];
    final endPrompts = <Prompt>[];
    
    for (final prompt in prompts) {
      switch (prompt.order) {
        case PromptOrder.start:
          startPrompts.add(prompt);
          break;
        case PromptOrder.after:
          afterPrompts.add(prompt);
          break;
        case PromptOrder.end:
          endPrompts.add(prompt);
          break;
      }
    }
    
    // Ordena por index dentro de cada grupo
    startPrompts.sort((a, b) => a.index.compareTo(b.index));
    afterPrompts.sort((a, b) => a.index.compareTo(b.index));
    endPrompts.sort((a, b) => a.index.compareTo(b.index));
    
    // Cria node raiz
    final rootNode = Node(
      id: 'prompts-root',
      name: 'Prompts',
    );
    
    // Cria grupos como filhos da raiz
    if (startPrompts.isNotEmpty) {
      final startGroup = Node(
        id: 'prompts-group-start',
        name: 'Início (Start)',
      );
      for (final prompt in startPrompts) {
        startGroup.addChild(_promptToNode(prompt));
      }
      rootNode.addChild(startGroup);
    }
    
    if (afterPrompts.isNotEmpty) {
      final afterGroup = Node(
        id: 'prompts-group-after',
        name: 'Após (After)',
      );
      for (final prompt in afterPrompts) {
        afterGroup.addChild(_promptToNode(prompt));
      }
      rootNode.addChild(afterGroup);
    }
    
    if (endPrompts.isNotEmpty) {
      final endGroup = Node(
        id: 'prompts-group-end',
        name: 'Fim (End)',
      );
      for (final prompt in endPrompts) {
        endGroup.addChild(_promptToNode(prompt));
      }
      rootNode.addChild(endGroup);
    }
    
    return rootNode;
  }

  /// Converte um prompt individual para node
  static Node _promptToNode(Prompt prompt) {
    return Node(
      id: prompt.id,
      name: prompt.prompt.length > 50 
          ? '${prompt.prompt.substring(0, 50)}...' 
          : prompt.prompt,
      fields: {
        'prompt': prompt.prompt,
        'order': prompt.order.toJson(),
        'index': prompt.index,
      },
    );
  }

  /// Verifica se um node é um prompt (tem campo "prompt")
  static bool isPromptNode(Node node) {
    return node.fields.containsKey('prompt') && node.fields['prompt'] != null;
  }

  /// Extrai dados de prompt de um node
  static Prompt? nodeToPrompt(Node node) {
    if (!isPromptNode(node)) return null;
    
    final promptText = node.fields['prompt']?.toString() ?? '';
    final orderStr = node.fields['order']?.toString() ?? 'start';
    final index = node.fields['index'] is int 
        ? node.fields['index'] as int
        : (node.fields['index'] is String 
            ? int.tryParse(node.fields['index'] as String) ?? 0
            : 0);
    
    try {
      final order = PromptOrder.fromJson(orderStr);
      return Prompt(
        id: node.id,
        prompt: promptText,
        order: order,
        index: index,
      );
    } catch (e) {
      return null;
    }
  }
}

