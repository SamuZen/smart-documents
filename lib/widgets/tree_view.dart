import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: _buildTreeNodes(widget.rootNode, 0),
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
        onToggle: hasChildren ? () => _toggleExpand(nodeId) : null,
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

