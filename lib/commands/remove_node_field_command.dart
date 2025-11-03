import 'command_metadata.dart';
import 'command_parameter.dart';
import '../models/node.dart';
import '../services/command_history.dart';

/// Comando para remover um campo de um node
class RemoveNodeFieldCommand implements TreeCommand {
  final String nodeId;
  final String fieldKey;
  final dynamic removedValue; // Valor removido para poder restaurar no undo

  RemoveNodeFieldCommand({
    required this.nodeId,
    required this.fieldKey,
    required this.removedValue,
  });

  @override
  String get commandId => 'remove_node_field';

  @override
  String get description => 'Remover campo "$fieldKey"';

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
    return _removeFieldFromTree(root, nodeId, fieldKey);
  }

  @override
  Node undoOnTree(Node root) {
    return _restoreFieldInTree(root, nodeId, fieldKey, removedValue);
  }

  Node _removeFieldFromTree(Node node, String targetId, String key) {
    if (node.id == targetId) {
      final newFields = Map<String, dynamic>.from(node.fields);
      newFields.remove(key);
      return node.copyWith(fields: newFields);
    }

    final updatedChildren = node.children
        .map((child) => _removeFieldFromTree(child, targetId, key))
        .toList();

    return node.copyWith(children: updatedChildren);
  }

  Node _restoreFieldInTree(Node node, String targetId, String key, dynamic value) {
    if (node.id == targetId) {
      final newFields = Map<String, dynamic>.from(node.fields);
      newFields[key] = value;
      return node.copyWith(fields: newFields);
    }

    final updatedChildren = node.children
        .map((child) => _restoreFieldInTree(child, targetId, key, value))
        .toList();

    return node.copyWith(children: updatedChildren);
  }

  /// Factory constructor para criar comando a partir de Map
  factory RemoveNodeFieldCommand.fromMap(Map<String, dynamic> args) {
    return RemoveNodeFieldCommand(
      nodeId: args['nodeId'] as String,
      fieldKey: args['fieldKey'] as String,
      removedValue: args['removedValue'],
    );
  }

  /// Retorna metadata do comando
  static CommandMetadata getMetadata() {
    return CommandMetadata(
      id: 'remove_node_field',
      name: 'Remover Campo de Node',
      description: 'Remove um campo personalizado de um node',
      parameters: [
        CommandParameter(
          name: 'nodeId',
          type: 'String',
          description: 'ID do node',
          required: true,
        ),
        CommandParameter(
          name: 'fieldKey',
          type: 'String',
          description: 'Nome/chave do campo a ser removido',
          required: true,
        ),
        CommandParameter(
          name: 'removedValue',
          type: 'dynamic',
          description: 'Valor removido (para undo)',
          required: false,
        ),
      ],
      factory: (args) => RemoveNodeFieldCommand.fromMap(args),
    );
  }
}

