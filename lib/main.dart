import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'models/node.dart';
import 'services/project_service.dart';
import 'widgets/tree_view.dart';
import 'widgets/draggable_resizable_window.dart';
import 'widgets/actions_panel.dart';
import 'widgets/menu_bar.dart';
import 'screens/welcome_screen.dart';
import 'utils/preferences.dart';

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

  // Estado do projeto
  String? _currentProjectPath;
  bool _hasUnsavedChanges = false;
  bool _showWelcomeScreen = true; // Inicia mostrando a tela de boas-vindas

  @override
  void initState() {
    super.initState();
    // Inicia com uma estrutura vazia (será substituída quando carregar projeto)
    _rootNode = Node(
      id: 'root',
      name: 'Novo Projeto',
    );
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
      _markProjectAsModified();
    });
  }

  void _handleNodeParentChanged(String draggedNodeId, String newParentId) {
    developer.log('MyHomePage: _handleNodeParentChanged chamado. draggedNodeId: $draggedNodeId, newParentId: $newParentId');
    
    // A TreeView já atualizou localmente, precisamos sincronizar com a raiz
    setState(() {
      _rootNode = _moveNodeToParent(_rootNode, draggedNodeId, newParentId);
      _markProjectAsModified();
    });
  }

  void _handleNodeAdded(String parentNodeId, String newNodeId, String newNodeName) {
    developer.log('MyHomePage: _handleNodeAdded chamado. parentNodeId: $parentNodeId, newNodeId: $newNodeId, newNodeName: $newNodeName');
    
    // Atualiza a raiz para sincronizar com a TreeView
    setState(() {
      _rootNode = _addNodeToParent(_rootNode, parentNodeId, newNodeId, newNodeName);
      _markProjectAsModified();
    });
  }

  void _handleNodeDeleted(String deletedNodeId) {
    developer.log('MyHomePage: _handleNodeDeleted chamado. deletedNodeId: $deletedNodeId');
    
    // Atualiza a raiz para sincronizar com a TreeView
    setState(() {
      _rootNode = _removeNodeFromTree(_rootNode, deletedNodeId);
      // Remove do set de nodes expandidos se necessário
      _expandedNodes.remove(deletedNodeId);
      // Limpa seleção se o node deletado estava selecionado
      if (_selectedNodeId == deletedNodeId) {
        _selectedNodeId = null;
      }
      _markProjectAsModified();
    });
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

  void _updateRootNode(String nodeId, String newName) {
    developer.log('MyHomePage: _updateRootNode chamado. nodeId: $nodeId, newName: "$newName"');
    final oldName = _rootNode.findById(nodeId)?.name ?? 'NÃO ENCONTRADO';
    developer.log('MyHomePage: Nome antigo do node: "$oldName"');
    
    setState(() {
      _rootNode = _updateNodeInTree(_rootNode, nodeId, newName);
      _markProjectAsModified();
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
    });

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
    });

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
    });
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(_getWindowTitle()),
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
      body: Column(
        children: [
          // Menu Bar
          AppMenuBar(
            onNewProject: _handleNewProject,
            onOpenProject: _handleOpenProject,
            onSaveProject: _handleSaveProject,
            onCloseProject: _handleCloseProject,
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
                            onNodeAdded: _handleNodeAdded,
                            onNodeDeleted: _handleNodeDeleted,
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
          ),
        ],
      ),
    );
  }
}
