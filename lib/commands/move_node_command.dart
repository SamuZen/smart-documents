import 'command_metadata.dart';
import 'command_parameter.dart';
import '../models/node.dart';
import '../services/command_history.dart';

/// Comando para mover um node para outro parent
class MoveNodeCommand implements TreeCommand {
  final String draggedNodeId;
  final String oldParentId;
  final String newParentId;
  final int oldIndex; // Índice no parent antigo
  final int newIndex; // Índice no novo parent
  Node? _nodeSnapshot; // Cache do node movido (para undo)

  MoveNodeCommand({
    required this.draggedNodeId,
    required this.oldParentId,
    required this.newParentId,
    this.oldIndex = -1,
    this.newIndex = -1,
  });

  @override
  String get commandId => 'move_node';

  @override
  String get description => 'Mover node para outro parent';

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
    // Primeiro encontra o node a ser movido
    final nodeToMove = _findNodeById(root, draggedNodeId);
    if (nodeToMove == null) {
      return root; // Node não encontrado
    }
    
    // Salva snapshot para undo
    _nodeSnapshot = nodeToMove;
    
    // Remove o node do parent antigo
    var updatedTree = _removeNodeFromTree(root, draggedNodeId);
    // Adiciona ao novo parent
    return _addNodeToParent(updatedTree, newParentId, nodeToMove, newIndex);
  }

  @override
  Node undoOnTree(Node root) {
    // Usa o snapshot salvo
    if (_nodeSnapshot == null) {
      return root; // Não foi possível fazer undo
    }
    
    // Remove o node do novo parent
    var updatedTree = _removeNodeFromTree(root, draggedNodeId);
    // Restaura no parent antigo
    return _addNodeToParent(updatedTree, oldParentId, _nodeSnapshot!, oldIndex);
  }

  Node? _findNodeById(Node node, String targetId) {
    if (node.id == targetId) {
      return node;
    }
    
    for (final child in node.children) {
      final found = _findNodeById(child, targetId);
      if (found != null) {
        return found;
      }
    }
    
    return null;
  }

  Node _removeNodeFromTree(Node node, String targetId) {
    final filteredChildren = node.children
        .where((child) => child.id != targetId)
        .map((child) => _removeNodeFromTree(child, targetId))
        .toList();

    return node.copyWith(children: filteredChildren);
  }

  Node _addNodeToParent(Node node, String targetParentId, Node nodeToAdd, int index) {
    if (node.id == targetParentId) {
      final newChildren = List<Node>.from(node.children);
      if (index >= 0 && index < newChildren.length) {
        newChildren.insert(index, nodeToAdd);
      } else {
        newChildren.add(nodeToAdd);
      }
      return node.copyWith(children: newChildren);
    }

    final updatedChildren = node.children
        .map((child) => _addNodeToParent(child, targetParentId, nodeToAdd, index))
        .toList();

    return node.copyWith(children: updatedChildren);
  }

  /// Factory constructor para criar comando a partir de Map
  factory MoveNodeCommand.fromMap(Map<String, dynamic> args) {
    return MoveNodeCommand(
      draggedNodeId: args['draggedNodeId'] as String,
      oldParentId: args['oldParentId'] as String,
      newParentId: args['newParentId'] as String,
      oldIndex: args['oldIndex'] as int? ?? -1,
      newIndex: args['newIndex'] as int? ?? -1,
    );
  }

  /// Retorna metadata do comando
  static CommandMetadata getMetadata() {
    return CommandMetadata(
      id: 'move_node',
      name: 'Mover Node',
      description: 'Move um node para ser filho de outro parent',
      parameters: [
        CommandParameter(
          name: 'draggedNodeId',
          type: 'String',
          description: 'ID do node sendo movido',
          required: true,
        ),
        CommandParameter(
          name: 'newParentId',
          type: 'String',
          description: 'ID do novo node pai',
          required: true,
        ),
        CommandParameter(
          name: 'oldParentId',
          type: 'String',
          description: 'ID do node pai antigo (para undo)',
          required: false,
        ),
        CommandParameter(
          name: 'oldIndex',
          type: 'int',
          description: 'Índice original no parent antigo (para undo)',
          required: false,
          defaultValue: -1,
        ),
        CommandParameter(
          name: 'newIndex',
          type: 'int',
          description: 'Novo índice no parent novo (para undo)',
          required: false,
          defaultValue: -1,
        ),
      ],
      factory: (args) => MoveNodeCommand.fromMap(args),
    );
  }
}

