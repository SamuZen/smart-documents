import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import 'dart:io';
import 'models/node.dart';
import 'services/project_service.dart';
import 'services/command_history.dart';
import 'services/command_registry.dart';
import 'services/command_registry_helper.dart';
import 'services/checkpoint_manager.dart';
import 'commands/rename_node_command.dart';
import 'commands/add_node_command.dart';
import 'commands/delete_node_command.dart';
import 'commands/reorder_node_command.dart';
import 'commands/move_node_command.dart';
import 'widgets/tree_view.dart';
import 'widgets/draggable_resizable_window.dart';
import 'widgets/actions_panel.dart';
import 'widgets/document_editor.dart';
import 'widgets/menu_bar.dart';
import 'widgets/checkpoint_dialog.dart';
import 'widgets/confirmation_dialog.dart';
import 'screens/welcome_screen.dart';
import 'utils/preferences.dart';
import 'commands/set_node_field_command.dart';
import 'commands/remove_node_field_command.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Document',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
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
  bool _showDocumentEditor = true;
  String? _selectedNodeId;
  bool _isEditing = false;
  final Set<String> _expandedNodes = {}; // Rastreia nodes expandidos

  // Estado do projeto
  String? _currentProjectPath;
  bool _hasUnsavedChanges = false;
  bool _showWelcomeScreen = true; // Inicia mostrando a tela de boas-vindas

  // Sistema de comandos
  late CommandHistory _commandHistory;
  late CheckpointManager _checkpointManager;
  final CommandRegistry _commandRegistry = CommandRegistry.instance;
  String? _undoDescription;
  String? _redoDescription;
  
  // FocusNode principal para capturar atalhos globais
  final FocusNode _mainFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Inicia com uma estrutura vazia (será substituída quando carregar projeto)
    _rootNode = Node(
      id: 'root',
      name: 'Novo Projeto',
    );

    // Inicializa sistema de comandos
    _initializeCommandSystem();
    
    // Garante que o foco principal está solicitado após o primeiro frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_mainFocusNode.hasFocus) {
        print('✅ [Main] Solicitando foco principal no initState');
        developer.log('Main: Solicitando foco principal no initState');
        _mainFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _mainFocusNode.dispose();
    super.dispose();
  }

  void _initializeCommandSystem() {
    // Registra todos os comandos
    CommandRegistryHelper.registerAllCommands();

    // Inicializa CommandHistory
    _commandHistory = CommandHistory();
    _commandHistory.onTreeChanged = (Node updatedTree) {
      setState(() {
        _rootNode = updatedTree;
        _markProjectAsModified();
      });
    };
    _commandHistory.onHistoryChanged = () {
      _updateHistoryState();
    };

    // Inicializa CheckpointManager
    _checkpointManager = CheckpointManager();
    _checkpointManager.onTreeChanged = (Node updatedTree) {
      setState(() {
        _rootNode = updatedTree;
        _hasUnsavedChanges = false; // Checkpoints não marcam como modificado
        _commandHistory.clear(); // Limpa histórico ao restaurar checkpoint
      });
    };

    // Conecta CommandHistory e CheckpointManager
    _commandHistory.setCheckpointManager(_checkpointManager);
    _checkpointManager.setCommandHistory(_commandHistory);

    // Atualiza estado inicial do histórico
    _updateHistoryState();
  }

  void _updateHistoryState() {
    setState(() {
      _undoDescription = _commandHistory.undoDescription;
      _redoDescription = _commandHistory.redoDescription;
    });
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

  void _handleNodeReordered(String draggedNodeId, String targetNodeId, bool insertBefore) async {
    developer.log('MyHomePage: _handleNodeReordered chamado. draggedNodeId: $draggedNodeId, targetNodeId: $targetNodeId, insertBefore: $insertBefore');
    
    // Encontra o parent comum
    final draggedParent = Node.findParent(_rootNode, draggedNodeId);
    final targetParent = Node.findParent(_rootNode, targetNodeId);
    
    // Verifica se são irmãos (mesmo parent)
    String? parentId;
    if (draggedParent == null && targetParent == null) {
      parentId = _rootNode.id; // Ambos são filhos da raiz
    } else if (draggedParent != null && targetParent != null && draggedParent.id == targetParent.id) {
      parentId = draggedParent.id;
    } else {
      return; // Não são irmãos, não pode reordenar
    }
    
    // Encontra índices
    final parentNode = _rootNode.findById(parentId);
    if (parentNode == null) return;
    
    final oldIndex = parentNode.children.indexWhere((child) => child.id == draggedNodeId);
    final targetIndex = parentNode.children.indexWhere((child) => child.id == targetNodeId);
    
    if (oldIndex == -1 || targetIndex == -1) return;
    
    // Calcula novo índice
    final newTargetIndex = targetIndex > oldIndex ? targetIndex - 1 : targetIndex;
    final newIndex = insertBefore ? newTargetIndex : newTargetIndex + 1;
    
    // Cria e executa comando
    final command = ReorderNodeCommand(
      parentNodeId: parentId,
      draggedNodeId: draggedNodeId,
      targetNodeId: targetNodeId,
      insertBefore: insertBefore,
      oldIndex: oldIndex,
      newIndex: newIndex.clamp(0, parentNode.children.length - 1),
    );
    
    await _commandHistory.execute(command, _rootNode);
  }

  void _handleNodeParentChanged(String draggedNodeId, String newParentId) async {
    developer.log('MyHomePage: _handleNodeParentChanged chamado. draggedNodeId: $draggedNodeId, newParentId: $newParentId');
    
    // Encontra informações do parent antigo
    final oldParent = Node.findParent(_rootNode, draggedNodeId);
    final oldParentId = oldParent?.id ?? _rootNode.id;
    
    // Encontra índices
    final oldParentNode = _rootNode.findById(oldParentId);
    final newParentNode = _rootNode.findById(newParentId);
    
    if (oldParentNode == null || newParentNode == null) return;
    
    final oldIndex = oldParentNode.children.indexWhere((child) => child.id == draggedNodeId);
    final newIndex = newParentNode.children.length; // Adiciona no final
    
    // Cria e executa comando
    final command = MoveNodeCommand(
      draggedNodeId: draggedNodeId,
      oldParentId: oldParentId,
      newParentId: newParentId,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
    
    await _commandHistory.execute(command, _rootNode);
  }

  void _handleNodeAdded(String parentNodeId, String newNodeId, String newNodeName) async {
    developer.log('MyHomePage: _handleNodeAdded chamado. parentNodeId: $parentNodeId, newNodeId: $newNodeId, newNodeName: $newNodeName');
    
    // Cria e executa comando
    final command = AddNodeCommand(
      parentNodeId: parentNodeId,
      newNodeId: newNodeId,
      newNodeName: newNodeName,
    );
    
    await _commandHistory.execute(command, _rootNode);
  }

  void _handleAddNodeShortcut() {
    // Este método é chamado quando 'n' é pressionado globalmente
    // Cria um novo node filho do node selecionado
    if (_selectedNodeId == null || _isEditing) {
      return;
    }

    final parentNode = _rootNode.findById(_selectedNodeId!);
    if (parentNode == null) {
      return;
    }

    // Gera um ID único para o novo node
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newNodeId = 'new_node_$timestamp';
    final newNodeName = 'Novo Item';

    // Cria o novo node através do comando
    _handleNodeAdded(_selectedNodeId!, newNodeId, newNodeName);
  }

  void _handleDeleteNodeShortcut() {
    // Este método é chamado quando Delete/Backspace é pressionado globalmente
    // Deleta o node selecionado (com confirmação)
    if (_selectedNodeId == null || _isEditing) {
      return;
    }

    final nodeToDelete = _rootNode.findById(_selectedNodeId!);
    if (nodeToDelete == null) {
      return;
    }

    // Não permite deletar a raiz
    if (_selectedNodeId == _rootNode.id) {
      return;
    }

    // Conta quantos descendentes o node tem
    final descendantCount = nodeToDelete.countAllDescendants();
    
    // Formata a mensagem de confirmação
    String message;
    if (descendantCount == 0) {
      message = 'Você quer deletar o node "${nodeToDelete.name}"?';
    } else {
      final childText = descendantCount == 1 ? 'child node' : 'child nodes';
      message = 'Você quer deletar o node "${nodeToDelete.name}"? Irá deletar também $descendantCount $childText.';
    }

    // Mostra dialog de confirmação
    ConfirmationDialog.show(
      context: context,
      title: 'Confirmar deleção',
      message: message,
      confirmText: 'Deletar',
      cancelText: 'Cancelar',
      isDestructive: true,
      onConfirm: () {
        // Usuário confirmou, deleta o node
        _handleNodeDeleted(_selectedNodeId!);
      },
    );
  }

  void _handleNodeDeleted(String deletedNodeId) async {
    developer.log('MyHomePage: _handleNodeDeleted chamado. deletedNodeId: $deletedNodeId');
    
    // Encontra o node antes de deletar para obter informações
    final nodeToDelete = _rootNode.findById(deletedNodeId);
    if (nodeToDelete == null) {
      return;
    }
    
    // Não permite deletar a raiz
    if (deletedNodeId == _rootNode.id) {
      return;
    }
    
    // Encontra o parent e o índice
    final parent = Node.findParent(_rootNode, deletedNodeId);
    final parentId = parent?.id ?? _rootNode.id;
    
    // Encontra o índice original
    final parentNode = _rootNode.findById(parentId);
    final originalIndex = parentNode?.children.indexWhere((child) => child.id == deletedNodeId) ?? -1;
    
    // Cria snapshot completo do node (cópia profunda)
    final nodeSnapshot = _deepCopyNode(nodeToDelete);
    
    // Cria e executa comando
    final command = DeleteNodeCommand(
      deletedNodeId: deletedNodeId,
      parentNodeId: parentId,
      nodeSnapshot: nodeSnapshot,
      originalIndex: originalIndex,
    );
    
    await _commandHistory.execute(command, _rootNode);
    
    // Limpa estados relacionados
    setState(() {
      _expandedNodes.remove(deletedNodeId);
      if (_selectedNodeId == deletedNodeId) {
        _selectedNodeId = null;
      }
    });
  }
  
  // Helper para criar cópia profunda de um Node
  Node _deepCopyNode(Node node) {
    final copiedChildren = node.children.map((child) => _deepCopyNode(child)).toList();
    return Node(
      id: node.id,
      name: node.name,
      children: copiedChildren,
      fields: Map<String, dynamic>.from(node.fields),
    );
  }

  Node _removeNodeFromTree(Node root, String nodeId) {
    // Não permite remover a raiz
    if (root.id == nodeId) {
      return root;
    }

    // Remove o node recursivamente
    Node removeRecursive(Node node) {
      final filteredChildren = node.children
          .where((child) => child.id != nodeId)
          .map((child) => removeRecursive(child))
          .toList();

      return node.copyWith(children: filteredChildren);
    }

    return removeRecursive(root);
  }

  Node _addNodeToParent(Node root, String parentNodeId, String newNodeId, String newNodeName) {
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

    return addChildRecursive(root);
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

  void _updateRootNode(String nodeId, String newName) async {
    developer.log('MyHomePage: _updateRootNode chamado. nodeId: $nodeId, newName: "$newName"');
    final oldName = _rootNode.findById(nodeId)?.name ?? '';
    
    // Cria e executa comando
    final command = RenameNodeCommand(
      nodeId: nodeId,
      oldName: oldName,
      newName: newName,
    );
    
    await _commandHistory.execute(command, _rootNode);
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

  // ========== Métodos de Edição de Campos ==========

  void _handleFieldChanged(String nodeId, String fieldKey, dynamic fieldValue) async {
    final node = _rootNode.findById(nodeId);
    if (node == null) return;

    final oldValue = node.fields[fieldKey];
    final command = SetNodeFieldCommand(
      nodeId: nodeId,
      fieldKey: fieldKey,
      newValue: fieldValue,
      oldValue: oldValue,
    );

    await _commandHistory.execute(command, _rootNode);
  }

  void _handleFieldRemoved(String nodeId, String fieldKey) async {
    final node = _rootNode.findById(nodeId);
    if (node == null) return;

    final removedValue = node.fields[fieldKey];
    if (removedValue == null) return;

    final command = RemoveNodeFieldCommand(
      nodeId: nodeId,
      fieldKey: fieldKey,
      removedValue: removedValue,
    );

    await _commandHistory.execute(command, _rootNode);
  }

  void _handleFieldAdded(String nodeId, String fieldKey, dynamic fieldValue) async {
    final command = SetNodeFieldCommand(
      nodeId: nodeId,
      fieldKey: fieldKey,
      newValue: fieldValue,
      oldValue: null, // Campo novo, não tem valor antigo
    );

    await _commandHistory.execute(command, _rootNode);
  }

  // ========== Métodos de Gerenciamento de Projeto ==========

  void _markProjectAsModified() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }


  bool _checkUnsavedChanges() {
    return _hasUnsavedChanges;
  }

  /// Retorna true se pode continuar (usuário salvou ou descartou), false se cancelou
  Future<bool> _handleUnsavedChangesDialog() async {
    if (!_checkUnsavedChanges()) {
      return true; // Não há alterações não salvas, pode continuar
    }

    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Alterações não salvas'),
          content: const Text(
            'Você tem alterações não salvas. O que deseja fazer?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop('cancel'),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop('discard'),
              child: const Text('Descartar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () => Navigator.of(dialogContext).pop('save'),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (result == 'cancel') {
      return false; // Usuário cancelou, não deve continuar
    } else if (result == 'save') {
      await _handleSaveProject();
      return true; // Salvou, pode continuar
    } else {
      // result == 'discard'
      setState(() {
        _hasUnsavedChanges = false;
      });
      return true; // Descartou, pode continuar
    }
  }

  Future<void> _handleNewProject() async {
    // Verifica alterações não salvas
    final canContinue = await _handleUnsavedChangesDialog();
    if (!canContinue) {
      return; // Usuário cancelou
    }

    // Solicita nome do projeto
    final projectName = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        final textController = TextEditingController();
        return AlertDialog(
          title: const Text('Novo Projeto'),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nome do projeto',
              hintText: 'Digite o nome do projeto',
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                Navigator.of(dialogContext).pop(value.trim());
              }
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final name = textController.text.trim();
                if (name.isNotEmpty) {
                  Navigator.of(dialogContext).pop(name);
                }
              },
              child: const Text('Criar'),
            ),
          ],
        );
      },
    );

    if (projectName == null || projectName.isEmpty) {
      return; // Usuário cancelou ou nome vazio
    }

    // Solicita pasta pai onde criar o projeto
    final parentFolder = await ProjectService.selectParentFolder();
    if (parentFolder == null) {
      return; // Usuário cancelou
    }

    // Cria a pasta do projeto
    final projectPath = await ProjectService.createProjectFolder(projectName, parentFolder);
    if (projectPath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao criar pasta do projeto. A pasta já existe ou nome inválido.')),
        );
      }
      return;
    }

    // Cria novo projeto com o nome especificado
    final newRootNode = Node(
      id: 'root',
      name: projectName,
    );

    // Salva o projeto
    final saved = await ProjectService.saveProject(projectPath, newRootNode);
    if (!saved) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar projeto')),
        );
      }
      return;
    }

    // Adiciona à lista de projetos recentes
    await Preferences.addRecentProject(projectPath, projectName);

    // Carrega o projeto criado
    setState(() {
      _rootNode = newRootNode;
      _currentProjectPath = projectPath;
      _hasUnsavedChanges = false;
      _showWelcomeScreen = false;
      _selectedNodeId = null;
      _expandedNodes.clear();
    });

    // Limpa histórico de comandos
    _commandHistory.clear();
    _checkpointManager.clearCheckpoints();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Projeto "$projectName" criado com sucesso')),
      );
    }
  }

  Future<void> _handleOpenProject() async {
    // Verifica alterações não salvas
    final canContinue = await _handleUnsavedChangesDialog();
    if (!canContinue) {
      return; // Usuário cancelou
    }

    // Seleciona pasta do projeto
    final projectPath = await ProjectService.pickProjectFolder();
    if (projectPath == null) {
      return; // Usuário cancelou ou pasta não tem project.json
    }

    // Carrega o projeto
    final loadedNode = await ProjectService.loadProject(projectPath);
    if (loadedNode == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao carregar projeto. Verifique se a pasta contém um arquivo project.json válido.'),
          ),
        );
      }
      return;
    }

    // Adiciona à lista de projetos recentes
    await Preferences.addRecentProject(projectPath, loadedNode.name);

    // Atualiza estado
    setState(() {
      _rootNode = loadedNode;
      _currentProjectPath = projectPath;
      _hasUnsavedChanges = false;
      _showWelcomeScreen = false;
      _selectedNodeId = null;
      _expandedNodes.clear();
      _showDocumentEditor = true; // Reseta para mostrar todas as janelas
    });

    // Limpa histórico de comandos
    _commandHistory.clear();
    _checkpointManager.clearCheckpoints();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Projeto carregado com sucesso')),
      );
    }
  }

  Future<void> _handleOpenRecentProject(String projectPath) async {
    // Verifica alterações não salvas
    final canContinue = await _handleUnsavedChangesDialog();
    if (!canContinue) {
      return; // Usuário cancelou
    }

    // Carrega o projeto
    final loadedNode = await ProjectService.loadProject(projectPath);
    if (loadedNode == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao carregar projeto. O projeto pode ter sido movido ou deletado.'),
          ),
        );
        // Remove da lista de recentes se não existe mais
        await Preferences.removeRecentProject(projectPath);
      }
      return;
    }

    // Adiciona à lista de projetos recentes (move para o topo)
    await Preferences.addRecentProject(projectPath, loadedNode.name);

    // Atualiza estado
    setState(() {
      _rootNode = loadedNode;
      _currentProjectPath = projectPath;
      _hasUnsavedChanges = false;
      _showWelcomeScreen = false;
      _selectedNodeId = null;
      _expandedNodes.clear();
      _showDocumentEditor = true; // Reseta para mostrar todas as janelas
    });

    // Limpa histórico de comandos
    _commandHistory.clear();
    _checkpointManager.clearCheckpoints();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Projeto carregado com sucesso')),
      );
    }
  }

  Future<void> _handleSaveProject() async {
    if (_currentProjectPath == null) {
      // Se não tem projeto salvo, pede nome e cria novo
      final projectName = await showDialog<String>(
        context: context,
        builder: (BuildContext dialogContext) {
          final textController = TextEditingController(text: _rootNode.name);
          return AlertDialog(
            title: const Text('Salvar Projeto'),
            content: TextField(
              controller: textController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nome do projeto',
                hintText: 'Digite o nome do projeto',
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  Navigator.of(dialogContext).pop(value.trim());
                }
              },
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  final name = textController.text.trim();
                  if (name.isNotEmpty) {
                    Navigator.of(dialogContext).pop(name);
                  }
                },
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      );

      if (projectName == null || projectName.isEmpty) {
        return; // Usuário cancelou ou nome vazio
      }

      // Atualiza o nome do projeto na raiz
      setState(() {
        _rootNode = _rootNode.copyWith(name: projectName);
      });

      // Solicita pasta pai onde criar o projeto
      final parentFolder = await ProjectService.selectParentFolder();
      if (parentFolder == null) {
        return; // Usuário cancelou
      }

      // Cria a pasta do projeto
      final projectPath = await ProjectService.createProjectFolder(projectName, parentFolder);
      if (projectPath == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao criar pasta do projeto. A pasta já existe ou nome inválido.')),
          );
        }
        return;
      }

      final saved = await ProjectService.saveProject(projectPath, _rootNode);
      if (!saved) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao salvar projeto')),
          );
        }
        return;
      }

      // Adiciona à lista de projetos recentes
      await Preferences.addRecentProject(projectPath, projectName);

      setState(() {
        _currentProjectPath = projectPath;
        _hasUnsavedChanges = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Projeto salvo com sucesso')),
        );
      }
    } else {
      // Salva no caminho atual
      final saved = await ProjectService.saveProject(_currentProjectPath!, _rootNode);
      if (!saved) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao salvar projeto')),
          );
        }
        return;
      }

      setState(() {
        _hasUnsavedChanges = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Projeto salvo com sucesso')),
        );
      }
    }
  }

  Future<void> _handleCloseProject() async {
    // Verifica alterações não salvas
    final canContinue = await _handleUnsavedChangesDialog();
    if (!canContinue) {
      return; // Usuário cancelou
    }

    // Limpa estado e mostra tela de boas-vindas
    setState(() {
      _rootNode = Node(
        id: 'root',
        name: 'Novo Projeto',
      );
      _currentProjectPath = null;
      _hasUnsavedChanges = false;
      _showWelcomeScreen = true;
      _selectedNodeId = null;
      _expandedNodes.clear();
      _showDocumentEditor = true; // Reseta para mostrar todas as janelas
    });

    // Limpa histórico de comandos
    _commandHistory.clear();
    _checkpointManager.clearCheckpoints();
  }

  Future<void> _handleOpenProjectLocation() async {
    if (_currentProjectPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum projeto aberto')),
      );
      return;
    }

    try {
      final directory = Directory(_currentProjectPath!);
      if (!directory.existsSync()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A pasta do projeto não existe mais')),
        );
        return;
      }

      // Abre o explorador de arquivos na pasta do projeto
      if (Platform.isWindows) {
        // Windows: usa explorer.exe
        await Process.run('explorer.exe', [_currentProjectPath!]);
      } else if (Platform.isLinux) {
        // Linux: usa xdg-open
        await Process.run('xdg-open', [_currentProjectPath!]);
      } else if (Platform.isMacOS) {
        // macOS: usa open
        await Process.run('open', [_currentProjectPath!]);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sistema operacional não suportado')),
        );
      }
    } catch (e) {
      print('❌ Erro ao abrir localização do projeto: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao abrir localização: $e')),
      );
    }
  }

  // ========== Métodos de Undo/Redo ==========

  Future<void> _handleUndo() async {
    final affectedNodeId = await _commandHistory.undo(_rootNode);
    
    // Se houver um node afetado, apenas seleciona (sem mexer no foco)
    // O foco será mantido onde está, permitindo múltiplos undos consecutivos
    if (affectedNodeId != null && mounted) {
      setState(() {
        _selectedNodeId = affectedNodeId;
      });
      // Notifica mudança de seleção para atualizar o TreeView
      _handleSelectionChanged(affectedNodeId);
    }
  }

  Future<void> _handleRedo() async {
    final affectedNodeId = await _commandHistory.redo(_rootNode);
    
    // Se houver um node afetado, apenas seleciona (sem mexer no foco)
    // O foco será mantido onde está, permitindo múltiplos redos consecutivos
    if (affectedNodeId != null && mounted) {
      setState(() {
        _selectedNodeId = affectedNodeId;
      });
      // Notifica mudança de seleção para atualizar o TreeView
      _handleSelectionChanged(affectedNodeId);
    }
  }

  Future<void> _handleCreateCheckpoint() async {
    final checkpointName = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        final textController = TextEditingController();
        return AlertDialog(
          title: const Text('Criar Checkpoint'),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nome do checkpoint (opcional)',
              hintText: 'Ex: Antes de importação LLM',
            ),
            onSubmitted: (value) {
              Navigator.of(dialogContext).pop(value.trim().isEmpty ? null : value.trim());
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final name = textController.text.trim();
                Navigator.of(dialogContext).pop(name.isEmpty ? null : name);
              },
              child: const Text('Criar'),
            ),
          ],
        );
      },
    );

    // Se checkpointName é null, usuário cancelou o dialog
    if (checkpointName == null) {
      return;
    }

    try {
      await _checkpointManager.createCheckpoint(checkpointName.isEmpty ? null : checkpointName, _rootNode);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkpoint criado${checkpointName.isEmpty ? "" : ": $checkpointName"}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar checkpoint: $e')),
        );
      }
    }
  }

  Future<void> _handleManageCheckpoints() async {
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return CheckpointDialog(
          checkpointManager: _checkpointManager,
          onRestoreCheckpoint: (checkpointId) async {
            try {
              await _checkpointManager.restoreCheckpoint(checkpointId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Checkpoint restaurado com sucesso')),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao restaurar checkpoint: $e')),
                );
              }
            }
          },
          onDeleteCheckpoint: (checkpointId) async {
            try {
              await _checkpointManager.deleteCheckpoint(checkpointId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Checkpoint deletado com sucesso')),
                );
                // Recria o dialog para atualizar a lista
                _handleManageCheckpoints();
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao deletar checkpoint: $e')),
                );
              }
            }
          },
        );
      },
    );
  }

  String _getWindowTitle() {
    if (_showWelcomeScreen) {
      return 'Smart Document - Sem projeto';
    }
    if (_currentProjectPath != null) {
      final projectName = _rootNode.name;
      final unsavedIndicator = _hasUnsavedChanges ? ' *' : '';
      return 'Smart Document - $projectName$unsavedIndicator';
    }
    final unsavedIndicator = _hasUnsavedChanges ? ' *' : '';
    return 'Smart Document - Sem projeto$unsavedIndicator';
  }

  @override
  Widget build(BuildContext context) {
    // Atalhos globais - sempre funcionam, mesmo com TextFields focados
    // IMPORTANTE: O shortcut 'n' só é adicionado quando NÃO está editando
    // para não interferir na digitação de texto em TextFields
    final shortcuts = <LogicalKeySet, Intent>{
      // Undo/Redo - sempre disponíveis
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ): const _GlobalUndoIntent(),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY): const _GlobalRedoIntent(),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyZ): const _GlobalRedoIntent(),
      // Deletar node - só funciona quando não está editando
      // Apenas DEL (Delete), não Backspace
      LogicalKeySet(LogicalKeyboardKey.delete): const _DeleteNodeGlobalIntent(),
    };
    
    // Só adiciona shortcut 'n' quando NÃO está editando
    // Isso permite que a letra 'n' seja digitada normalmente em TextFields
    if (!_isEditing) {
      shortcuts[LogicalKeySet(LogicalKeyboardKey.keyN)] = const _AddNodeGlobalIntent();
    }
    
    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: {
          _GlobalUndoIntent: CallbackAction<_GlobalUndoIntent>(
            onInvoke: (_) {
              print('⌨️ [Main] CTRL+Z PRESSIONADO GLOBALMENTE');
              print('   _mainFocusNode.hasFocus: ${_mainFocusNode.hasFocus}');
              print('   _isEditing: $_isEditing');
              developer.log('Main: Ctrl+Z pressionado globalmente. hasFocus=${_mainFocusNode.hasFocus}, _isEditing=$_isEditing');
              
              // Verifica o foco atual
              final focusScope = FocusScope.of(context);
              final focusedChild = focusScope.focusedChild;
              print('   focusedChild: ${focusedChild?.runtimeType}');
              developer.log('Main: focusedChild=${focusedChild?.runtimeType}');
              
              // Undo sempre funciona, mesmo durante edição
              _handleUndo();
              return null;
            },
          ),
          _GlobalRedoIntent: CallbackAction<_GlobalRedoIntent>(
            onInvoke: (_) {
              print('⌨️ [Main] CTRL+Y PRESSIONADO GLOBALMENTE');
              print('   _mainFocusNode.hasFocus: ${_mainFocusNode.hasFocus}');
              print('   _isEditing: $_isEditing');
              developer.log('Main: Ctrl+Y pressionado globalmente. hasFocus=${_mainFocusNode.hasFocus}, _isEditing=$_isEditing');
              
              // Verifica o foco atual
              final focusScope = FocusScope.of(context);
              final focusedChild = focusScope.focusedChild;
              print('   focusedChild: ${focusedChild?.runtimeType}');
              developer.log('Main: focusedChild=${focusedChild?.runtimeType}');
              
              // Redo sempre funciona, mesmo durante edição
              _handleRedo();
              return null;
            },
          ),
          _AddNodeGlobalIntent: CallbackAction<_AddNodeGlobalIntent>(
            onInvoke: (_) {
              print('⌨️ [Main] N PRESSIONADO GLOBALMENTE');
              print('   _isEditing: $_isEditing');
              print('   _selectedNodeId: $_selectedNodeId');
              print('   _showWindow: $_showWindow');
              
              // Este callback só será chamado se o shortcut existir,
              // e o shortcut só existe quando !_isEditing (definido no build)
              // Mas ainda verificamos por segurança
              if (!_isEditing && _selectedNodeId != null && _showWindow) {
                print('✅ [Main] Condições OK, adicionando node');
                _handleAddNodeShortcut();
              } else {
                print('❌ [Main] Condições não atendidas: _isEditing=$_isEditing, _selectedNodeId=$_selectedNodeId, _showWindow=$_showWindow');
              }
              return null;
            },
          ),
          _DeleteNodeGlobalIntent: CallbackAction<_DeleteNodeGlobalIntent>(
            onInvoke: (_) {
              print('⌨️ [Main] DELETE PRESSIONADO GLOBALMENTE');
              print('   _mainFocusNode.hasFocus: ${_mainFocusNode.hasFocus}');
              print('   _isEditing: $_isEditing');
              print('   _selectedNodeId: $_selectedNodeId');
              print('   _showWindow: $_showWindow');
              developer.log('Main: Delete pressionado globalmente. hasFocus=${_mainFocusNode.hasFocus}, _isEditing=$_isEditing');
              
              // Verifica o foco atual
              final focusScope = FocusScope.of(context);
              final focusedChild = focusScope.focusedChild;
              print('   focusedChild: ${focusedChild?.runtimeType}');
              developer.log('Main: focusedChild=${focusedChild?.runtimeType}');
              
              // Só deleta se não estiver editando e houver um node selecionado
              if (!_isEditing && _selectedNodeId != null && _showWindow) {
                print('✅ [Main] Condições OK, deletando node');
                _handleDeleteNodeShortcut();
              } else {
                print('❌ [Main] Condições não atendidas: _isEditing=$_isEditing, _selectedNodeId=$_selectedNodeId, _showWindow=$_showWindow');
              }
              return null;
            },
          ),
        },
        child: Focus(
          focusNode: _mainFocusNode,
          autofocus: false, // Desativado para não interferir com TreeView
          skipTraversal: false,
          onFocusChange: (hasFocus) {
            print('🔍 [Main] Foco principal mudou: hasFocus=$hasFocus');
            developer.log('Main: Foco principal mudou. hasFocus=$hasFocus');
            
            // NÃO tenta recuperar foco automaticamente - deixa outros widgets (como TreeView) manterem o foco
            // Isso evita conflitos com widgets que precisam de foco para processar teclas (setas, etc)
            if (!hasFocus) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // Verifica se nenhum outro widget tem foco
                final focusScope = FocusScope.of(context);
                final focusedChild = focusScope.focusedChild;
                print('🔍 [Main] Verificando foco após perder: focusedChild=${focusedChild?.runtimeType}');
                developer.log('Main: Verificando foco após perder. focusedChild=${focusedChild?.runtimeType}');
                
                // Só recupera foco se realmente não há nenhum widget focado
                // E se não for um TreeView (que precisa manter o foco para processar setas)
                if (focusedChild == null && mounted) {
                  print('✅ [Main] Nenhum widget focado, recuperando foco principal');
                  developer.log('Main: Nenhum widget focado, recuperando foco principal');
                  _mainFocusNode.requestFocus();
                } else if (focusedChild != null) {
                  print('⚠️ [Main] Outro widget está focado: ${focusedChild.runtimeType}');
                  print('   Não recuperando foco para evitar conflitos');
                  developer.log('Main: Outro widget está focado: ${focusedChild.runtimeType}');
                }
              });
            } else {
              print('✅ [Main] Foco principal recuperado');
              developer.log('Main: Foco principal recuperado');
            }
          },
          child: Scaffold(
      body: Column(
        children: [
          // Menu Bar
          AppMenuBar(
            onNewProject: _handleNewProject,
            onOpenProject: _handleOpenProject,
            onSaveProject: _handleSaveProject,
            onCloseProject: _handleCloseProject,
            onOpenProjectLocation: _handleOpenProjectLocation,
            onUndo: _handleUndo,
            onRedo: _handleRedo,
            onCreateCheckpoint: _handleCreateCheckpoint,
            onManageCheckpoints: _handleManageCheckpoints,
            canUndo: _commandHistory.canUndo,
            canRedo: _commandHistory.canRedo,
            undoDescription: _undoDescription != null ? 'Desfazer: $_undoDescription' : 'Desfazer',
            redoDescription: _redoDescription != null ? 'Refazer: $_redoDescription' : 'Refazer',
            onToggleNavigation: () {
              setState(() {
                _showWindow = !_showWindow;
              });
            },
            onToggleActions: () {
              setState(() {
                _showActionsWindow = !_showActionsWindow;
              });
            },
            onToggleDocumentEditor: () {
              setState(() {
                _showDocumentEditor = !_showDocumentEditor;
              });
            },
            showNavigation: _showWindow,
            showActions: _showActionsWindow,
            showDocumentEditor: _showDocumentEditor,
          ),
          // Conteúdo principal
          Expanded(
            child: _showWelcomeScreen
                ? WelcomeScreen(
                    onNewProject: _handleNewProject,
                    onOpenProject: _handleOpenProject,
                    onOpenRecentProject: _handleOpenRecentProject,
                  )
                : Stack(
                    children: [
                      // Área principal - Background escuro para contraste
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundDark, // Fundo mais escuro para contraste
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.description,
                                size: 64,
                                color: AppTheme.neonBlue.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Área de trabalho principal',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Janela flutuante com TreeView
                      if (_showWindow)
                        DraggableResizableWindow(
                          key: const ValueKey('navigation_window'),
                          title: 'Navegação',
                          initialWidth: 300,
                          initialHeight: 500,
                          minWidth: 250,
                          minHeight: 300,
                          initialPosition: const Offset(50, 50),
                          onClose: () {
                            setState(() {
                              _showWindow = false;
                            });
                          },
                          // Removido onTap para permitir que o TreeView mantenha o foco e capture F2
                          child: TreeView(
                            rootNode: _rootNode,
                            onNodeNameChanged: _updateRootNode,
                            onSelectionChanged: _handleSelectionChanged,
                            onEditingStateChanged: _handleEditingStateChanged,
                            onExpansionChanged: _handleExpansionChanged,
                            onNodeReordered: _handleNodeReordered,
                            onNodeParentChanged: _handleNodeParentChanged,
                            onNodeAdded: _handleNodeAdded,
                            onNodeDeleted: _handleNodeDeleted,
                            // onUndo e onRedo removidos - agora são gerenciados globalmente
                          ),
                        ),
                      // Janela flutuante com ActionsPanel (sempre visível)
                      if (_showActionsWindow)
                        DraggableResizableWindow(
                          key: const ValueKey('actions_window'),
                          title: 'Ações',
                          initialWidth: 350,
                          initialHeight: 500,
                          minWidth: 280,
                          minHeight: 300,
                          initialPosition: const Offset(400, 50),
                          onClose: () {
                            setState(() {
                              _showActionsWindow = false;
                            });
                          },
                          onTap: () {
                            // Retorna foco ao widget principal quando clica na janela
                            if (!_mainFocusNode.hasFocus) {
                              print('🖱️ [Main] Clique na janela Ações, retornando foco');
                              _mainFocusNode.requestFocus();
                            }
                          },
                          child: ActionsPanel(
                            selectedNode: _getSelectedNode(),
                            isEditing: _isEditing,
                            isExpanded: _getSelectedNodeExpansionState(),
                          ),
                        ),
                      // Janela flutuante com DocumentEditor
                      if (_showDocumentEditor)
                        DraggableResizableWindow(
                          key: const ValueKey('document_editor_window'),
                          title: 'Editor de Documento',
                          initialWidth: 400,
                          initialHeight: 600,
                          minWidth: 350,
                          minHeight: 400,
                          initialPosition: const Offset(800, 50),
                          onClose: () {
                            setState(() {
                              _showDocumentEditor = false;
                            });
                          },
                          onTap: () {
                            // Retorna foco ao widget principal quando clica na janela (mas não nos campos)
                            // Isso é tratado pelo DocumentEditor também, mas aqui é uma segunda camada
                            final focusScope = FocusScope.of(context);
                            final hasTextFieldFocused = focusScope.focusedChild?.runtimeType.toString().contains('TextField') ?? false;
                            
                            if (!hasTextFieldFocused && !_mainFocusNode.hasFocus) {
                              print('🖱️ [Main] Clique na janela Editor de Documento (fora dos campos), retornando foco');
                              _mainFocusNode.requestFocus();
                            }
                          },
                          child: DocumentEditor(
                            selectedNode: _getSelectedNode(),
                            onFieldChanged: _handleFieldChanged,
                            onFieldRemoved: _handleFieldRemoved,
                            onFieldAdded: _handleFieldAdded,
                            mainAppFocusNode: _mainFocusNode,
                            projectPath: _currentProjectPath,
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
          ),
        ),
      ),
    );
  }
}

// Intent para undo global (Ctrl+Z)
class _GlobalUndoIntent extends Intent {
  const _GlobalUndoIntent();
}

// Intent para redo global (Ctrl+Y ou Ctrl+Shift+Z)
class _GlobalRedoIntent extends Intent {
  const _GlobalRedoIntent();
}

// Intent para adicionar node globalmente (N)
class _AddNodeGlobalIntent extends Intent {
  const _AddNodeGlobalIntent();
}

// Intent para deletar node globalmente (Delete/Backspace)
class _DeleteNodeGlobalIntent extends Intent {
  const _DeleteNodeGlobalIntent();
}
