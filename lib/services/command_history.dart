import '../commands/command.dart';
import '../models/node.dart';
import 'checkpoint_manager.dart';

/// Gerenciador de histórico de comandos para undo/redo
class CommandHistory {
  final List<Command> _undoStack = [];
  final List<Command> _redoStack = [];
  final int _maxHistorySize = 100;
  
  Function(Node)? onTreeChanged;
  Function()? onHistoryChanged;
  
  CheckpointManager? _checkpointManager;

  /// Define o CheckpointManager para criar checkpoints
  void setCheckpointManager(CheckpointManager checkpointManager) {
    _checkpointManager = checkpointManager;
  }

  /// Executa um comando e adiciona à pilha de undo
  Future<void> execute(Command command, Node currentTree) async {
    try {
      // Executa o comando na árvore
      final updatedTree = _executeCommandOnTree(command, currentTree);
      
      // Adiciona à pilha de undo
      _undoStack.add(command);
      
      // Limita o tamanho do histórico
      if (_undoStack.length > _maxHistorySize) {
        _undoStack.removeAt(0);
      }
      
      // Limpa pilha de redo quando novo comando é executado
      _redoStack.clear();
      
      // Notifica mudanças na árvore
      onTreeChanged?.call(updatedTree);
      
      // Notifica mudanças no histórico
      _notifyHistoryChanged();
    } catch (e) {
      print('❌ Erro ao executar comando: $e');
      rethrow;
    }
  }

  /// Desfaz o último comando
  Future<void> undo(Node currentTree) async {
    if (!canUndo) {
      return;
    }

    try {
      // Remove último comando da pilha undo
      final command = _undoStack.removeLast();
      
      // Executa undo na árvore
      final updatedTree = _undoCommandOnTree(command, currentTree);
      
      // Move para pilha redo
      _redoStack.add(command);
      
      // Notifica mudanças na árvore
      onTreeChanged?.call(updatedTree);
      
      // Notifica mudanças no histórico
      _notifyHistoryChanged();
    } catch (e) {
      print('❌ Erro ao desfazer comando: $e');
      rethrow;
    }
  }

  /// Refaz o último comando desfeito
  Future<void> redo(Node currentTree) async {
    if (!canRedo) {
      return;
    }

    try {
      // Remove último comando da pilha redo
      final command = _redoStack.removeLast();
      
      // Reexecuta o comando na árvore
      final updatedTree = _executeCommandOnTree(command, currentTree);
      
      // Move de volta para pilha undo
      _undoStack.add(command);
      
      // Notifica mudanças na árvore
      onTreeChanged?.call(updatedTree);
      
      // Notifica mudanças no histórico
      _notifyHistoryChanged();
    } catch (e) {
      print('❌ Erro ao refazer comando: $e');
      rethrow;
    }
  }

  /// Executa comando em uma árvore (método helper)
  Node _executeCommandOnTree(Command command, Node tree) {
    // Usa dynamic casting para acessar métodos específicos
    if (command is TreeCommand) {
      return command.executeOnTree(tree);
    }
    // Fallback para comandos que implementam execute diretamente
    command.execute();
    return tree;
  }

  /// Reverte comando em uma árvore (método helper)
  Node _undoCommandOnTree(Command command, Node tree) {
    // Usa dynamic casting para acessar métodos específicos
    if (command is TreeCommand) {
      return command.undoOnTree(tree);
    }
    // Fallback para comandos que implementam undo diretamente
    command.undo();
    return tree;
  }

  /// Verifica se pode desfazer
  bool get canUndo => _undoStack.isNotEmpty;

  /// Verifica se pode refazer
  bool get canRedo => _redoStack.isNotEmpty;

  /// Descrição do próximo undo
  String? get undoDescription {
    if (!canUndo) return null;
    return _undoStack.last.description;
  }

  /// Descrição do próximo redo
  String? get redoDescription {
    if (!canRedo) return null;
    return _redoStack.last.description;
  }

  /// Limpa todo o histórico
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    _notifyHistoryChanged();
  }

  /// Cria um checkpoint (delega para CheckpointManager)
  Future<String> createCheckpoint(String? name, Node treeSnapshot) async {
    if (_checkpointManager == null) {
      throw StateError('CheckpointManager não foi definido');
    }
    return await _checkpointManager!.createCheckpoint(name, treeSnapshot);
  }

  void _notifyHistoryChanged() {
    onHistoryChanged?.call();
  }
}

/// Interface para comandos que operam diretamente na árvore
abstract class TreeCommand implements Command {
  Node executeOnTree(Node tree);
  Node undoOnTree(Node tree);
}

