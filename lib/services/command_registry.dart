import 'dart:convert';
import '../commands/command.dart';
import '../commands/command_metadata.dart';

/// Registro centralizado de todos os comandos disponíveis
/// Permite descoberta de comandos e criação dinâmica para integração com LLMs
class CommandRegistry {
  static final CommandRegistry _instance = CommandRegistry._internal();
  factory CommandRegistry() => _instance;
  CommandRegistry._internal();

  static CommandRegistry get instance => _instance;

  final Map<String, CommandMetadata> _commands = {};

  /// Registra um comando no registry
  void registerCommand(CommandMetadata metadata) {
    _commands[metadata.id] = metadata;
  }

  /// Retorna metadata de todos os comandos registrados
  List<CommandMetadata> getAllCommands() {
    return _commands.values.toList();
  }

  /// Obtém metadata de um comando específico
  CommandMetadata? getCommandMetadata(String commandId) {
    return _commands[commandId];
  }

  /// Cria um comando a partir de ID e argumentos
  /// Valida argumentos antes de criar
  Future<Command> createCommand(String commandId, Map<String, dynamic> args) async {
    final metadata = _commands[commandId];
    if (metadata == null) {
      throw ArgumentError('Comando não encontrado: $commandId');
    }

    // Valida argumentos
    if (!validateCommandArgs(commandId, args)) {
      throw ArgumentError('Argumentos inválidos para comando $commandId');
    }

    // Cria comando usando factory
    return metadata.factory(args);
  }

  /// Valida argumentos de um comando antes de criar
  bool validateCommandArgs(String commandId, Map<String, dynamic> args) {
    final metadata = _commands[commandId];
    if (metadata == null) return false;

    // Verifica se todos os parâmetros obrigatórios estão presentes
    for (final param in metadata.parameters) {
      if (param.required && !args.containsKey(param.name)) {
        // Se não tem valor e não tem default, é inválido
        if (args[param.name] == null && param.defaultValue == null) {
          return false;
        }
      }
    }

    // Valida tipos básicos (pode ser expandido)
    for (final entry in args.entries) {
      final param = metadata.parameters.firstWhere(
        (p) => p.name == entry.key,
        orElse: () => throw ArgumentError('Parâmetro desconhecido: ${entry.key}'),
      );

      // Validação básica de tipo
      if (param.type == 'String' && entry.value is! String) {
        return false;
      } else if (param.type == 'int' && entry.value is! int) {
        return false;
      } else if (param.type == 'bool' && entry.value is! bool) {
        return false;
      }
    }

    return true;
  }

  /// Retorna todos os comandos como JSON para integração com LLMs
  String getCommandsAsJson() {
    final commandsList = _commands.values.map((cmd) => cmd.toJson()).toList();
    return jsonEncode({
      'commands': commandsList,
      'count': commandsList.length,
    });
  }

  /// Retorna documentação de todos os comandos em Markdown
  String getCommandsAsMarkdown() {
    final buffer = StringBuffer();
    buffer.writeln('# Comandos Disponíveis\n');
    buffer.writeln('Este documento lista todos os comandos disponíveis no sistema.\n');

    for (final cmd in _commands.values) {
      buffer.writeln('## ${cmd.name} (`${cmd.id}`)\n');
      buffer.writeln('**Descrição:** ${cmd.description}\n');
      buffer.writeln('### Parâmetros\n');
      
      if (cmd.parameters.isEmpty) {
        buffer.writeln('Nenhum parâmetro.\n');
      } else {
        buffer.writeln('| Nome | Tipo | Obrigatório | Descrição |');
        buffer.writeln('|------|------|-------------|-----------|');
        for (final param in cmd.parameters) {
          final required = param.required ? 'Sim' : 'Não';
          buffer.writeln('| `${param.name}` | `${param.type}` | $required | ${param.description} |');
        }
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  /// Limpa todos os comandos registrados
  void clear() {
    _commands.clear();
  }
}

