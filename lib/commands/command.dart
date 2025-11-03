/// Interface abstrata para todos os comandos
abstract class Command {
  /// ID único do tipo de comando
  String get commandId;

  /// Descrição legível do comando
  String get description;

  /// Executa o comando
  Future<void> execute();

  /// Reverte o comando (undo)
  Future<void> undo();
}

