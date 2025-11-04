import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class AppMenuBar extends StatelessWidget {
  final VoidCallback? onNewProject;
  final VoidCallback? onOpenProject;
  final VoidCallback? onSaveProject;
  final VoidCallback? onCloseProject;
  final VoidCallback? onOpenProjectLocation;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onCreateCheckpoint;
  final VoidCallback? onManageCheckpoints;
  final bool canUndo;
  final bool canRedo;
  final String? undoDescription;
  final String? redoDescription;
  
  // View menu callbacks and states
  final VoidCallback? onToggleNavigation;
  final VoidCallback? onToggleActions;
  final VoidCallback? onToggleDocumentEditor;
  final bool showNavigation;
  final bool showActions;
  final bool showDocumentEditor;

  const AppMenuBar({
    super.key,
    this.onNewProject,
    this.onOpenProject,
    this.onSaveProject,
    this.onCloseProject,
    this.onOpenProjectLocation,
    this.onUndo,
    this.onRedo,
    this.onCreateCheckpoint,
    this.onManageCheckpoints,
    this.canUndo = false,
    this.canRedo = false,
    this.undoDescription,
    this.redoDescription,
    this.onToggleNavigation,
    this.onToggleActions,
    this.onToggleDocumentEditor,
    this.showNavigation = true,
    this.showActions = true,
    this.showDocumentEditor = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: AppTheme.surfaceNeutral, // Diferente para destacar
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderNeutral,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Menu Arquivo
          _MenuButton(
            label: 'Arquivo',
            menuItems: [
              _MenuItem(
                icon: Icons.add,
                label: 'Novo Projeto',
                onPressed: onNewProject,
              ),
              _MenuItem(
                icon: Icons.folder_open,
                label: 'Abrir Projeto',
                onPressed: onOpenProject,
              ),
              _MenuItem(
                icon: Icons.save,
                label: 'Salvar Projeto',
                onPressed: onSaveProject,
              ),
              const _MenuDivider(),
              _MenuItem(
                icon: Icons.close,
                label: 'Fechar Projeto',
                onPressed: onCloseProject,
              ),
              const _MenuDivider(),
              _MenuItem(
                icon: Icons.folder,
                label: 'Abrir Localização do Projeto',
                onPressed: onOpenProjectLocation,
                enabled: onOpenProjectLocation != null,
              ),
            ],
          ),
          // Menu Editar
          _MenuButton(
            label: 'Editar',
            menuItems: [
              _MenuItem(
                icon: Icons.undo,
                label: undoDescription ?? 'Desfazer',
                onPressed: canUndo ? onUndo : null,
                enabled: canUndo,
              ),
              _MenuItem(
                icon: Icons.redo,
                label: redoDescription ?? 'Refazer',
                onPressed: canRedo ? onRedo : null,
                enabled: canRedo,
              ),
              const _MenuDivider(),
              _MenuItem(
                icon: Icons.bookmark_add,
                label: 'Criar Checkpoint...',
                onPressed: onCreateCheckpoint,
              ),
              _MenuItem(
                icon: Icons.bookmarks,
                label: 'Gerenciar Checkpoints...',
                onPressed: onManageCheckpoints,
              ),
            ],
          ),
          // Menu View
          _MenuButton(
            label: 'View',
            menuItems: [
              _MenuItem(
                icon: showNavigation ? Icons.check_box : Icons.check_box_outline_blank,
                label: 'Navegação',
                onPressed: onToggleNavigation,
              ),
              _MenuItem(
                icon: showActions ? Icons.check_box : Icons.check_box_outline_blank,
                label: 'Ações',
                onPressed: onToggleActions,
              ),
              _MenuItem(
                icon: showDocumentEditor ? Icons.check_box : Icons.check_box_outline_blank,
                label: 'Editor de Documento',
                onPressed: onToggleDocumentEditor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatefulWidget {
  final String label;
  final List<dynamic> menuItems;

  const _MenuButton({
    required this.label,
    required this.menuItems,
  });

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  bool _isHovered = false;
  bool _isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      onOpen: () => setState(() => _isMenuOpen = true),
      onClose: () => setState(() => _isMenuOpen = false),
      menuChildren: widget.menuItems.map((item) {
        if (item is _MenuDivider) {
          return const Divider();
        }
        if (item is _MenuItem) {
          // Para itens do menu View, mostra o ícone de checkbox com cor especial
          final showCheckIcon = item.icon == Icons.check_box || item.icon == Icons.check_box_outline_blank;
          return MenuItemButton(
            leadingIcon: showCheckIcon 
                ? Icon(
                    item.icon == Icons.check_box ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 16,
                    color: item.icon == Icons.check_box ? AppTheme.neonBlue : AppTheme.textSecondary,
                  )
                : Icon(item.icon, size: 16),
            onPressed: item.enabled ? item.onPressed : null,
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: 13,
                color: item.enabled ? null : AppTheme.textTertiary,
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      }).toList(),
      builder: (context, controller, child) {
        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: (_isHovered || _isMenuOpen)
                    ? AppTheme.surfaceVariantDark // Destaque mais sutil
                    : Colors.transparent,
              ),
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                  fontWeight: _isHovered || _isMenuOpen ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.onPressed,
    this.enabled = true,
  });
}

class _MenuDivider {
  const _MenuDivider();
}

