import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/node.dart';
import '../theme/app_theme.dart';
import '../services/prompt_service.dart';
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
  final Set<String> _selectedPromptIds = {}; // IDs dos prompts selecionados

  @override
  void initState() {
    super.initState();
    _promptService = PromptService(
      rootNode: widget.rootNode,
      promptsRootNode: widget.promptsRootNode,
    );
  }

  @override
  void didUpdateWidget(ComposerWindow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Atualiza o serviço quando rootNode ou promptsRootNode muda
    if (oldWidget.rootNode.id != widget.rootNode.id ||
        oldWidget.promptsRootNode.id != widget.promptsRootNode.id) {
      _promptService = PromptService(
        rootNode: widget.rootNode,
        promptsRootNode: widget.promptsRootNode,
      );
      setState(() {});
    }
  }

  void _handlePromptSelectionChanged(Set<String> selectedPromptIds) {
    setState(() {
      _selectedPromptIds.clear();
      _selectedPromptIds.addAll(selectedPromptIds);
      _promptService.setSelectedPrompts(_selectedPromptIds);
    });
  }

  void _handleSelectionChanged(Set<String> selectedNodeIds) {
    setState(() {
      _promptService.setSelectedNodes(selectedNodeIds);
    });
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
                '${_promptService.getSelectedNodeIds().length} selecionado(s)',
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
            onSelectionChanged: _handlePromptSelectionChanged,
          ),
        ),
      ],
    );
  }
}
