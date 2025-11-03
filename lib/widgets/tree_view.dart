import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/node.dart';
import 'tree_node_tile.dart';

class TreeView extends StatefulWidget {
  final Node rootNode;
  final Function(String nodeId, String newName)? onNodeNameChanged;

  const TreeView({
    super.key,
    required this.rootNode,
    this.onNodeNameChanged,
  });

  @override
  State<TreeView> createState() => _TreeViewState();
}

class _TreeViewState extends State<TreeView> {
  late Node _rootNode;
  final Set<String> _expandedNodes = {};
  String? _selectedNodeId;
  String? _editingNodeId;

  @override
  void initState() {
    super.initState();
    _rootNode = widget.rootNode;
  }

  @override
  void didUpdateWidget(TreeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rootNode != widget.rootNode) {
      _rootNode = widget.rootNode;
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

  void _selectNode(String? nodeId) {
    setState(() {
      _selectedNodeId = nodeId;
      // Cancela modo de edição ao selecionar outro nó
      if (_editingNodeId != null && _editingNodeId != nodeId) {
        _editingNodeId = null;
      }
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingNodeId = null;
    });
  }

  void _updateNodeName(String nodeId, String newName) {
    setState(() {
      _rootNode = _updateNodeInTree(_rootNode, nodeId, newName);
    });
    widget.onNodeNameChanged?.call(nodeId, newName);
  }

  Node _updateNodeInTree(Node node, String nodeId, String newName) {
    if (node.id == nodeId) {
      return node.copyWith(name: newName);
    }
    
    final updatedChildren = node.children.map((child) {
      return _updateNodeInTree(child, nodeId, newName);
    }).toList();
    
    return node.copyWith(children: updatedChildren);
  }

  void _confirmEditing() {
    // O salvamento é feito via onSubmitted do TextField quando o usuário pressiona Enter
    // Este método pode ser usado para outras ações futuras
    setState(() {
      _editingNodeId = null;
    });
  }

  void _handleNameChanged(String nodeId, String newName) {
    if (newName.trim().isNotEmpty) {
      _updateNodeName(nodeId, newName);
      setState(() {
        _editingNodeId = null;
      });
    }
  }

  void _handleCancelEditing() {
    setState(() {
      _editingNodeId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.f2): const _F2Intent(),
        LogicalKeySet(LogicalKeyboardKey.escape): const _CancelEditingIntent(),
        LogicalKeySet(LogicalKeyboardKey.enter): const _ConfirmEditingIntent(),
      },
      child: Actions(
        actions: {
          _F2Intent: CallbackAction<_F2Intent>(
            onInvoke: (_) {
              // Quando F2 é pressionado, ativa modo de edição (mock)
              if (_selectedNodeId != null) {
                setState(() {
                  _editingNodeId = _selectedNodeId;
                });
              }
              return null;
            },
          ),
          _CancelEditingIntent: CallbackAction<_CancelEditingIntent>(
            onInvoke: (_) {
              _cancelEditing();
              _handleCancelEditing();
              return null;
            },
          ),
          _ConfirmEditingIntent: CallbackAction<_ConfirmEditingIntent>(
            onInvoke: (_) {
              _confirmEditing();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: ListView(
            padding: const EdgeInsets.all(8.0),
            children: _buildTreeNodes(_rootNode, 0),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTreeNodes(Node node, int depth) {
    final List<Widget> widgets = [];
    final isExpanded = _isExpanded(node.id);
    final hasChildren = !node.isLeaf;
    final nodeId = node.id;

    // Adiciona o próprio node
    final isEditing = _editingNodeId == nodeId;
    
    widgets.add(
      TreeNodeTile(
        key: ValueKey(nodeId),
        node: node,
        depth: depth,
        isExpanded: isExpanded,
        hasChildren: hasChildren,
        isSelected: _selectedNodeId == nodeId,
        isEditing: isEditing,
        onToggle: hasChildren ? () => _toggleExpand(nodeId) : null,
        onTap: () => _selectNode(nodeId),
        onNameChanged: isEditing
            ? (newName) => _handleNameChanged(nodeId, newName)
            : null,
        onCancelEditing: isEditing
            ? () => _handleCancelEditing()
            : null,
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

// Intent para detectar F2
class _F2Intent extends Intent {
  const _F2Intent();
}

// Intent para cancelar edição (ESC)
class _CancelEditingIntent extends Intent {
  const _CancelEditingIntent();
}

// Intent para confirmar edição (Enter)
class _ConfirmEditingIntent extends Intent {
  const _ConfirmEditingIntent();
}

