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
    setState(() {
      _selectedNodeId = nodeId;
      // Cancela modo de edição ao selecionar outro nó
      if (_editingNodeId != null && _editingNodeId != nodeId) {
        print('⚠️ [TreeView] Cancelando edição porque outro node foi selecionado');
        developer.log('TreeView: Cancelando edição porque outro node foi selecionado');
        _editingNodeId = null;
      }
    });
    print('   _selectedNodeId após setState: $_selectedNodeId');
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

