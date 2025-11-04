import 'command_metadata.dart';
import 'command_parameter.dart';
import '../models/node.dart';
import '../services/command_history.dart';

/// Comando para atualizar os tipos de campos de um node
class SetNodeFieldTypesCommand implements TreeCommand {
  final String nodeId;
  final Map<String, String> newFieldTypes;
  final Map<String, String> oldFieldTypes; // Tipos anteriores para undo

  SetNodeFieldTypesCommand({
    required this.nodeId,
    required this.newFieldTypes,
    required this.oldFieldTypes,
  });

  @override
  String get commandId => 'set_node_field_types';

  @override
  String get description => 'Atualizar tipos de campos';

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
    return _setFieldTypesInTree(root, nodeId, newFieldTypes);
  }

  @override
  Node undoOnTree(Node root) {
    return _setFieldTypesInTree(root, nodeId, oldFieldTypes);
  }

  Node _setFieldTypesInTree(Node node, String targetId, Map<String, String> fieldTypes) {
    if (node.id == targetId) {
      return node.copyWith(fieldTypes: fieldTypes);
    }

    final updatedChildren = node.children
        .map((child) => _setFieldTypesInTree(child, targetId, fieldTypes))
        .toList();

    return node.copyWith(children: updatedChildren);
  }

  /// Factory constructor para criar comando a partir de Map
  factory SetNodeFieldTypesCommand.fromMap(Map<String, dynamic> args) {
    return SetNodeFieldTypesCommand(
      nodeId: args['nodeId'] as String,
      newFieldTypes: Map<String, String>.from(
        (args['newFieldTypes'] as Map).map((k, v) => MapEntry(k.toString(), v.toString())),
      ),
      oldFieldTypes: Map<String, String>.from(
        (args['oldFieldTypes'] as Map).map((k, v) => MapEntry(k.toString(), v.toString())),
      ),
    );
  }

  /// Retorna metadata do comando
  static CommandMetadata getMetadata() {
    return CommandMetadata(
      id: 'set_node_field_types',
      name: 'Definir Tipos de Campos de Node',
      description: 'Atualiza os tipos dos campos personalizados de um node',
      parameters: [
        CommandParameter(
          name: 'nodeId',
          type: 'String',
          description: 'ID do node',
          required: true,
        ),
        CommandParameter(
          name: 'newFieldTypes',
          type: 'Map<String, String>',
          description: 'Novos tipos dos campos',
          required: true,
        ),
        CommandParameter(
          name: 'oldFieldTypes',
          type: 'Map<String, String>',
          description: 'Tipos anteriores dos campos',
          required: true,
        ),
      ],
      factory: (args) => SetNodeFieldTypesCommand.fromMap(args),
    );
  }
}

