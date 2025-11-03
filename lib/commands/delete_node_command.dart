import 'command_metadata.dart';
import 'command_parameter.dart';
import '../models/node.dart';
import '../services/command_history.dart';

/// Comando para deletar um node
class DeleteNodeCommand implements TreeCommand {
  final String deletedNodeId;
  final String parentNodeId;
  final Node nodeSnapshot; // Snapshot completo do node deletado (com todos os filhos)
  final int originalIndex; // Índice original do node no parent

  DeleteNodeCommand({
    required this.deletedNodeId,
    required this.parentNodeId,
    required this.nodeSnapshot,
    required this.originalIndex,
  });

  @override
  String get commandId => 'delete_node';

  @override
  String get description => 'Deletar node "${nodeSnapshot.name}"';

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
    return _removeNodeFromTree(root, deletedNodeId);
  }

  @override
  Node undoOnTree(Node root) {
    return _restoreNodeInTree(root, parentNodeId, nodeSnapshot, originalIndex);
  }

  Node _removeNodeFromTree(Node node, String targetId) {
    // Não permite remover a raiz
    if (node.id == targetId) {
      return node;
    }

    final filteredChildren = node.children
        .where((child) => child.id != targetId)
        .map((child) => _removeNodeFromTree(child, targetId))
        .toList();

    return node.copyWith(children: filteredChildren);
  }

  Node _restoreNodeInTree(Node node, String targetParentId, Node nodeToRestore, int index) {
    if (node.id == targetParentId) {
      final newChildren = List<Node>.from(node.children);
      if (index >= 0 && index < newChildren.length) {
        newChildren.insert(index, nodeToRestore);
      } else {
        newChildren.add(nodeToRestore);
      }
      return node.copyWith(children: newChildren);
    }

    final updatedChildren = node.children
        .map((child) => _restoreNodeInTree(child, targetParentId, nodeToRestore, index))
        .toList();

    return node.copyWith(children: updatedChildren);
  }

  /// Factory constructor para criar comando a partir de Map
  /// Nota: nodeSnapshot precisa ser passado como Node completo
  factory DeleteNodeCommand.fromMap(Map<String, dynamic> args) {
    return DeleteNodeCommand(
      deletedNodeId: args['nodeId'] as String,
      parentNodeId: args['parentNodeId'] as String,
      nodeSnapshot: args['nodeSnapshot'] as Node,
      originalIndex: args['originalIndex'] as int? ?? -1,
    );
  }

  /// Retorna metadata do comando
  static CommandMetadata getMetadata() {
    return CommandMetadata(
      id: 'delete_node',
      name: 'Deletar Node',
      description: 'Remove um node e todos os seus filhos da árvore',
      parameters: [
        CommandParameter(
          name: 'nodeId',
          type: 'String',
          description: 'ID do node a ser deletado',
          required: true,
        ),
        CommandParameter(
          name: 'parentNodeId',
          type: 'String',
          description: 'ID do node pai (para undo)',
          required: false,
        ),
        CommandParameter(
          name: 'nodeSnapshot',
          type: 'Node',
          description: 'Snapshot completo do node deletado (para undo)',
          required: false,
        ),
        CommandParameter(
          name: 'originalIndex',
          type: 'int',
          description: 'Índice original do node no parent (para undo)',
          required: false,
          defaultValue: -1,
        ),
      ],
      factory: (args) => DeleteNodeCommand.fromMap(args),
    );
  }
}

