import '../models/node.dart';
import '../models/prompt.dart';
import 'prompt_formatter.dart';
import 'prompt_manager_service.dart';

/// Serviço para gerenciar estado de seleção e geração de prompts
class PromptService {
  final Node rootNode;
  final Set<String> _selectedNodeIds = {};
  final PromptManagerService? promptManager;

  PromptService({
    required this.rootNode,
    this.promptManager,
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

  /// Gera o prompt formatado para LLM
  /// 
  /// [includeChildren] - Se true, inclui filhos recursivamente dos nodes selecionados
  String generatePrompt({bool includeChildren = false}) {
    final buffer = StringBuffer();

    // 1. Prompts com order = "start"
    if (promptManager != null) {
      final startPrompts = promptManager!.getPromptsByOrder(PromptOrder.start);
      for (final prompt in startPrompts) {
        buffer.writeln(prompt.prompt);
        buffer.writeln(); // Linha em branco após cada prompt
      }
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
    } else {
      // Se não há nodes selecionados, apenas retorna '[]'
      buffer.write('[]');
    }

    // 3. Prompts com order = "after"
    if (promptManager != null) {
      final afterPrompts = promptManager!.getPromptsByOrder(PromptOrder.after);
      if (afterPrompts.isNotEmpty) {
        buffer.writeln();
        buffer.writeln();
      }
      for (final prompt in afterPrompts) {
        buffer.writeln(prompt.prompt);
        buffer.writeln(); // Linha em branco após cada prompt
      }
    }

    // 4. Prompts com order = "end"
    if (promptManager != null) {
      final endPrompts = promptManager!.getPromptsByOrder(PromptOrder.end);
      if (endPrompts.isNotEmpty && selectedNodes.isNotEmpty) {
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

