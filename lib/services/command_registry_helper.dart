import 'command_registry.dart';
import '../commands/rename_node_command.dart';
import '../commands/add_node_command.dart';
import '../commands/delete_node_command.dart';
import '../commands/reorder_node_command.dart';
import '../commands/move_node_command.dart';
import '../commands/set_node_field_command.dart';
import '../commands/remove_node_field_command.dart';

/// Helper para registrar todos os comandos no CommandRegistry
class CommandRegistryHelper {
  static void registerAllCommands() {
    final registry = CommandRegistry.instance;
    
    // Registra todos os comandos
    registry.registerCommand(RenameNodeCommand.getMetadata());
    registry.registerCommand(AddNodeCommand.getMetadata());
    registry.registerCommand(DeleteNodeCommand.getMetadata());
    registry.registerCommand(ReorderNodeCommand.getMetadata());
    registry.registerCommand(MoveNodeCommand.getMetadata());
    registry.registerCommand(SetNodeFieldCommand.getMetadata());
    registry.registerCommand(RemoveNodeFieldCommand.getMetadata());
    
    print('✅ Todos os comandos foram registrados no CommandRegistry');
  }
}

