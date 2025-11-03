import 'command_metadata.dart';
import 'command_parameter.dart';
import '../models/node.dart';
import '../services/command_history.dart';

/// Comando para renomear um node
class RenameNodeCommand implements TreeCommand {
  final String nodeId;
  final String oldName;
  final String newName;

  RenameNodeCommand({
    required this.nodeId,
    required this.oldName,
    required this.newName,
  });

  @override
  String get commandId => 'rename_node';

  @override
  String get description => 'Renomear node "$oldName" para "$newName"';

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
    return _updateNodeInTree(root, nodeId, newName);
  }

  @override
  Node undoOnTree(Node root) {
    return _updateNodeInTree(root, nodeId, oldName);
  }

  Node _updateNodeInTree(Node node, String targetId, String newName) {
    if (node.id == targetId) {
      return node.copyWith(name: newName);
    }

    final updatedChildren = node.children
        .map((child) => _updateNodeInTree(child, targetId, newName))
        .toList();

    return node.copyWith(children: updatedChildren);
  }

  /// Factory constructor para criar comando a partir de Map
  factory RenameNodeCommand.fromMap(Map<String, dynamic> args) {
    return RenameNodeCommand(
      nodeId: args['nodeId'] as String,
      oldName: args['oldName'] as String? ?? '',
      newName: args['newName'] as String,
    );
  }

  /// Retorna metadata do comando
  static CommandMetadata getMetadata() {
    return CommandMetadata(
      id: 'rename_node',
      name: 'Renomear Node',
      description: 'Renomeia um node existente na árvore',
      parameters: [
        CommandParameter(
          name: 'nodeId',
          type: 'String',
          description: 'ID do node a ser renomeado',
          required: true,
        ),
        CommandParameter(
          name: 'newName',
          type: 'String',
          description: 'Novo nome do node',
          required: true,
        ),
        CommandParameter(
          name: 'oldName',
          type: 'String',
          description: 'Nome antigo do node (para undo)',
          required: false,
        ),
      ],
      factory: (args) => RenameNodeCommand.fromMap(args),
    );
  }
}

