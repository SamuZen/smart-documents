import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/node.dart';
import 'tree_node_tile.dart';

class TreeView extends StatefulWidget {
  final Node rootNode;

  const TreeView({
    super.key,
    required this.rootNode,
  });

  @override
  State<TreeView> createState() => _TreeViewState();
}

class _TreeViewState extends State<TreeView> {
  final Set<String> _expandedNodes = {};
  String? _selectedNodeId;
  String? _editingNodeId; // ID do nó que está em modo de edição (mock)

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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.f2): const _F2Intent(),
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
        },
        child: Focus(
          autofocus: true,
          child: ListView(
            padding: const EdgeInsets.all(8.0),
            children: _buildTreeNodes(widget.rootNode, 0),
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
      widgets.add(
        TreeNodeTile(
          key: ValueKey(nodeId),
          node: node,
          depth: depth,
          isExpanded: isExpanded,
          hasChildren: hasChildren,
          isSelected: _selectedNodeId == nodeId,
          isEditing: _editingNodeId == nodeId, // Passa informação se está editando (mock)
          onToggle: hasChildren ? () => _toggleExpand(nodeId) : null,
          onTap: () => _selectNode(nodeId),
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

