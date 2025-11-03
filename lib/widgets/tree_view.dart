import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
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
  final FocusNode _treeFocusNode = FocusNode();

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
    // Sempre sincroniza _rootNode com widget.rootNode para garantir que mudanças do parent sejam refletidas
    developer.log('TreeView: didUpdateWidget - Sincronizando _rootNode. Root atual: ${_rootNode.name}, Novo root: ${widget.rootNode.name}');
    if (_rootNode.name != widget.rootNode.name || _rootNode.id != widget.rootNode.id) {
      developer.log('TreeView: Root mudou! Atualizando _rootNode local.');
    }
    _rootNode = widget.rootNode;
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
    
    setState(() {
      _selectedNodeId = nodeId;
      // Cancela modo de edição ao selecionar outro nó
      if (_editingNodeId != null && _editingNodeId != nodeId) {
        _editingNodeId = null;
      }
    });
    print('   _selectedNodeId após setState: $_selectedNodeId');
    print('   _editingNodeId após setState: $_editingNodeId');
  }

  void _cancelEditing() {
    setState(() {
      _editingNodeId = null;
    });
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
    
    // Só adiciona shortcuts de esquerda/direita se não estiver editando
    // Quando está editando, o TextField precisa processar essas teclas
    if (_editingNodeId == null) {
      shortcuts[LogicalKeySet(LogicalKeyboardKey.arrowLeft)] = const _ArrowLeftIntent();
      shortcuts[LogicalKeySet(LogicalKeyboardKey.arrowRight)] = const _ArrowRightIntent();
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

