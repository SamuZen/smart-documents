import 'package:flutter/material.dart';
import '../models/action_item.dart';
import '../models/node.dart';

class ActionsPanel extends StatefulWidget {
  final Node? selectedNode;
  final bool isEditing;
  final bool? isExpanded; // null se não aplicável ou desconhecido

  const ActionsPanel({
    super.key,
    this.selectedNode,
    this.isEditing = false,
    this.isExpanded,
  });

  @override
  State<ActionsPanel> createState() => _ActionsPanelState();
}

class _ActionsPanelState extends State<ActionsPanel> {
  final TextEditingController _searchController = TextEditingController();
  final Set<ActionCategory> _visibleCategories = {
    ActionCategory.keyboard,
    ActionCategory.mouse,
    ActionCategory.context,
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ActionItem> _generateActions() {
    if (widget.selectedNode == null) {
      return [];
    }

    final node = widget.selectedNode!;
    final hasChildren = !node.isLeaf;
    final actions = <ActionItem>[];

    // Ações de Teclado - Sempre disponíveis (quando um node está selecionado)
    actions.addAll([
      ActionItem(
        id: 'edit',
        name: 'Editar nome',
        description: 'Editar o nome do node selecionado',
        icon: Icons.edit,
        shortcut: 'F2',
        category: ActionCategory.keyboard,
        available: !widget.isEditing,
      ),
      ActionItem(
        id: 'navigate-up',
        name: 'Navegar para cima',
        description: 'Selecionar o node anterior',
        icon: Icons.arrow_upward,
        shortcut: '↑',
        category: ActionCategory.keyboard,
        available: !widget.isEditing,
      ),
      ActionItem(
        id: 'navigate-down',
        name: 'Navegar para baixo',
        description: 'Selecionar o próximo node',
        icon: Icons.arrow_downward,
        shortcut: '↓',
        category: ActionCategory.keyboard,
        available: !widget.isEditing,
      ),
      ActionItem(
        id: 'collapse',
        name: 'Colapsar',
        description: 'Colapsar o node selecionado',
        icon: Icons.chevron_left,
        shortcut: '←',
        category: ActionCategory.keyboard,
        available: !widget.isEditing && hasChildren && (widget.isExpanded ?? false),
        condition: hasChildren ? 'Apenas se o node estiver expandido' : null,
      ),
      ActionItem(
        id: 'expand',
        name: 'Expandir',
        description: 'Expandir o node selecionado',
        icon: Icons.chevron_right,
        shortcut: '→',
        category: ActionCategory.keyboard,
        available: !widget.isEditing && hasChildren && !(widget.isExpanded ?? false),
        condition: hasChildren ? 'Apenas se o node estiver colapsado' : null,
      ),
      ActionItem(
        id: 'navigate-up-non-leaf',
        name: 'Navegar para node não-leaf anterior',
        description: 'Navegar para o node não-leaf anterior',
        icon: Icons.skip_previous,
        shortcut: 'Ctrl+↑',
        category: ActionCategory.keyboard,
        available: !widget.isEditing,
      ),
      ActionItem(
        id: 'navigate-down-non-leaf',
        name: 'Navegar para próximo node não-leaf',
        description: 'Navegar para o próximo node não-leaf',
        icon: Icons.skip_next,
        shortcut: 'Ctrl+↓',
        category: ActionCategory.keyboard,
        available: !widget.isEditing,
      ),
    ]);

    // Ações de Teclado - Condicionais (apenas quando em modo de edição)
    if (widget.isEditing) {
      actions.addAll([
        ActionItem(
          id: 'confirm-edit',
          name: 'Confirmar edição',
          description: 'Salvar as alterações do nome',
          icon: Icons.check,
          shortcut: 'Enter',
          category: ActionCategory.keyboard,
          available: true,
        ),
        ActionItem(
          id: 'cancel-edit',
          name: 'Cancelar edição',
          description: 'Descartar as alterações do nome',
          icon: Icons.cancel,
          shortcut: 'ESC',
          category: ActionCategory.keyboard,
          available: true,
        ),
      ]);
    }

    // Ações de Mouse/Clique
    actions.addAll([
      ActionItem(
        id: 'click-select',
        name: 'Clique no node',
        description: 'Selecionar o node',
        icon: Icons.touch_app,
        category: ActionCategory.mouse,
        available: true,
      ),
      ActionItem(
        id: 'click-toggle',
        name: 'Clique na seta',
        description: 'Expandir ou colapsar o node',
        icon: Icons.chevron_right,
        category: ActionCategory.mouse,
        available: hasChildren,
        condition: hasChildren ? null : 'Apenas se o node tiver filhos',
      ),
    ]);

    // Ações Contextuais
    actions.addAll([
      ActionItem(
        id: 'info-id',
        name: 'ID do node',
        description: 'Identificador único do node',
        icon: Icons.tag,
        category: ActionCategory.context,
        available: true,
      ),
      ActionItem(
        id: 'info-name',
        name: 'Nome do node',
        description: 'Nome atual do node',
        icon: Icons.text_fields,
        category: ActionCategory.context,
        available: true,
      ),
      ActionItem(
        id: 'info-children-count',
        name: 'Número de filhos',
        description: 'Quantidade de filhos do node',
        icon: Icons.account_tree,
        category: ActionCategory.context,
        available: true,
      ),
      ActionItem(
        id: 'info-is-leaf',
        name: 'É um node folha',
        description: 'Indica se o node não possui filhos',
        icon: node.isLeaf ? Icons.insert_drive_file : Icons.folder,
        category: ActionCategory.context,
        available: true,
      ),
    ]);

    return actions;
  }

  List<ActionItem> _filterActions(List<ActionItem> actions) {
    var filtered = actions;

    // Filtro por categoria
    filtered = filtered.where((action) => _visibleCategories.contains(action.category)).toList();

    // Filtro por busca
    final searchText = _searchController.text.toLowerCase().trim();
    if (searchText.isNotEmpty) {
      filtered = filtered.where((action) {
        return action.name.toLowerCase().contains(searchText) ||
            action.description.toLowerCase().contains(searchText) ||
            (action.shortcut?.toLowerCase().contains(searchText) ?? false);
      }).toList();
    }

    return filtered;
  }

  String _getCategoryName(ActionCategory category) {
    switch (category) {
      case ActionCategory.keyboard:
        return 'Teclado';
      case ActionCategory.mouse:
        return 'Mouse';
      case ActionCategory.context:
        return 'Contexto';
    }
  }

  IconData _getCategoryIcon(ActionCategory category) {
    switch (category) {
      case ActionCategory.keyboard:
        return Icons.keyboard;
      case ActionCategory.mouse:
        return Icons.mouse;
      case ActionCategory.context:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allActions = _generateActions();
    final filteredActions = _filterActions(allActions);

    return Column(
      children: [
        // Header com busca e filtros
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // Campo de busca
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar ações...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              // Filtros por categoria
              Wrap(
                spacing: 8,
                children: ActionCategory.values.map((category) {
                  final isVisible = _visibleCategories.contains(category);
                  return FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getCategoryIcon(category), size: 16),
                        const SizedBox(width: 4),
                        Text(_getCategoryName(category)),
                      ],
                    ),
                    selected: isVisible,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _visibleCategories.add(category);
                        } else {
                          _visibleCategories.remove(category);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        // Lista de ações
        Expanded(
          child: widget.selectedNode == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum item selecionado',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : filteredActions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.filter_alt_off,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhuma ação encontrada',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tente ajustar os filtros',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: filteredActions.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final action = filteredActions[index];
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            action.icon,
                            size: 20,
                            color: action.available
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[400],
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  action.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: action.available
                                        ? null
                                        : Colors.grey[500],
                                  ),
                                ),
                              ),
                              if (action.shortcut != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: action.available
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primaryContainer
                                        : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    action.shortcut!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: action.available
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                action.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: action.available
                                      ? Colors.grey[700]
                                      : Colors.grey[500],
                                ),
                              ),
                              if (action.condition != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 12,
                                        color: Colors.grey[500],
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          action.condition!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              // Informações contextuais para ações de contexto
                              if (action.category == ActionCategory.context)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: _buildContextValue(action),
                                ),
                            ],
                          ),
                          enabled: action.available,
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildContextValue(ActionItem action) {
    if (widget.selectedNode == null) return const SizedBox.shrink();

    final node = widget.selectedNode!;
    String value = '';

    switch (action.id) {
      case 'info-id':
        value = node.id;
        break;
      case 'info-name':
        value = node.name;
        break;
      case 'info-children-count':
        value = '${node.children.length} ${node.children.length == 1 ? 'filho' : 'filhos'}';
        break;
      case 'info-is-leaf':
        value = node.isLeaf ? 'Sim' : 'Não';
        break;
    }

    if (value.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Text(
            'Valor: ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
