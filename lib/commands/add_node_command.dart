import 'command_metadata.dart';
import 'command_parameter.dart';
import '../models/node.dart';
import '../services/command_history.dart';

/// Comando para adicionar um novo node
class AddNodeCommand implements TreeCommand {
  final String parentNodeId;
  final String newNodeId;
  final String newNodeName;
  final int insertionIndex;

  AddNodeCommand({
    required this.parentNodeId,
    required this.newNodeId,
    required this.newNodeName,
    this.insertionIndex = -1, // -1 significa adicionar no final
  });

  @override
  String get commandId => 'add_node';

  @override
  String get description => 'Adicionar node "$newNodeName"';

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
    final newNode = Node(
      id: newNodeId,
      name: newNodeName,
    );

    return _addNodeToParent(root, parentNodeId, newNode, insertionIndex);
  }

  @override
  Node undoOnTree(Node root) {
    return _removeNodeFromTree(root, newNodeId);
  }

  Node _addNodeToParent(Node node, String targetParentId, Node newNode, int index) {
    if (node.id == targetParentId) {
      final newChildren = List<Node>.from(node.children);
      if (index >= 0 && index < newChildren.length) {
        newChildren.insert(index, newNode);
      } else {
        newChildren.add(newNode);
      }
      return node.copyWith(children: newChildren);
    }

    final updatedChildren = node.children
        .map((child) => _addNodeToParent(child, targetParentId, newNode, index))
        .toList();

    return node.copyWith(children: updatedChildren);
  }

  Node _removeNodeFromTree(Node node, String targetId) {
    final filteredChildren = node.children
        .where((child) => child.id != targetId)
        .map((child) => _removeNodeFromTree(child, targetId))
        .toList();

    return node.copyWith(children: filteredChildren);
  }

  /// Factory constructor para criar comando a partir de Map
  factory AddNodeCommand.fromMap(Map<String, dynamic> args) {
    return AddNodeCommand(
      parentNodeId: args['parentNodeId'] as String,
      newNodeId: args['newNodeId'] as String,
      newNodeName: args['newNodeName'] as String,
      insertionIndex: args['insertionIndex'] as int? ?? -1,
    );
  }

  /// Retorna metadata do comando
  static CommandMetadata getMetadata() {
    return CommandMetadata(
      id: 'add_node',
      name: 'Adicionar Node',
      description: 'Adiciona um novo node filho a um node pai',
      parameters: [
        CommandParameter(
          name: 'parentNodeId',
          type: 'String',
          description: 'ID do node pai onde o novo node será adicionado',
          required: true,
        ),
        CommandParameter(
          name: 'newNodeId',
          type: 'String',
          description: 'ID único do novo node',
          required: true,
        ),
        CommandParameter(
          name: 'newNodeName',
          type: 'String',
          description: 'Nome do novo node',
          required: true,
        ),
        CommandParameter(
          name: 'insertionIndex',
          type: 'int',
          description: 'Índice onde inserir o node (-1 para adicionar no final)',
          required: false,
          defaultValue: -1,
        ),
      ],
      factory: (args) => AddNodeCommand.fromMap(args),
    );
  }
}

