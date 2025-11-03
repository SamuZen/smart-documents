import 'command_parameter.dart';
import 'command.dart';

/// Metadata de um comando para descoberta e documentação
class CommandMetadata {
  final String id;
  final String name;
  final String description;
  final List<CommandParameter> parameters;
  final Command Function(Map<String, dynamic> args) factory;

  const CommandMetadata({
    required this.id,
    required this.name,
    required this.description,
    required this.parameters,
    required this.factory,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'parameters': parameters.map((p) => p.toJson()).toList(),
    };
  }
}

