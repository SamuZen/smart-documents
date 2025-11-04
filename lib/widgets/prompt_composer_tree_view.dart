import 'package:flutter/material.dart';
import '../models/node.dart';
import '../theme/app_theme.dart';
import 'prompt_composer_tree_node_tile.dart';

class PromptComposerTreeView extends StatefulWidget {
  final Node rootNode;
  final Function(Set<String> selectedNodeIds)? onSelectionChanged;
  final Set<String>? initialSelection; // Seleções iniciais para restaurar estado

  const PromptComposerTreeView({
    super.key,
    required this.rootNode,
    this.onSelectionChanged,
    this.initialSelection,
  });

  @override
  State<PromptComposerTreeView> createState() => _PromptComposerTreeViewState();
}

class _PromptComposerTreeViewState extends State<PromptComposerTreeView> {
  final Set<String> _expandedNodes = {};
  final Set<String> _selectedNodeIds = {};

  @override
  void initState() {
    super.initState();
    // Expande todos os nodes ao inicializar
    _expandAllNodes();
    
    // Restaura seleções iniciais se fornecidas
    if (widget.initialSelection != null) {
      _selectedNodeIds.addAll(widget.initialSelection!);
    }
  }

  /// Expande todos os nodes recursivamente
  void _expandAllNodes() {
    void expandNodeRecursive(Node node) {
      if (node.children.isNotEmpty) {
        _expandedNodes.add(node.id);
        for (final child in node.children) {
          expandNodeRecursive(child);
        }
      }
    }

    expandNodeRecursive(widget.rootNode);
  }

  @override
  void didUpdateWidget(PromptComposerTreeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sincroniza quando rootNode muda
    if (oldWidget.rootNode.id != widget.rootNode.id ||
        oldWidget.rootNode.name != widget.rootNode.name) {
      _expandAllNodes();
    }
    // Atualiza seleções quando initialSelection muda
    // Compara o conteúdo dos sets, não apenas a referência
    if (widget.initialSelection != null) {
      final currentSet = Set<String>.from(_selectedNodeIds);
      final newSet = Set<String>.from(widget.initialSelection!);
      
      // Verifica se há diferença no conteúdo
      if (currentSet.length != newSet.length || 
          !currentSet.containsAll(newSet) ||
          !newSet.containsAll(currentSet)) {
        _selectedNodeIds.clear();
        _selectedNodeIds.addAll(widget.initialSelection!);
        setState(() {});
      }
    } else if (_selectedNodeIds.isNotEmpty) {
      // Se initialSelection foi removido, limpa seleções
      _selectedNodeIds.clear();
      setState(() {});
    }
  }

  void _toggleExpand(String nodeId) {
    setState(() {
      if (_expandedNodes.contains(nodeId)) {
        _expandedNodes.remove(nodeId);
      } else {
        _expandedNodes.add(nodeId);
      }
    });
  }

  bool _isExpanded(String nodeId) {
    return _expandedNodes.contains(nodeId);
  }

  void _toggleSelection(String nodeId) {
    setState(() {
      if (_selectedNodeIds.contains(nodeId)) {
        _selectedNodeIds.remove(nodeId);
      } else {
        _selectedNodeIds.add(nodeId);
      }
    });

    // Notifica mudança de seleção
    if (widget.onSelectionChanged != null) {
      widget.onSelectionChanged!(Set<String>.from(_selectedNodeIds));
    }
  }

  bool _isSelected(String nodeId) {
    return _selectedNodeIds.contains(nodeId);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
      ),
      child: ListView(
        padding: const EdgeInsets.all(8.0),
        children: _buildTreeNodes(widget.rootNode, 0),
      ),
    );
  }

  List<Widget> _buildTreeNodes(Node node, int depth) {
    final List<Widget> widgets = [];
    final isExpanded = _isExpanded(node.id);
    final hasChildren = !node.isLeaf;
    final nodeId = node.id;
    final isSelected = _isSelected(nodeId);

    // Adiciona o próprio node
    widgets.add(
      InkWell(
        onTap: () => _toggleSelection(nodeId),
        child: PromptComposerTreeNodeTile(
          key: ValueKey(nodeId),
          node: node,
          depth: depth,
          isExpanded: isExpanded,
          hasChildren: hasChildren,
          isSelected: isSelected,
          onToggle: hasChildren ? () => _toggleExpand(nodeId) : null,
          onCheckboxChanged: (value) => _toggleSelection(nodeId),
        ),
      ),
    );

    // Adiciona recursivamente os filhos apenas se expandido
    if (hasChildren && isExpanded) {
      for (final child in node.children) {
        widgets.addAll(_buildTreeNodes(child, depth + 1));
      }
    }

    return widgets;
  }
}

