import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppMenuBar extends StatelessWidget {
  final VoidCallback? onNewProject;
  final VoidCallback? onOpenProject;
  final VoidCallback? onSaveProject;
  final VoidCallback? onCloseProject;

  const AppMenuBar({
    super.key,
    this.onNewProject,
    this.onOpenProject,
    this.onSaveProject,
    this.onCloseProject,
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
      ],
    );
  }
}

