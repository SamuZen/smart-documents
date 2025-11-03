import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'models/node.dart';
import 'services/node_service.dart';
import 'widgets/tree_view.dart';
import 'widgets/draggable_resizable_window.dart';
import 'widgets/actions_panel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Document',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 118, 206, 47)),
      ),
      home: const MyHomePage(title: 'Smart Document'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Node _rootNode;
  bool _showWindow = true;
  bool _showActionsWindow = true;
  String? _selectedNodeId;
  bool _isEditing = false;
  final Set<String> _expandedNodes = {}; // Rastreia nodes expandidos

  @override
  void initState() {
    super.initState();
    _rootNode = NodeService.createExampleStructure();
  }

  void _handleSelectionChanged(String? nodeId) {
    setState(() {
      _selectedNodeId = nodeId;
    });
  }

  void _handleEditingStateChanged(bool isEditing, String? nodeId) {
    setState(() {
      _isEditing = isEditing;
      // Se mudou a seleção durante edição, atualiza
      if (nodeId != null) {
        _selectedNodeId = nodeId;
      }
    });
  }

  void _handleExpansionChanged(String nodeId, bool isExpanded) {
    setState(() {
      if (isExpanded) {
        _expandedNodes.add(nodeId);
      } else {
        _expandedNodes.remove(nodeId);
      }
    });
  }

  Node? _getSelectedNode() {
    if (_selectedNodeId == null) return null;
    return _rootNode.findById(_selectedNodeId!);
  }

  bool? _getSelectedNodeExpansionState() {
    if (_selectedNodeId == null) return null;
    return _expandedNodes.contains(_selectedNodeId);
  }

  void _updateRootNode(String nodeId, String newName) {
    developer.log('MyHomePage: _updateRootNode chamado. nodeId: $nodeId, newName: "$newName"');
    final oldName = _rootNode.findById(nodeId)?.name ?? 'NÃO ENCONTRADO';
    developer.log('MyHomePage: Nome antigo do node: "$oldName"');
    
    setState(() {
      _rootNode = _updateNodeInTree(_rootNode, nodeId, newName);
    });
    
    final updatedName = _rootNode.findById(nodeId)?.name ?? 'NÃO ENCONTRADO';
    developer.log('MyHomePage: Após atualização, nome do node: "$updatedName"');
  }

  Node _updateNodeInTree(Node node, String nodeId, String newName) {
    developer.log('MyHomePage: _updateNodeInTree - node.id: ${node.id}, procurando: $nodeId');
    if (node.id == nodeId) {
      developer.log('MyHomePage: Node encontrado! Atualizando nome de "${node.name}" para "$newName"');
      return node.copyWith(name: newName);
    }
    
    final updatedChildren = node.children.map((child) {
      return _updateNodeInTree(child, nodeId, newName);
    }).toList();
    
    return node.copyWith(children: updatedChildren);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(_showWindow ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _showWindow = !_showWindow;
              });
            },
            tooltip: _showWindow ? 'Ocultar janela' : 'Mostrar janela',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Área principal
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.description,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Área de trabalho principal',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          // Janela flutuante com TreeView
          if (_showWindow)
            DraggableResizableWindow(
              title: 'Navegação',
              initialWidth: 300,
              initialHeight: 500,
              minWidth: 250,
              minHeight: 300,
              onClose: () {
                setState(() {
                  _showWindow = false;
                });
              },
              child: TreeView(
                rootNode: _rootNode,
                onNodeNameChanged: _updateRootNode,
                onSelectionChanged: _handleSelectionChanged,
                onEditingStateChanged: _handleEditingStateChanged,
                onExpansionChanged: _handleExpansionChanged,
              ),
            ),
          // Janela flutuante com ActionsPanel (sempre visível)
          if (_showActionsWindow)
            DraggableResizableWindow(
              title: 'Ações',
              initialWidth: 350,
              initialHeight: 500,
              minWidth: 280,
              minHeight: 300,
              onClose: () {
                setState(() {
                  _showActionsWindow = false;
                });
              },
              child: ActionsPanel(
                selectedNode: _getSelectedNode(),
                isEditing: _isEditing,
                isExpanded: _getSelectedNodeExpansionState(),
              ),
            ),
        ],
      ),
    );
  }
}
