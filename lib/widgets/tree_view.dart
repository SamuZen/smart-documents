import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import '../models/node.dart';
import 'tree_node_tile.dart';

class TreeView extends StatefulWidget {
  final Node rootNode;
  final Function(String nodeId, String newName)? onNodeNameChanged;
  final Function(String? nodeId)? onSelectionChanged;
  final Function(bool isEditing, String? nodeId)? onEditingStateChanged;
  final Function(String nodeId, bool isExpanded)? onExpansionChanged;
  final Function(String draggedNodeId, String targetNodeId, bool insertBefore)? onNodeReordered;
  final Function(String draggedNodeId, String newParentId)? onNodeParentChanged;
  final Function(String parentNodeId, String newNodeId, String newNodeName)? onNodeAdded;

  const TreeView({
    super.key,
    required this.rootNode,
    this.onNodeNameChanged,
    this.onSelectionChanged,
    this.onEditingStateChanged,
    this.onExpansionChanged,
    this.onNodeReordered,
    this.onNodeParentChanged,
    this.onNodeAdded,
  });

  @override
  State<TreeView> createState() => _TreeViewState();
}

class _TreeViewState extends State<TreeView> {
  late Node _rootNode;
  final Set<String> _expandedNodes = {};
  String? _selectedNodeId;
  String? _editingNodeId;
  final FocusNode _treeFocusNode = FocusNode();
  String? _draggedNodeId;
  String? _draggedOverNodeId; // Node sobre o qual está passando o mouse
  bool _insertBefore = true; // Se deve inserir antes ou depois do target

  @override
  void initState() {
    super.initState();
    _rootNode = widget.rootNode;
  }

  @override
  void dispose() {
    _treeFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TreeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sincroniza _rootNode com widget.rootNode apenas se realmente mudou
    // Compara a estrutura para evitar sobrescrever mudanças locais não sincronizadas
    if (!_areTreesEqual(_rootNode, widget.rootNode)) {
      developer.log('TreeView: didUpdateWidget - Root mudou externamente. Sincronizando.');
      _rootNode = widget.rootNode;
    }
  }

  // Compara duas árvores para verificar se são iguais (estrutura e conteúdo)
  bool _areTreesEqual(Node node1, Node node2) {
    if (node1.id != node2.id || node1.name != node2.name) {
      return false;
    }
    if (node1.children.length != node2.children.length) {
      return false;
    }
    for (int i = 0; i < node1.children.length; i++) {
      if (!_areTreesEqual(node1.children[i], node2.children[i])) {
        return false;
      }
    }
    return true;
  }

  void _toggleExpand(String nodeId) {
    final wasExpanded = _expandedNodes.contains(nodeId);
    setState(() {
      if (_expandedNodes.contains(nodeId)) {
        _expandedNodes.remove(nodeId);
      } else {
        _expandedNodes.add(nodeId);
      }
    });
    // Notifica mudança de expansão
    if (widget.onExpansionChanged != null) {
      widget.onExpansionChanged!(nodeId, !wasExpanded);
    }
    // Notifica mudança de seleção para atualizar ações contextuais
    if (nodeId == _selectedNodeId && widget.onSelectionChanged != null) {
      widget.onSelectionChanged!(_selectedNodeId);
    }
  }

  bool _isExpanded(String nodeId) {
    return _expandedNodes.contains(nodeId);
  }

