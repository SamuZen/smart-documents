import 'dart:math';
import '../models/node.dart';
import 'checkpoint.dart';
import 'command_history.dart';

/// Gerenciador de checkpoints para salvar e restaurar estados da árvore
class CheckpointManager {
  final List<Checkpoint> _checkpoints = [];
  final int _maxCheckpoints = 10;
  
  Function(Node)? onTreeChanged;
  CommandHistory? _commandHistory;

  /// Define o CommandHistory para limpar histórico ao restaurar
  void setCommandHistory(CommandHistory commandHistory) {
    _commandHistory = commandHistory;
  }

  /// Cria um novo checkpoint
  Future<String> createCheckpoint(String? name, Node treeSnapshot) async {
    // Cria snapshot profundo da árvore (cópia completa)
    final snapshot = _deepCopyNode(treeSnapshot);
    
    final checkpoint = Checkpoint(
      id: _generateId(),
      name: name,
      timestamp: DateTime.now(),
      treeSnapshot: snapshot,
    );

    // Adiciona checkpoint
    _checkpoints.add(checkpoint);

    // Limita número de checkpoints
    if (_checkpoints.length > _maxCheckpoints) {
      _checkpoints.removeAt(0); // Remove o mais antigo
    }

    print('✅ Checkpoint criado: ${checkpoint.id}${name != null ? " ($name)" : ""}');
    return checkpoint.id;
  }

  /// Restaura um checkpoint
  Future<void> restoreCheckpoint(String checkpointId) async {
    final checkpoint = _checkpoints.firstWhere(
      (cp) => cp.id == checkpointId,
      orElse: () => throw ArgumentError('Checkpoint não encontrado: $checkpointId'),
    );

    // Cria cópia profunda do snapshot
    final restoredTree = _deepCopyNode(checkpoint.treeSnapshot);

    // Limpa histórico de undo/redo
    _commandHistory?.clear();

    // Notifica mudança na árvore
    onTreeChanged?.call(restoredTree);

    print('✅ Checkpoint restaurado: ${checkpoint.id}${checkpoint.name != null ? " (${checkpoint.name})" : ""}');
  }

  /// Remove um checkpoint
  Future<void> deleteCheckpoint(String checkpointId) async {
    final initialLength = _checkpoints.length;
    _checkpoints.removeWhere((cp) => cp.id == checkpointId);
    if (_checkpoints.length == initialLength) {
      throw ArgumentError('Checkpoint não encontrado: $checkpointId');
    }
    print('✅ Checkpoint removido: $checkpointId');
  }

  /// Lista todos os checkpoints
  List<Checkpoint> getAllCheckpoints() {
    return List.unmodifiable(_checkpoints);
  }

  /// Obtém um checkpoint específico
  Checkpoint? getCheckpoint(String checkpointId) {
    try {
      return _checkpoints.firstWhere((cp) => cp.id == checkpointId);
    } catch (e) {
      return null;
    }
  }

  /// Limpa todos os checkpoints
  void clearCheckpoints() {
    _checkpoints.clear();
    print('✅ Todos os checkpoints foram limpos');
  }

  /// Cria cópia profunda de um Node (recursivo)
  Node _deepCopyNode(Node node) {
    final copiedChildren = node.children.map((child) => _deepCopyNode(child)).toList();
    return Node(
      id: node.id,
      name: node.name,
      children: copiedChildren,
    );
  }

  /// Gera ID único para checkpoint
  String _generateId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomNum = random.nextInt(10000);
    return 'checkpoint_${timestamp}_$randomNum';
  }
}

