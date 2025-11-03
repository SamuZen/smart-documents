/// Define um parâmetro de comando para descoberta e validação
class CommandParameter {
  final String name;
  final String type; // 'String', 'int', 'bool', 'Node', etc.
  final String description;
  final bool required;
  final dynamic defaultValue;

  const CommandParameter({
    required this.name,
    required this.type,
    required this.description,
    this.required = true,
    this.defaultValue,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'description': description,
      'required': required,
      'defaultValue': defaultValue,
    };
  }
}

