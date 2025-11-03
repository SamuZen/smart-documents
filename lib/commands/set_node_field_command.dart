import 'command_metadata.dart';
import 'command_parameter.dart';
import '../models/node.dart';
import '../services/command_history.dart';

/// Comando para adicionar ou modificar um campo de um node
class SetNodeFieldCommand implements TreeCommand {
  final String nodeId;
  final String fieldKey;
  final dynamic newValue;
  final dynamic oldValue; // null se é novo campo, ou valor anterior se está modificando

  SetNodeFieldCommand({
    required this.nodeId,
    required this.fieldKey,
    required this.newValue,
    this.oldValue,
  });

  @override
  String get commandId => 'set_node_field';

  @override
  String get description => '${oldValue == null ? "Adicionar" : "Modificar"} campo "$fieldKey"';

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
    return _setFieldInTree(root, nodeId, fieldKey, newValue);
  }

  @override
  Node undoOnTree(Node root) {
    if (oldValue == null) {
      // Se era um campo novo, remove ao fazer undo
      return _removeFieldFromTree(root, nodeId, fieldKey);
    } else {
      // Se estava modificando, restaura valor antigo
      return _setFieldInTree(root, nodeId, fieldKey, oldValue);
    }
  }

  Node _setFieldInTree(Node node, String targetId, String key, dynamic value) {
    if (node.id == targetId) {
      final newFields = Map<String, dynamic>.from(node.fields);
      newFields[key] = value;
      return node.copyWith(fields: newFields);
    }

    final updatedChildren = node.children
        .map((child) => _setFieldInTree(child, targetId, key, value))
        .toList();

    return node.copyWith(children: updatedChildren);
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

  /// Factory constructor para criar comando a partir de Map
  factory SetNodeFieldCommand.fromMap(Map<String, dynamic> args) {
    return SetNodeFieldCommand(
      nodeId: args['nodeId'] as String,
      fieldKey: args['fieldKey'] as String,
      newValue: args['newValue'],
      oldValue: args['oldValue'],
    );
  }

  /// Retorna metadata do comando
  static CommandMetadata getMetadata() {
    return CommandMetadata(
      id: 'set_node_field',
      name: 'Definir Campo de Node',
      description: 'Adiciona ou modifica um campo personalizado de um node',
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
          description: 'Nome/chave do campo',
          required: true,
        ),
        CommandParameter(
          name: 'newValue',
          type: 'dynamic',
          description: 'Novo valor do campo',
          required: true,
        ),
        CommandParameter(
          name: 'oldValue',
          type: 'dynamic',
          description: 'Valor anterior (null se é novo campo)',
          required: false,
        ),
      ],
      factory: (args) => SetNodeFieldCommand.fromMap(args),
    );
  }
}

