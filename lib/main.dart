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

  void _handleNodeReordered(String draggedNodeId, String targetNodeId, bool insertBefore) {
    developer.log('MyHomePage: _handleNodeReordered chamado. draggedNodeId: $draggedNodeId, targetNodeId: $targetNodeId, insertBefore: $insertBefore');
    
    // A TreeView já atualizou localmente, precisamos atualizar a raiz também
    // Mas a TreeView já fez a atualização interna, então só precisamos sincronizar
    // Vamos atualizar a raiz para refletir a mudança
    setState(() {
      // A árvore já foi atualizada internamente no TreeView, mas precisamos garantir
      // que o estado aqui também seja atualizado. Como o TreeView gerencia seu próprio estado,
      // vamos usar o didUpdateWidget para sincronizar.
      // Por enquanto, vamos atualizar diretamente através de uma busca recursiva
      _rootNode = _reorderNodeInTree(_rootNode, draggedNodeId, targetNodeId, insertBefore);
    });
  }

  void _handleNodeParentChanged(String draggedNodeId, String newParentId) {
    developer.log('MyHomePage: _handleNodeParentChanged chamado. draggedNodeId: $draggedNodeId, newParentId: $newParentId');
    
    // A TreeView já atualizou localmente, precisamos sincronizar com a raiz
    setState(() {
      _rootNode = _moveNodeToParent(_rootNode, draggedNodeId, newParentId);
    });
  }

  Node _moveNodeToParent(Node root, String draggedNodeId, String newParentId) {
    // Encontra o node a ser movido
    final nodeToMove = root.findById(draggedNodeId);
    if (nodeToMove == null) {
      return root; // Node não encontrado, retorna sem alterações
    }
    
    // Remove o node da árvore
    Node removeNode(Node node) {
      final updatedChildren = node.children
          .where((child) => child.id != draggedNodeId)
          .map((child) => removeNode(child))
          .toList();
      
      return node.copyWith(children: updatedChildren);
    }
    
    // Adiciona o node como filho do novo parent
    Node addToParent(Node node, Node nodeToAdd) {
      if (node.id == newParentId) {
        final newChildren = List<Node>.from(node.children)..add(nodeToAdd);
        return node.copyWith(children: newChildren);
      }
      
      final updatedChildren = node.children
          .map((child) => addToParent(child, nodeToAdd))
          .toList();
      
      return node.copyWith(children: updatedChildren);
    }
    
    var updatedRoot = removeNode(root);
    updatedRoot = addToParent(updatedRoot, nodeToMove);
    
    return updatedRoot;
  }

  Node _reorderNodeInTree(Node node, String draggedNodeId, String targetNodeId, bool insertBefore) {
    // Verifica se algum filho direto precisa ser reordenado
    final draggedIndex = node.children.indexWhere((child) => child.id == draggedNodeId);
    final targetIndex = node.children.indexWhere((child) => child.id == targetNodeId);
    
    if (draggedIndex != -1 && targetIndex != -1) {
      // Reordena os filhos
      final children = List<Node>.from(node.children);
      final draggedNode = children.removeAt(draggedIndex);
      final newTargetIndex = targetIndex > draggedIndex ? targetIndex - 1 : targetIndex;
      final insertIndex = insertBefore ? newTargetIndex : newTargetIndex + 1;
      children.insert(insertIndex.clamp(0, children.length), draggedNode);
      return node.copyWith(children: children);
    }
    
    // Procura recursivamente nos filhos
    final updatedChildren = node.children.map((child) => 
      _reorderNodeInTree(child, draggedNodeId, targetNodeId, insertBefore)
    ).toList();
    
    return node.copyWith(children: updatedChildren);
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
                onNodeReordered: _handleNodeReordered,
                onNodeParentChanged: _handleNodeParentChanged,
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
