import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppMenuBar extends StatelessWidget {
  final VoidCallback? onNewProject;
  final VoidCallback? onOpenProject;
  final VoidCallback? onSaveProject;
  final VoidCallback? onCloseProject;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onCreateCheckpoint;
  final bool canUndo;
  final bool canRedo;
  final String? undoDescription;
  final String? redoDescription;

  const AppMenuBar({
    super.key,
    this.onNewProject,
    this.onOpenProject,
    this.onSaveProject,
    this.onCloseProject,
    this.onUndo,
    this.onRedo,
    this.onCreateCheckpoint,
    this.canUndo = false,
    this.canRedo = false,
    this.undoDescription,
    this.redoDescription,
  });

  @override
  Widget build(BuildContext context) {
    return MenuBar(
      children: [
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              leadingIcon: const Icon(Icons.add),
              onPressed: onNewProject,
              child: const Text('Novo Projeto'),
            ),
            MenuItemButton(
              leadingIcon: const Icon(Icons.folder_open),
              onPressed: onOpenProject,
              child: const Text('Abrir Projeto'),
            ),
            MenuItemButton(
              leadingIcon: const Icon(Icons.save),
              onPressed: onSaveProject,
              child: const Text('Salvar Projeto'),
            ),
            const Divider(),
            MenuItemButton(
              leadingIcon: const Icon(Icons.close),
              onPressed: onCloseProject,
              child: const Text('Fechar Projeto'),
            ),
          ],
          child: const Text('Arquivo'),
        ),
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              leadingIcon: const Icon(Icons.undo),
              onPressed: canUndo ? onUndo : null,
              child: Text(undoDescription ?? 'Desfazer'),
            ),
            MenuItemButton(
              leadingIcon: const Icon(Icons.redo),
              onPressed: canRedo ? onRedo : null,
              child: Text(redoDescription ?? 'Refazer'),
            ),
            const Divider(),
            MenuItemButton(
              leadingIcon: const Icon(Icons.bookmark_add),
              onPressed: onCreateCheckpoint,
              child: const Text('Criar Checkpoint...'),
            ),
          ],
          child: const Text('Editar'),
        ),
      ],
    );
  }
}