  void _selectNode(String? nodeId) {
    print('🎯 [TreeView] NODE SELECIONADO - nodeId: $nodeId');
    print('   _selectedNodeId anterior: $_selectedNodeId');
    print('   _editingNodeId: $_editingNodeId');
    developer.log('TreeView: _selectNode chamado. nodeId: $nodeId, _editingNodeId: $_editingNodeId');
    
    // Se está editando outro node, cancela a edição primeiro
    if (_editingNodeId != null && _editingNodeId != nodeId) {
      print('⚠️ [TreeView] Cancelando edição porque outro node foi selecionado');
      developer.log('TreeView: Cancelando edição porque outro node foi selecionado');
      
      // Limpa o callback de confirmação do node que estava editando
      _confirmCallbacks.remove(_editingNodeId);
      
      // Garante que o foco volte para o TreeView
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _treeFocusNode.requestFocus();
      });
    }
    
    final previousEditingNodeId = _editingNodeId;
    setState(() {
      _selectedNodeId = nodeId;
      // Cancela modo de edição ao selecionar outro nó
      if (_editingNodeId != null && _editingNodeId != nodeId) {
        _editingNodeId = null;
      }
    });
    
    // Notifica mudança de seleção
    if (widget.onSelectionChanged != null) {
      widget.onSelectionChanged!(nodeId);
    }
    
    // Notifica mudança de estado de edição se necessário
    if (previousEditingNodeId != _editingNodeId && widget.onEditingStateChanged != null) {
      widget.onEditingStateChanged!(_editingNodeId != null, _editingNodeId);
    }
    
    print('   _selectedNodeId após setState: $_selectedNodeId');
    print('   _editingNodeId após setState: $_editingNodeId');
  }

  void _cancelEditing() {
    final wasEditing = _editingNodeId != null;
    setState(() {
      _editingNodeId = null;
    });
    // Notifica mudança de estado de edição
    if (wasEditing && widget.onEditingStateChanged != null) {
      widget.onEditingStateChanged!(false, _selectedNodeId);
    }
  }


  Node _updateNodeInTree(Node node, String nodeId, String newName) {
    developer.log('TreeView: _updateNodeInTree - node.id: ${node.id}, procurando: $nodeId');
    if (node.id == nodeId) {
      developer.log('TreeView: Node encontrado! Atualizando nome de "${node.name}" para "$newName"');
      return node.copyWith(name: newName);
    }
    
    final updatedChildren = node.children.map((child) {
      return _updateNodeInTree(child, nodeId, newName);
    }).toList();
    
    return node.copyWith(children: updatedChildren);
  }

  // Map para armazenar funções de confirmação que leem o valor do TextField
  final Map<String, VoidCallback> _confirmCallbacks = {};

  void _confirmEditing() {
    print('💾 [TreeView] _confirmEditing chamado');
    if (_editingNodeId != null) {
      final nodeId = _editingNodeId!;
      print('   Node sendo editado: $nodeId');
      
      // Chama o callback de confirmação que foi registrado
      // Esse callback vai ler o valor do TextField e salvar via onNameChanged
      final confirmCallback = _confirmCallbacks[nodeId];
      if (confirmCallback != null) {
        print('   ✅ Chamando callback para ler TextField e salvar');
        confirmCallback(); // Isso vai chamar confirmEditing() do TreeNodeTile
        _confirmCallbacks.remove(nodeId);
      } else {
        print('   ⚠️ Callback não encontrado - o TextField.onSubmitted deve ter processado');
      }
      
      setState(() {
        _editingNodeId = null;
      });
      
      // Notifica mudança de estado de edição
      if (widget.onEditingStateChanged != null) {
        widget.onEditingStateChanged!(false, nodeId);
      }
    } else {
      print('   Nenhum node em edição');
    }
  }

  void _handleNameChanged(String nodeId, String newName) {
    print('💾 [TreeView] NOME MUDANDO');
    print('   nodeId: $nodeId');
    print('   newName: "$newName"');
    print('   onNodeNameChanged existe: ${widget.onNodeNameChanged != null}');
    developer.log('TreeView: _handleNameChanged chamado. nodeId: $nodeId, newName: "$newName", onNodeNameChanged: ${widget.onNodeNameChanged != null}');
    if (newName.trim().isNotEmpty) {
      final oldName = _rootNode.findById(nodeId)?.name ?? 'NÃO ENCONTRADO';
      print('   Nome antigo: "$oldName"');
      developer.log('TreeView: Nome antigo do node: "$oldName"');
      
      // Limpa o callback de confirmação após salvar
      _confirmCallbacks.remove(nodeId);
      
      // Primeiro atualiza localmente para feedback imediato
      setState(() {
        _rootNode = _updateNodeInTree(_rootNode, nodeId, newName);
        _editingNodeId = null;
      });
      
      // Notifica mudança de estado de edição (saiu do modo de edição)
      if (widget.onEditingStateChanged != null) {
        widget.onEditingStateChanged!(false, nodeId);
      }
      
      final updatedName = _rootNode.findById(nodeId)?.name ?? 'NÃO ENCONTRADO';
      print('   Nome após atualização local: "$updatedName"');
      developer.log('TreeView: Após atualização local, nome do node: "$updatedName"');
      
      // Depois notifica o parent para atualizar a fonte de verdade
      print('   Chamando callback onNodeNameChanged...');
      developer.log('TreeView: Chamando onNodeNameChanged callback');
      widget.onNodeNameChanged?.call(nodeId, newName);
      print('   Callback retornou');
      developer.log('TreeView: Callback onNodeNameChanged retornou');
      
      // Garante que o foco volte para o TreeView para capturar atalhos de teclado
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _treeFocusNode.requestFocus();
      });
    } else {
      print('❌ Nome vazio, não atualizando');
      developer.log('TreeView: Nome vazio, não atualizando');
    }
  }

  void _handleCancelEditing() {
    print('🛑 [TreeView] CANCELANDO EDIÇÃO');
    print('   _editingNodeId antes: $_editingNodeId');
    developer.log('TreeView: _handleCancelEditing chamado. _editingNodeId: $_editingNodeId');
    
    // Limpa o callback de confirmação
    if (_editingNodeId != null) {
      _confirmCallbacks.remove(_editingNodeId);
      print('   Callback de confirmação removido para: $_editingNodeId');
    }
    
    setState(() {
      _editingNodeId = null;
    });
    print('   _editingNodeId após setState: $_editingNodeId');
    
    // Garante que o foco volte para o TreeView para capturar atalhos de teclado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _treeFocusNode.requestFocus();
    });
    developer.log('TreeView: Modo de edição cancelado');
  }

  void _addNewChild() {
    if (_selectedNodeId == null || _editingNodeId != null) {
      print('❌ [TreeView] Nenhum node selecionado ou está editando');
      return;
    }

    final parentNode = _rootNode.findById(_selectedNodeId!);
    if (parentNode == null) {
      print('❌ [TreeView] Node selecionado não encontrado');
      return;
    }

    // Gera um ID único para o novo node
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newNodeId = 'new_node_$timestamp';
    final newNodeName = 'Novo Item';

    // Salva o ID do parent antes de mudar a seleção
    final parentNodeId = _selectedNodeId!;

    // Cria o novo node
    final newNode = Node(
      id: newNodeId,
      name: newNodeName,
    );

    // Adiciona o novo node como filho do parent
    Node addChildRecursive(Node node) {
      if (node.id == parentNodeId) {
        final newChildren = List<Node>.from(node.children)..add(newNode);
        return node.copyWith(children: newChildren);
      }

      final updatedChildren = node.children
          .map((child) => addChildRecursive(child))
          .toList();

      return node.copyWith(children: updatedChildren);
    }

    // Atualiza a árvore primeiro
    final updatedRoot = addChildRecursive(_rootNode);
    
    // Garante que o parent está expandido para mostrar o novo filho
    final wasExpanded = _expandedNodes.contains(parentNodeId);
    if (!wasExpanded) {
      _expandedNodes.add(parentNodeId);
      // Notifica mudança de expansão
      if (widget.onExpansionChanged != null) {
        widget.onExpansionChanged!(parentNodeId, true);
      }
    }
    
    setState(() {
      _rootNode = updatedRoot;
      // Seleciona o novo node
      _selectedNodeId = newNodeId;
    });

    // Notifica callbacks DEPOIS do setState para garantir que o widget seja reconstruído primeiro
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Notifica callbacks após o frame ser renderizado
        if (widget.onSelectionChanged != null) {
          widget.onSelectionChanged!(newNodeId);
        }
        if (widget.onNodeAdded != null) {
          widget.onNodeAdded!(parentNodeId, newNodeId, newNodeName);
        }
        
        // Entra em modo de edição após um frame adicional (simula F2)
        // Isso garante que o TreeNodeTile já foi construído
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _selectedNodeId == newNodeId) {
            setState(() {
              _editingNodeId = newNodeId;
            });
            // Notifica mudança de estado de edição
            if (widget.onEditingStateChanged != null) {
              widget.onEditingStateChanged!(true, newNodeId);
            }
          }
        });
      }
    });

    print('✅ [TreeView] Novo child adicionado: $newNodeId');
  }

  // Verifica se são irmãos (mesmo parent) - para determinar se é reordenação
  bool _areSiblings(String draggedId, String targetId) {
    final draggedParent = Node.findParent(_rootNode, draggedId);
    final targetParent = Node.findParent(_rootNode, targetId);
    
    // Se ambos são filhos da raiz
    if (draggedParent == null && targetParent == null) {
      return true;
    }
    
    // Se ambos têm o mesmo parent
    if (draggedParent != null && targetParent != null) {
      return draggedParent.id == targetParent.id;
    }
    
    return false;
  }

  void _handleDrop(String draggedNodeId, String targetNodeId) {
    print('🔄 [TreeView] DROP - draggedNodeId: $draggedNodeId, targetNodeId: $targetNodeId, insertBefore: $_insertBefore');
    developer.log('TreeView: _handleDrop chamado. draggedNodeId: $draggedNodeId, targetNodeId: $targetNodeId');
    
    // Verifica se não está editando
    if (_editingNodeId != null) {
      print('❌ Não é possível reordenar durante edição');
      return;
    }

    // Encontra os nodes
    final draggedNode = _rootNode.findById(draggedNodeId);
    final targetNode = _rootNode.findById(targetNodeId);
    
    if (draggedNode == null || targetNode == null) {
      print('❌ Nodes não encontrados');
      return;
    }

    // Encontra os parents
    final draggedParent = Node.findParent(_rootNode, draggedNodeId);
    final targetParent = Node.findParent(_rootNode, targetNodeId);

    // Verifica se são irmãos (mesmo parent)
    final areSibs = _areSiblings(draggedNodeId, targetNodeId);

    if (areSibs) {
      // Reordenação entre irmãos
      if (draggedParent == null && targetParent == null) {
        // Ambos são filhos da raiz
        _reorderInRoot(draggedNodeId, targetNodeId, _insertBefore);
      } else if (draggedParent != null && targetParent != null) {
        // Mesmos pais - reordena dentro do parent
        _reorderInParent(draggedParent.id, draggedNodeId, targetNodeId, _insertBefore);
      }
      
      // Notifica callback de reordenação
      if (widget.onNodeReordered != null) {
        widget.onNodeReordered!(draggedNodeId, targetNodeId, _insertBefore);
      }
    } else {
      // Mudança de parent - move o node para ser filho do target
      _moveToNewParent(draggedNodeId, targetNodeId);
      
      // Notifica callback de mudança de parent
      if (widget.onNodeParentChanged != null) {
        widget.onNodeParentChanged!(draggedNodeId, targetNodeId);
      }
    }

    // Limpa estado de drag
    setState(() {
      _draggedNodeId = null;
      _draggedOverNodeId = null;
    });
  }

  void _moveToNewParent(String draggedNodeId, String newParentId) {
    print('📦 Movendo node $draggedNodeId para ser filho de $newParentId');
    
    // Primeiro, encontra o node a ser movido
    final draggedNode = _rootNode.findById(draggedNodeId);
    if (draggedNode == null) {
      print('❌ Node não encontrado: $draggedNodeId');
      return;
    }
    
    // Remove o node da posição atual (filtra recursivamente)
    Node removeNodeRecursive(Node node) {
      // Filtra os filhos removendo o node arrastado
      final filteredChildren = node.children
          .where((child) => child.id != draggedNodeId)
          .map((child) => removeNodeRecursive(child))
          .toList();
      
      return node.copyWith(children: filteredChildren);
    }
    
    // Adiciona o node como filho do novo parent
    Node addAsChildRecursive(Node node, Node nodeToAdd) {
      if (node.id == newParentId) {
        // Adiciona como último filho
        final newChildren = List<Node>.from(node.children)..add(nodeToAdd);
        return node.copyWith(children: newChildren);
      }
      
      final updatedChildren = node.children
          .map((child) => addAsChildRecursive(child, nodeToAdd))
          .toList();
      
      return node.copyWith(children: updatedChildren);
    }
    
    // Remove o node da árvore
    var updatedRoot = removeNodeRecursive(_rootNode);
    
    // Adiciona o node como filho do novo parent
    updatedRoot = addAsChildRecursive(updatedRoot, draggedNode);
    
    // Se o novo parent estava colapsado, expande para mostrar o novo filho
    if (!_expandedNodes.contains(newParentId)) {
      _toggleExpand(newParentId);
    }
    
    setState(() {
      _rootNode = updatedRoot;
    });
  }

  void _reorderInRoot(String draggedNodeId, String targetNodeId, bool insertBefore) {
    print('📦 Reordenando na raiz');
    final children = List<Node>.from(_rootNode.children);
    
    // Remove o node arrastado
    final draggedIndex = children.indexWhere((node) => node.id == draggedNodeId);
    if (draggedIndex == -1) return;
    final draggedNode = children.removeAt(draggedIndex);
    
    // Encontra posição do target
    final targetIndex = children.indexWhere((node) => node.id == targetNodeId);
    if (targetIndex == -1) {
      // Se não encontrou (foi removido acima), adiciona no final
      children.add(draggedNode);
    } else {
      // Insere na posição correta
      final insertIndex = insertBefore ? targetIndex : targetIndex + 1;
      children.insert(insertIndex.clamp(0, children.length), draggedNode);
    }
    
    setState(() {
      _rootNode = _rootNode.copyWith(children: children);
    });
  }

  void _reorderInParent(String parentId, String draggedNodeId, String targetNodeId, bool insertBefore) {
    print('📦 Reordenando no parent: $parentId');
    
    Node? updateNodeRecursive(Node node) {
      if (node.id == parentId) {
        final children = List<Node>.from(node.children);
        
        // Remove o node arrastado
        final draggedIndex = children.indexWhere((child) => child.id == draggedNodeId);
        if (draggedIndex == -1) return node;
        final draggedNode = children.removeAt(draggedIndex);
        
        // Encontra posição do target
        final targetIndex = children.indexWhere((child) => child.id == targetNodeId);
        if (targetIndex == -1) {
          children.add(draggedNode);
        } else {
          final insertIndex = insertBefore ? targetIndex : targetIndex + 1;
          children.insert(insertIndex.clamp(0, children.length), draggedNode);
        }
        
        return node.copyWith(children: children);
      }
      
      final updatedChildren = node.children.map((child) => updateNodeRecursive(child) ?? child).toList();
      return node.copyWith(children: updatedChildren);
    }
    
    setState(() {
      _rootNode = updateNodeRecursive(_rootNode) ?? _rootNode;
    });
  }

  /// Retorna lista plana de todos os nodes visíveis na ordem que aparecem na tela
  List<Node> _getVisibleNodes() {
    final List<Node> visibleNodes = [];
    
    void collectVisibleNodes(Node node) {
      visibleNodes.add(node);
      // Se o node está expandido, adiciona seus filhos recursivamente
      if (!node.isLeaf && _expandedNodes.contains(node.id)) {
        for (final child in node.children) {
          collectVisibleNodes(child);
        }
      }
    }
    
    collectVisibleNodes(_rootNode);
    return visibleNodes;
  }

  /// Retorna o índice do node na lista de nodes visíveis, ou -1 se não encontrado
  int _getNodeIndex(String nodeId) {
    final visibleNodes = _getVisibleNodes();
    for (int i = 0; i < visibleNodes.length; i++) {
      if (visibleNodes[i].id == nodeId) {
        return i;
      }
    }
    return -1;
  }

  /// Navega para o node anterior (seta para cima)
  void _navigateUp() {
    // Não navega se estiver editando
    if (_editingNodeId != null) {
      return;
    }
    
    final visibleNodes = _getVisibleNodes();
    if (visibleNodes.isEmpty) return;
    
    if (_selectedNodeId == null) {
      // Se nenhum node está selecionado, seleciona o primeiro
      _selectNode(visibleNodes.first.id);
      return;
    }
    
    final currentIndex = _getNodeIndex(_selectedNodeId!);
    if (currentIndex == -1) {
      // Node não encontrado, seleciona o primeiro
      _selectNode(visibleNodes.first.id);
      return;
    }
    
    if (currentIndex > 0) {
      // Move para o node anterior
      _selectNode(visibleNodes[currentIndex - 1].id);
    }
    // Se estiver no primeiro, mantém seleção
  }

  /// Navega para o próximo node (seta para baixo)
  void _navigateDown() {
    // Não navega se estiver editando
    if (_editingNodeId != null) {
      return;
    }
    
    final visibleNodes = _getVisibleNodes();
    if (visibleNodes.isEmpty) return;
    
    if (_selectedNodeId == null) {
      // Se nenhum node está selecionado, seleciona o primeiro
      _selectNode(visibleNodes.first.id);
      return;
    }
    
    final currentIndex = _getNodeIndex(_selectedNodeId!);
    if (currentIndex == -1) {
      // Node não encontrado, seleciona o primeiro
      _selectNode(visibleNodes.first.id);
      return;
    }
    
    if (currentIndex < visibleNodes.length - 1) {
      // Move para o próximo node
      _selectNode(visibleNodes[currentIndex + 1].id);
    }
    // Se estiver no último, mantém seleção
  }

  /// Colapsa o node selecionado (seta para esquerda)
  void _collapseSelected() {
    // Não colapsa se estiver editando
    if (_editingNodeId != null) {
      return;
    }
    
    if (_selectedNodeId == null) return;
    
    final selectedNode = _rootNode.findById(_selectedNodeId!);
    if (selectedNode == null || selectedNode.isLeaf) return;
    
    // Se estiver expandido, colapsa
    if (_expandedNodes.contains(_selectedNodeId)) {
      _toggleExpand(_selectedNodeId!);
    }
  }

  /// Expande o node selecionado (seta para direita)
  void _expandSelected() {
    // Não expande se estiver editando
    if (_editingNodeId != null) {
      return;
    }
    
    if (_selectedNodeId == null) return;
    
    final selectedNode = _rootNode.findById(_selectedNodeId!);
    if (selectedNode == null || selectedNode.isLeaf) return;
    
    // Se estiver colapsado, expande
    if (!_expandedNodes.contains(_selectedNodeId)) {
      _toggleExpand(_selectedNodeId!);
    }
  }

  /// Navega para o próximo node não-leaf (Ctrl + seta para cima)
  void _navigateToPreviousNonLeaf() {
    // Não navega se estiver editando
    if (_editingNodeId != null) {
      return;
    }
    
    final visibleNodes = _getVisibleNodes();
    if (visibleNodes.isEmpty) return;
    
    int startIndex;
    if (_selectedNodeId == null) {
      startIndex = visibleNodes.length;
    } else {
      startIndex = _getNodeIndex(_selectedNodeId!);
      if (startIndex == -1) {
        startIndex = visibleNodes.length;
      }
    }
    
    // Procura para trás pelo próximo node não-leaf
    for (int i = startIndex - 1; i >= 0; i--) {
      if (!visibleNodes[i].isLeaf) {
        _selectNode(visibleNodes[i].id);
        return;
      }
    }
    
    // Se não encontrou, mantém seleção atual ou seleciona o primeiro se não havia seleção
    if (_selectedNodeId == null && visibleNodes.isNotEmpty) {
      _selectNode(visibleNodes.first.id);
    }
  }

  /// Navega para o próximo node não-leaf (Ctrl + seta para baixo)
  void _navigateToNextNonLeaf() {
    // Não navega se estiver editando
    if (_editingNodeId != null) {
      return;
    }
    
    final visibleNodes = _getVisibleNodes();
    if (visibleNodes.isEmpty) return;
    
    int startIndex;
    if (_selectedNodeId == null) {
      startIndex = -1;
    } else {
      startIndex = _getNodeIndex(_selectedNodeId!);
      if (startIndex == -1) {
        startIndex = -1;
      }
    }
    
    // Procura para frente pelo próximo node não-leaf
    for (int i = startIndex + 1; i < visibleNodes.length; i++) {
      if (!visibleNodes[i].isLeaf) {
        _selectNode(visibleNodes[i].id);
        return;
      }
    }
    
    // Se não encontrou, mantém seleção atual ou seleciona o último se não havia seleção
    if (_selectedNodeId == null && visibleNodes.isNotEmpty) {
      _selectNode(visibleNodes.last.id);
    }
  }

  Map<LogicalKeySet, Intent> _getShortcuts() {
    final shortcuts = <LogicalKeySet, Intent>{
      LogicalKeySet(LogicalKeyboardKey.f2): const _F2Intent(),
      LogicalKeySet(LogicalKeyboardKey.escape): const _CancelEditingIntent(),
      LogicalKeySet(LogicalKeyboardKey.enter): const _ConfirmEditingIntent(),
      LogicalKeySet(LogicalKeyboardKey.arrowUp): const _ArrowUpIntent(),
      LogicalKeySet(LogicalKeyboardKey.arrowDown): const _ArrowDownIntent(),
      // Ctrl + setas para navegar entre nodes não-leaf
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowUp): const _CtrlArrowUpIntent(),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowDown): const _CtrlArrowDownIntent(),
    };
    
    // Só adiciona shortcuts de esquerda/direita e 'n' se não estiver editando
    // Quando está editando, o TextField precisa processar essas teclas
    if (_editingNodeId == null) {
      shortcuts[LogicalKeySet(LogicalKeyboardKey.arrowLeft)] = const _ArrowLeftIntent();
      shortcuts[LogicalKeySet(LogicalKeyboardKey.arrowRight)] = const _ArrowRightIntent();
      shortcuts[LogicalKeySet(LogicalKeyboardKey.keyN)] = const _AddChildIntent();
    }
    
    return shortcuts;
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: _getShortcuts(),
      child: Actions(
        actions: {
          _F2Intent: CallbackAction<_F2Intent>(
            onInvoke: (_) {
              // Quando F2 é pressionado, ativa modo de edição
              print('⌨️ [TreeView] F2 PRESSIONADO');
              print('   _selectedNodeId: $_selectedNodeId');
              print('   _editingNodeId: $_editingNodeId');
              developer.log('TreeView: F2 pressionado. _selectedNodeId: $_selectedNodeId, _editingNodeId: $_editingNodeId');
              if (_selectedNodeId != null) {
                print('✅ [TreeView] ATIVANDO MODO DE EDIÇÃO para node $_selectedNodeId');
                developer.log('TreeView: Ativando modo de edição para node $_selectedNodeId');
                setState(() {
                  _editingNodeId = _selectedNodeId;
                });
                // Notifica mudança de estado de edição
                if (widget.onEditingStateChanged != null) {
                  widget.onEditingStateChanged!(true, _selectedNodeId);
                }
                print('   _editingNodeId após setState: $_editingNodeId');
              } else {
                print('❌ [TreeView] Nenhum node selecionado, não é possível entrar em modo de edição');
                developer.log('TreeView: Nenhum node selecionado, não é possível entrar em modo de edição');
              }
              return null;
            },
          ),
          _CancelEditingIntent: CallbackAction<_CancelEditingIntent>(
            onInvoke: (_) {
              print('⌨️ [TreeView] ESC PRESSIONADO - Cancelando edição');
              _cancelEditing();
              _handleCancelEditing();
              return null;
            },
          ),
          _ConfirmEditingIntent: CallbackAction<_ConfirmEditingIntent>(
            onInvoke: (_) {
              print('⌨️ [TreeView] ENTER PRESSIONADO - CONFIRMANDO edição');
              if (_editingNodeId != null) {
                // Chama o callback onConfirmEditing do TreeNodeTile que está editando
                // Isso vai ler o valor do TextField e salvar
                // Precisamos acessar o tile que está editando
                print('   Procurando tile em edição: $_editingNodeId');
                // O callback onConfirmEditing será chamado pelo TreeNodeTile
                // mas precisamos encontrar o widget e chamar seu método
                // Por enquanto, vamos confiar que o onSubmitted do TextField vai processar
                // Se não processar, o onConfirmEditing vai fazer
              }
              _confirmEditing();
              return null;
            },
          ),
          _ArrowUpIntent: CallbackAction<_ArrowUpIntent>(
            onInvoke: (_) {
              print('⌨️ [TreeView] SETA PARA CIMA pressionada');
              _navigateUp();
              return null;
            },
          ),
          _ArrowDownIntent: CallbackAction<_ArrowDownIntent>(
            onInvoke: (_) {
              print('⌨️ [TreeView] SETA PARA BAIXO pressionada');
              _navigateDown();
              return null;
            },
          ),
          _ArrowLeftIntent: CallbackAction<_ArrowLeftIntent>(
            onInvoke: (_) {
              print('⌨️ [TreeView] SETA PARA ESQUERDA pressionada');
              // Não processa se estiver editando (deixa o TextField processar)
              if (_editingNodeId != null) {
                print('   Ignorando porque está editando');
                return null;
              }
              _collapseSelected();
              return null;
            },
          ),
          _ArrowRightIntent: CallbackAction<_ArrowRightIntent>(
            onInvoke: (_) {
              print('⌨️ [TreeView] SETA PARA DIREITA pressionada');
              // Não processa se estiver editando (deixa o TextField processar)
              if (_editingNodeId != null) {
                print('   Ignorando porque está editando');
                return null;
              }
              _expandSelected();
              return null;
            },
          ),
          _CtrlArrowUpIntent: CallbackAction<_CtrlArrowUpIntent>(
            onInvoke: (_) {
              print('⌨️ [TreeView] CTRL + SETA PARA CIMA pressionada');
              _navigateToPreviousNonLeaf();
              return null;
            },
          ),
          _CtrlArrowDownIntent: CallbackAction<_CtrlArrowDownIntent>(
            onInvoke: (_) {
              print('⌨️ [TreeView] CTRL + SETA PARA BAIXO pressionada');
              _navigateToNextNonLeaf();
              return null;
            },
          ),
          _AddChildIntent: CallbackAction<_AddChildIntent>(
            onInvoke: (_) {
              print('⌨️ [TreeView] N PRESSIONADO - Adicionar novo child');
              _addNewChild();
              return null;
            },
          ),
        },
        child: Focus(
          focusNode: _treeFocusNode,
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
    developer.log('TreeView: _buildTreeNodes - nodeId: $nodeId, isEditing: $isEditing, node.name: "${node.name}"');
    
    // Verifica se pode aceitar drop neste node
    // Retorna true se pode fazer drop (seja reordenar irmãos ou mudar parent)
    bool canAcceptDrop(String draggedId) {
      if (draggedId == nodeId) return false; // Não pode soltar em si mesmo
      
      final draggedNode = _rootNode.findById(draggedId);
      if (draggedNode == null) return false;
      
      final targetNode = _rootNode.findById(nodeId);
      if (targetNode == null) return false;
      
      // Não pode mover para dentro de si mesmo ou seus descendentes
      if (Node.isDescendantOf(_rootNode, draggedId, nodeId)) return false;
      
      // Se passou todas as validações, pode aceitar
      // (pode ser reordenação entre irmãos ou mudança de parent)
      return true;
    }


    final isDraggedOver = _draggedOverNodeId == nodeId && 
                         _draggedNodeId != null && 
                         canAcceptDrop(_draggedNodeId!);
    
    widgets.add(
      DragTarget<String>(
        onWillAccept: (data) {
          if (data == null || data == nodeId) return false;
          return canAcceptDrop(data);
        },
        onAccept: (draggedId) {
          _handleDrop(draggedId, nodeId);
        },
        onLeave: (_) {
          setState(() {
            _draggedOverNodeId = null;
          });
        },
        onMove: (details) {
          // Detecta se está na metade superior (inserir antes) ou inferior (inserir depois)
          setState(() {
            _draggedOverNodeId = nodeId;
            // Usa offsetY relativo para determinar posição
            // Como não temos acesso direto ao offset, vamos usar uma heurística baseada no centro
            _insertBefore = details.offset.dy < 20; // Se está perto do topo, insere antes
          });
        },
        builder: (context, candidateData, rejectedData) {
          final isActive = candidateData.isNotEmpty || rejectedData.isNotEmpty;
          final isValid = candidateData.isNotEmpty && (_draggedNodeId != null && canAcceptDrop(_draggedNodeId!));
          final isInvalid = rejectedData.isNotEmpty || 
                           (_draggedNodeId != null && !canAcceptDrop(_draggedNodeId!));
          
          // Determina se é reordenação (irmãos) ou mudança de parent
          final bool isReorder = _draggedNodeId != null && 
                                _areSiblings(_draggedNodeId!, nodeId);
          final bool isParentChange = isValid && !isReorder;
          
          return Container(
            decoration: BoxDecoration(
              color: isActive && isValid
                  ? (isParentChange 
                      ? Theme.of(context).colorScheme.secondary.withOpacity(0.15) // Diferente para mudança de parent
                      : Theme.of(context).colorScheme.primary.withOpacity(0.1)) // Normal para reordenação
                  : isActive && isInvalid
                      ? Colors.red.withOpacity(0.1)
                      : Colors.transparent,
              border: isDraggedOver && isValid
                  ? isReorder
                      ? Border(
                          top: _insertBefore
                              ? BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                )
                              : BorderSide.none,
                          bottom: !_insertBefore
                              ? BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                )
                              : BorderSide.none,
                        )
                      : Border.all( // Para mudança de parent, mostra borda completa
                          color: Theme.of(context).colorScheme.secondary,
                          width: 2,
                        )
                  : null,
            ),
            child: TreeNodeTile(
              key: ValueKey(nodeId),
              node: node,
              depth: depth,
              isExpanded: isExpanded,
              hasChildren: hasChildren,
              isSelected: _selectedNodeId == nodeId,
              isEditing: isEditing,
              onToggle: hasChildren ? () => _toggleExpand(nodeId) : null,
              onTap: () => _selectNode(nodeId),
              onDragStart: () {
                setState(() {
                  _draggedNodeId = nodeId;
                });
              },
              onDragEnd: () {
                setState(() {
                  _draggedNodeId = null;
                  _draggedOverNodeId = null;
                });
              },
              onNameChanged: isEditing
                  ? (newName) {
                      developer.log('TreeView: Callback onNameChanged chamado diretamente para node $nodeId com "$newName"');
                      _handleNameChanged(nodeId, newName);
                    }
                  : null,
              onCancelEditing: isEditing
                  ? () {
                      developer.log('TreeView: Callback onCancelEditing chamado diretamente para node $nodeId');
                      _handleCancelEditing();
                    }
                  : null,
              onConfirmEditing: isEditing
                  ? (confirmFn) {
                      print('📞 [TreeView] Registrando função de confirmação para node $nodeId');
                      // Armazena a função confirmEditing do TreeNodeTile
                      // que será chamada quando Enter for pressionado via Shortcuts
                      _confirmCallbacks[nodeId] = confirmFn;
                    }
                  : null,
            ),
          );
        },
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

// Intent para navegar para cima (↑)
class _ArrowUpIntent extends Intent {
  const _ArrowUpIntent();
}

// Intent para navegar para baixo (↓)
class _ArrowDownIntent extends Intent {
  const _ArrowDownIntent();
}

// Intent para colapsar (←)
class _ArrowLeftIntent extends Intent {
  const _ArrowLeftIntent();
}

// Intent para expandir (→)
class _ArrowRightIntent extends Intent {
  const _ArrowRightIntent();
}

// Intent para navegar para o node não-leaf anterior (Ctrl + ↑)
class _CtrlArrowUpIntent extends Intent {
  const _CtrlArrowUpIntent();
}

// Intent para navegar para o próximo node não-leaf (Ctrl + ↓)
class _CtrlArrowDownIntent extends Intent {
  const _CtrlArrowDownIntent();
}

// Intent para adicionar novo child (N)
class _AddChildIntent extends Intent {
  const _AddChildIntent();
}

