import 'command_metadata.dart';
import 'command_parameter.dart';
import '../models/node.dart';
import '../services/command_history.dart';

/// Comando para reordenar nodes entre irmãos
class ReorderNodeCommand implements TreeCommand {
  final String parentNodeId;
  final String draggedNodeId;
  final String targetNodeId;
  final bool insertBefore;
  final int oldIndex;
  final int newIndex;

  ReorderNodeCommand({
    required this.parentNodeId,
    required this.draggedNodeId,
    required this.targetNodeId,
    required this.insertBefore,
    required this.oldIndex,
    required this.newIndex,
  });

  @override
  String get commandId => 'reorder_node';

  @override
  String get description => 'Reordenar node';

  @override
  Future<void> execute() async {
    // Implementação vazia - usa executeOnTree
  }

  @override
  Future<void> undo() async {
    // Implementação vazia - usa undoOnTree
  }

  @override
  Node executeOnTree(Node root) {
    return _reorderNodeInTree(root, parentNodeId, draggedNodeId, targetNodeId, insertBefore);
  }

  @override
  Node undoOnTree(Node root) {
    // Para undo, reverte a ordem: move de newIndex para oldIndex
    return _moveNodeByIndex(root, parentNodeId, draggedNodeId, newIndex, oldIndex);
  }

  Node _reorderNodeInTree(Node node, String targetParentId, String draggedId, String targetId, bool insertBefore) {
    // Verifica se este é o parent que contém os nodes
    final draggedIndex = node.children.indexWhere((child) => child.id == draggedId);
    final targetIndex = node.children.indexWhere((child) => child.id == targetId);

    if (node.id == targetParentId && draggedIndex != -1 && targetIndex != -1) {
      // Reordena os filhos
      final children = List<Node>.from(node.children);
      final draggedNode = children.removeAt(draggedIndex);
      final newTargetIndex = targetIndex > draggedIndex ? targetIndex - 1 : targetIndex;
      final insertIndex = insertBefore ? newTargetIndex : newTargetIndex + 1;
      children.insert(insertIndex.clamp(0, children.length), draggedNode);
      return node.copyWith(children: children);
    }

    // Procura recursivamente nos filhos
    final updatedChildren = node.children
        .map((child) => _reorderNodeInTree(child, targetParentId, draggedId, targetId, insertBefore))
        .toList();

    return node.copyWith(children: updatedChildren);
  }

  Node _moveNodeByIndex(Node node, String targetParentId, String nodeId, int fromIndex, int toIndex) {
    if (node.id == targetParentId) {
      final children = List<Node>.from(node.children);
      if (fromIndex >= 0 && fromIndex < children.length && toIndex >= 0 && toIndex < children.length) {
        final nodeToMove = children.removeAt(fromIndex);
        children.insert(toIndex, nodeToMove);
        return node.copyWith(children: children);
      }
    }

    final updatedChildren = node.children
        .map((child) => _moveNodeByIndex(child, targetParentId, nodeId, fromIndex, toIndex))
        .toList();

    return node.copyWith(children: updatedChildren);
  }

  /// Factory constructor para criar comando a partir de Map
  factory ReorderNodeCommand.fromMap(Map<String, dynamic> args) {
    return ReorderNodeCommand(
      parentNodeId: args['parentNodeId'] as String,
      draggedNodeId: args['draggedNodeId'] as String,
      targetNodeId: args['targetNodeId'] as String,
      insertBefore: args['insertBefore'] as bool? ?? true,
      oldIndex: args['oldIndex'] as int? ?? -1,
      newIndex: args['newIndex'] as int? ?? -1,
    );
  }

  /// Retorna metadata do comando
  static CommandMetadata getMetadata() {
    return CommandMetadata(
      id: 'reorder_node',
      name: 'Reordenar Node',
      description: 'Reordena a posição de um node entre seus irmãos',
      parameters: [
        CommandParameter(
          name: 'parentNodeId',
          type: 'String',
          description: 'ID do node pai que contém os nodes a serem reordenados',
          required: true,
        ),
        CommandParameter(
          name: 'draggedNodeId',
          type: 'String',
          description: 'ID do node sendo movido',
          required: true,
        ),
        CommandParameter(
          name: 'targetNodeId',
          type: 'String',
          description: 'ID do node alvo (referência para posição)',
          required: true,
        ),
        CommandParameter(
          name: 'insertBefore',
          type: 'bool',
          description: 'Se true, insere antes do target; se false, insere depois',
          required: false,
          defaultValue: true,
        ),
        CommandParameter(
          name: 'oldIndex',
          type: 'int',
          description: 'Índice original do node (para undo)',
          required: false,
          defaultValue: -1,
        ),
        CommandParameter(
          name: 'newIndex',
          type: 'int',
          description: 'Novo índice do node (para undo)',
          required: false,
          defaultValue: -1,
        ),
      ],
      factory: (args) => ReorderNodeCommand.fromMap(args),
    );
  }
}

