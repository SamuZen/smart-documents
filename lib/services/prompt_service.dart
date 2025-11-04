import '../models/node.dart';
import '../models/prompt.dart';
import 'prompt_formatter.dart';
import 'prompt_node_service.dart';

/// Serviço para gerenciar estado de seleção e geração de prompts
class PromptService {
  final Node rootNode;
  final Set<String> _selectedNodeIds = {};
  final Set<String> _selectedPromptIds = {};
  final Node? promptsRootNode;

  PromptService({
    required this.rootNode,
    this.promptsRootNode,
  });

  /// Adiciona um node à seleção
  void selectNode(String nodeId) {
    _selectedNodeIds.add(nodeId);
  }

  /// Remove um node da seleção
  void deselectNode(String nodeId) {
    _selectedNodeIds.remove(nodeId);
  }

  /// Alterna seleção de um node
  void toggleNode(String nodeId) {
    if (_selectedNodeIds.contains(nodeId)) {
      _selectedNodeIds.remove(nodeId);
    } else {
      _selectedNodeIds.add(nodeId);
    }
  }

  /// Retorna todos os nodes selecionados, excluindo aqueles que são descendentes de outros selecionados
  List<Node> getSelectedNodes() {
    final List<Node> selectedNodes = [];
    
    // Coleta todos os nodes selecionados
    for (final nodeId in _selectedNodeIds) {
      final node = rootNode.findById(nodeId);
      if (node != null) {
        selectedNodes.add(node);
      }
    }
    
    // Filtra removendo nodes que são descendentes de outros nodes selecionados
    final filteredNodes = <Node>[];
    for (final node in selectedNodes) {
      bool isDescendantOfSelected = false;
      
      // Verifica se este node é descendente de algum outro node selecionado
      for (final otherNode in selectedNodes) {
        if (otherNode.id != node.id &&
            Node.isDescendantOf(rootNode, otherNode.id, node.id)) {
          isDescendantOfSelected = true;
          break;
        }
      }
      
      // Só adiciona se não for descendente de outro node selecionado
      if (!isDescendantOfSelected) {
        filteredNodes.add(node);
      }
    }
    
    return filteredNodes;
  }

  /// Retorna os IDs dos nodes selecionados
  Set<String> getSelectedNodeIds() {
    return Set<String>.from(_selectedNodeIds);
  }

  /// Define os nodes selecionados
  void setSelectedNodes(Set<String> nodeIds) {
    _selectedNodeIds.clear();
    _selectedNodeIds.addAll(nodeIds);
  }

  /// Limpa toda a seleção
  void clearSelection() {
    _selectedNodeIds.clear();
  }

  /// Verifica se há nodes selecionados
  bool hasSelection() {
    return _selectedNodeIds.isNotEmpty;
  }

  /// Define os prompts selecionados
  void setSelectedPrompts(Set<String> promptIds) {
    _selectedPromptIds.clear();
    _selectedPromptIds.addAll(promptIds);
  }

  /// Retorna os prompts selecionados extraídos da árvore
  List<Prompt> getSelectedPrompts() {
    if (promptsRootNode == null) return [];
    
    final List<Prompt> prompts = [];
    for (final promptId in _selectedPromptIds) {
      final node = promptsRootNode!.findById(promptId);
      if (node != null && PromptNodeService.isPromptNode(node)) {
        final prompt = PromptNodeService.nodeToPrompt(node);
        if (prompt != null) {
          prompts.add(prompt);
        }
      }
    }
    
    // Ordena por order e depois por index
    prompts.sort((a, b) {
      final orderCompare = a.order.index.compareTo(b.order.index);
      if (orderCompare != 0) return orderCompare;
      return a.index.compareTo(b.index);
    });
    
    return prompts;
  }

  /// Gera o prompt formatado para LLM
  /// 
  /// [includeChildren] - Se true, inclui filhos recursivamente dos nodes selecionados
  String generatePrompt({bool includeChildren = false}) {
    final buffer = StringBuffer();
    final selectedPrompts = getSelectedPrompts();

    // Agrupa prompts por ordem
    final startPrompts = selectedPrompts.where((p) => p.order == PromptOrder.start).toList();
    final afterPrompts = selectedPrompts.where((p) => p.order == PromptOrder.after).toList();
    final endPrompts = selectedPrompts.where((p) => p.order == PromptOrder.end).toList();

    // 1. Prompts com order = "start"
    for (final prompt in startPrompts) {
      buffer.writeln(prompt.prompt);
      buffer.writeln(); // Linha em branco após cada prompt
    }

    // 2. Conteúdo JSON dos nodes (existente)
    final selectedNodes = getSelectedNodes();
    
    if (selectedNodes.isNotEmpty) {
      final count = selectedNodes.length;
      final countText = count == 1 ? '1 node selecionado' : '$count nodes selecionados';
      final introText = '$countText para contexto:\n\n';

      final jsonContent = PromptFormatter.formatNodesForLLM(
        selectedNodes,
        selectedNodeIds: _selectedNodeIds,
        includeChildren: includeChildren,
      );

      buffer.write(introText);
      buffer.write(jsonContent);
    }
    // Se não há nodes selecionados, não adiciona nada (contexto vazio)
    // Isso permite que os prompts sejam montados mesmo sem nodes selecionados

    // 3. Prompts com order = "after"
    if (afterPrompts.isNotEmpty) {
      // Adiciona linha em branco apenas se houver conteúdo antes (nodes ou prompts start)
      if (selectedNodes.isNotEmpty || startPrompts.isNotEmpty) {
        buffer.writeln();
        buffer.writeln();
      }
      for (final prompt in afterPrompts) {
        buffer.writeln(prompt.prompt);
        buffer.writeln(); // Linha em branco após cada prompt
      }
    }

    // 4. Prompts com order = "end"
    if (endPrompts.isNotEmpty) {
      // Adiciona linha em branco apenas se houver conteúdo antes
      if (selectedNodes.isNotEmpty || startPrompts.isNotEmpty || afterPrompts.isNotEmpty) {
        buffer.writeln();
      }
      for (final prompt in endPrompts) {
        buffer.writeln(prompt.prompt);
        buffer.writeln(); // Linha em branco após cada prompt
      }
    }

    return buffer.toString().trim(); // Remove espaços em branco extras no final
  }

  /// Valida se a seleção é válida antes de gerar prompt
  bool validateSelection() {
    if (_selectedNodeIds.isEmpty) {
      return false;
    }

    // Verifica se todos os IDs ainda existem na árvore
    for (final nodeId in _selectedNodeIds) {
      if (rootNode.findById(nodeId) == null) {
        return false;
      }
    }

    return true;
  }
}

