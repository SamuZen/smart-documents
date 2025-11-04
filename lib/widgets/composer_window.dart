import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/node.dart';
import '../theme/app_theme.dart';
import '../services/prompt_service.dart';
import '../services/composer_state_service.dart';
import 'prompt_composer_tree_view.dart';

/// Janela Prompt Composer com seleção múltipla e formatação de texto para LLM
class ComposerWindow extends StatefulWidget {
  final Node rootNode;
  final Node promptsRootNode;
  final String? projectPath;

  const ComposerWindow({
    super.key,
    required this.rootNode,
    required this.promptsRootNode,
    this.projectPath,
  });

  @override
  State<ComposerWindow> createState() => _ComposerWindowState();
}

class _ComposerWindowState extends State<ComposerWindow> {
  late PromptService _promptService;
  bool _includeChildren = false;
  int _selectedTab = 0; // 0 = Nodes, 1 = Prompts
  final Set<String> _selectedNodeIds = {}; // IDs dos nodes selecionados (estado local)
  final Set<String> _selectedPromptIds = {}; // IDs dos prompts selecionados

  @override
  void initState() {
    super.initState();
    _promptService = PromptService(
      rootNode: widget.rootNode,
      promptsRootNode: widget.promptsRootNode,
    );
    _loadState();
  }

  /// Carrega o estado salvo do composer
  Future<void> _loadState() async {
    if (widget.projectPath == null) return;

    try {
      final state = await ComposerStateService.loadState(widget.projectPath!);
      
      setState(() {
        // Restaura seleções de nodes no estado local
        _selectedNodeIds.clear();
        _selectedNodeIds.addAll(state.selectedNodeIds);
        
        // Restaura seleções de prompts
        _selectedPromptIds.clear();
        _selectedPromptIds.addAll(state.selectedPromptIds);
        
        // Atualiza o serviço com as seleções restauradas
        _promptService.setSelectedNodes(_selectedNodeIds);
        _promptService.setSelectedPrompts(_selectedPromptIds);
        
        // Restaura outras configurações
        _includeChildren = state.includeChildren;
        _selectedTab = state.selectedTab;
      });
    } catch (e) {
      print('❌ Erro ao carregar estado do composer: $e');
    }
  }

  /// Salva o estado atual do composer
  Future<void> _saveState() async {
    if (widget.projectPath == null) return;

    try {
      final state = ComposerState(
        selectedNodeIds: _selectedNodeIds,
        selectedPromptIds: _selectedPromptIds,
        includeChildren: _includeChildren,
        selectedTab: _selectedTab,
      );
      
      await ComposerStateService.saveState(widget.projectPath!, state);
    } catch (e) {
      print('❌ Erro ao salvar estado do composer: $e');
    }
  }

  @override
  void didUpdateWidget(ComposerWindow oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Como Nodes são imutáveis, se os widgets mudaram, significa que houve alteração
    // Salva as seleções atuais antes de atualizar (usa estado local, não o serviço)
    final currentSelectedNodeIds = Set<String>.from(_selectedNodeIds);
    final currentSelectedPromptIds = Set<String>.from(_selectedPromptIds);
    
    // Verifica se houve mudança real comparando referências e propriedades básicas
    // Como Nodes são imutáveis, uma nova referência significa mudança
    final rootNodeChanged = oldWidget.rootNode != widget.rootNode ||
        oldWidget.rootNode.name != widget.rootNode.name ||
        oldWidget.rootNode.children.length != widget.rootNode.children.length ||
        oldWidget.rootNode.fields.length != widget.rootNode.fields.length;
    
    final promptsRootNodeChanged = oldWidget.promptsRootNode != widget.promptsRootNode ||
        oldWidget.promptsRootNode.name != widget.promptsRootNode.name ||
        oldWidget.promptsRootNode.children.length != widget.promptsRootNode.children.length ||
        oldWidget.promptsRootNode.fields.length != widget.promptsRootNode.fields.length;
    
    final projectPathChanged = oldWidget.projectPath != widget.projectPath;
    
    // Se houve mudança, atualiza o serviço
    if (rootNodeChanged || promptsRootNodeChanged || projectPathChanged) {
      // Atualiza o PromptService com os novos nodes primeiro
      _promptService = PromptService(
        rootNode: widget.rootNode,
        promptsRootNode: widget.promptsRootNode,
      );
      
      // Valida e limpa seleções de nodes que não existem mais, preservando as válidas
      Set<String> validNodeIds;
      if (rootNodeChanged) {
        validNodeIds = _validateAndCleanNodeSelections(currentSelectedNodeIds);
      } else {
        // Se não mudou, mantém as seleções atuais
        validNodeIds = currentSelectedNodeIds;
      }
      
      // Valida e limpa seleções de prompts que não existem mais, preservando as válidas
      Set<String> validPromptIds;
      if (promptsRootNodeChanged) {
        validPromptIds = _validateAndCleanPromptSelections(currentSelectedPromptIds);
      } else {
        // Se não mudou, mantém as seleções atuais
        validPromptIds = currentSelectedPromptIds;
      }
      
      // Restaura as seleções válidas no estado local e no novo serviço
      setState(() {
        _selectedNodeIds.clear();
        _selectedNodeIds.addAll(validNodeIds);
        _selectedPromptIds.clear();
        _selectedPromptIds.addAll(validPromptIds);
      });
      
      // Atualiza o serviço com as seleções restauradas
      _promptService.setSelectedNodes(_selectedNodeIds);
      _promptService.setSelectedPrompts(_selectedPromptIds);
      
      // Recarrega o estado quando o projeto muda
      if (projectPathChanged) {
        _loadState();
      } else {
        // Salva o estado atualizado se não foi mudança de projeto
        _saveState();
      }
    }
  }

  /// Valida e remove seleções de nodes que não existem mais na árvore
  /// Retorna o conjunto de IDs válidos
  Set<String> _validateAndCleanNodeSelections(Set<String> selectedNodeIds) {
    final validNodeIds = <String>{};
    
    for (final nodeId in selectedNodeIds) {
      if (widget.rootNode.findById(nodeId) != null) {
        validNodeIds.add(nodeId);
      }
    }
    
    return validNodeIds;
  }

  /// Valida e remove seleções de prompts que não existem mais na árvore
  /// Retorna o conjunto de IDs válidos
  Set<String> _validateAndCleanPromptSelections(Set<String> selectedPromptIds) {
    final validPromptIds = <String>{};
    
    for (final promptId in selectedPromptIds) {
      if (widget.promptsRootNode.findById(promptId) != null) {
        validPromptIds.add(promptId);
      }
    }
    
    return validPromptIds;
  }

  void _handlePromptSelectionChanged(Set<String> selectedPromptIds) {
    setState(() {
      _selectedPromptIds.clear();
      _selectedPromptIds.addAll(selectedPromptIds);
      _promptService.setSelectedPrompts(_selectedPromptIds);
    });
    _saveState(); // Salva estado após mudança
  }

  void _handleSelectionChanged(Set<String> selectedNodeIds) {
    setState(() {
      _selectedNodeIds.clear();
      _selectedNodeIds.addAll(selectedNodeIds);
      _promptService.setSelectedNodes(_selectedNodeIds);
    });
    _saveState(); // Salva estado após mudança
  }

  void _copyToClipboard() {
    final prompt = _promptService.generatePrompt(
      includeChildren: _includeChildren,
    );
    Clipboard.setData(ClipboardData(text: prompt));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Prompt copiado para a área de transferência!',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        backgroundColor: AppTheme.surfaceVariantDark,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getFormattedPrompt() {
    return _promptService.generatePrompt(
      includeChildren: _includeChildren,
    );
  }

  int _getCharacterCount() {
    return _getFormattedPrompt().length;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceDark,
      child: Row(
        children: [
          // Coluna esquerda: Abas para Nodes e Prompts
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                border: Border(
                  right: BorderSide(
                    color: AppTheme.borderNeutral,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Abas
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      border: Border(
                        bottom: BorderSide(
                          color: AppTheme.borderNeutral,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTabButton(
                            'Nodes',
                            Icons.check_box,
                            0,
                            AppTheme.neonBlue,
                          ),
                        ),
                        Expanded(
                          child: _buildTabButton(
                            'Prompts',
                            Icons.text_fields,
                            1,
                            AppTheme.neonCyan,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Conteúdo da aba selecionada
                  Expanded(
                    child: _selectedTab == 0
                        ? _buildNodesTab()
                        : _buildPromptsTab(),
                  ),
                ],
              ),
            ),
          ),
          // Coluna direita: Preview e formatação
          Expanded(
            flex: 3,
            child: Container(
              color: AppTheme.surfaceDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho da seção de preview
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      border: Border(
                        bottom: BorderSide(
                          color: AppTheme.borderNeutral,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.code,
                          size: 20,
                          color: AppTheme.neonCyan,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Preview do Prompt',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        // Opções de formatação
                        Row(
                          children: [
                            // Checkbox para incluir filhos
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: _includeChildren,
                                  onChanged: (value) {
                                    setState(() {
                                      _includeChildren = value ?? false;
                                    });
                                    _saveState(); // Salva estado após mudança
                                  },
                                  visualDensity: VisualDensity.compact,
                                ),
                                Text(
                                  'Incluir filhos recursivamente',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            // Botão copiar (sempre habilitado, permite copiar prompts mesmo sem nodes)
                            OutlinedButton.icon(
                              onPressed: _copyToClipboard,
                              icon: const Icon(Icons.copy, size: 16),
                              label: const Text('Copiar'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Área de preview
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableText(
                              _getFormattedPrompt(),
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                                fontFamily: 'monospace',
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Rodapé com informações
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      border: Border(
                        top: BorderSide(
                          color: AppTheme.borderNeutral,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_getCharacterCount()} caracteres',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textTertiary,
                          ),
                        ),
                        const Spacer(),
                        if (!_promptService.hasSelection())
                          Text(
                            'Nenhum node selecionado (apenas prompts)',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textTertiary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, IconData icon, int tabIndex, Color color) {
    final isSelected = _selectedTab == tabIndex;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = tabIndex;
        });
        _saveState(); // Salva estado após mudança
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.surfaceDark : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? color : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? color : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNodesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho da seção de seleção
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            border: Border(
              bottom: BorderSide(
                color: AppTheme.borderNeutral,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_box,
                size: 20,
                color: AppTheme.neonBlue,
              ),
              const SizedBox(width: 8),
              Text(
                'Seleção de Nodes',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${_selectedNodeIds.length} selecionado(s)',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // TreeView
        Expanded(
          child: PromptComposerTreeView(
            rootNode: widget.rootNode,
            initialSelection: _selectedNodeIds,
            onSelectionChanged: _handleSelectionChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildPromptsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho da seção de seleção
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            border: Border(
              bottom: BorderSide(
                color: AppTheme.borderNeutral,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.text_fields,
                size: 20,
                color: AppTheme.neonCyan,
              ),
              const SizedBox(width: 8),
              Text(
                'Seleção de Prompts',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${_selectedPromptIds.length} selecionado(s)',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // TreeView de prompts com checkboxes
        Expanded(
          child: PromptComposerTreeView(
            rootNode: widget.promptsRootNode,
            initialSelection: _selectedPromptIds,
            onSelectionChanged: _handlePromptSelectionChanged,
          ),
        ),
      ],
    );
  }
}
