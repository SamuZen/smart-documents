import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/node.dart';
import '../models/prompt.dart';
import '../theme/app_theme.dart';
import '../services/prompt_service.dart';
import '../services/prompt_manager_service.dart';
import '../services/prompt_storage_service.dart';
import 'prompt_composer_tree_view.dart';

/// Janela Prompt Composer com seleção múltipla e formatação de texto para LLM
class ComposerWindow extends StatefulWidget {
  final Node rootNode;
  final PromptManagerService? promptManager;
  final String? projectPath;

  const ComposerWindow({
    super.key,
    required this.rootNode,
    this.promptManager,
    this.projectPath,
  });

  @override
  State<ComposerWindow> createState() => _ComposerWindowState();
}

class _ComposerWindowState extends State<ComposerWindow> {
  late PromptService _promptService;
  bool _includeChildren = false;
  int _selectedTab = 0; // 0 = Nodes, 1 = Prompts

  @override
  void initState() {
    super.initState();
    _promptService = PromptService(
      rootNode: widget.rootNode,
      promptManager: widget.promptManager,
    );
  }

  @override
  void didUpdateWidget(ComposerWindow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Atualiza o serviço quando rootNode ou promptManager muda
    if (oldWidget.rootNode.id != widget.rootNode.id ||
        oldWidget.promptManager != widget.promptManager) {
      _promptService = PromptService(
        rootNode: widget.rootNode,
        promptManager: widget.promptManager,
      );
      setState(() {});
    }
  }

  Future<void> _savePrompts() async {
    if (widget.projectPath != null && widget.promptManager != null) {
      await PromptStorageService.savePrompts(
        widget.projectPath!,
        widget.promptManager!.getAllPrompts(),
      );
    }
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
    if (!_promptService.hasSelection()) {
      return '// Selecione pelo menos um node para gerar o prompt';
    }
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
                            // Botão copiar
                            OutlinedButton.icon(
                              onPressed: _promptService.hasSelection()
                                  ? _copyToClipboard
                                  : null,
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
                            'Selecione nodes para gerar o prompt',
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
    if (widget.promptManager == null) {
      return Center(
        child: Text(
          'Gerenciamento de prompts não disponível',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho com botão adicionar
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
                'Gerenciar Prompts',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => _showAddPromptDialog(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Adicionar'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Lista de prompts por categoria
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              _buildPromptCategory('Início (Start)', PromptOrder.start),
              const SizedBox(height: 16),
              _buildPromptCategory('Após (After)', PromptOrder.after),
              const SizedBox(height: 16),
              _buildPromptCategory('Fim (End)', PromptOrder.end),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPromptCategory(String title, PromptOrder order) {
    final prompts = widget.promptManager!.getPromptsByOrder(order);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        if (prompts.isEmpty)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              'Nenhum prompt',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ...prompts.map((prompt) => _buildPromptItem(prompt)),
      ],
    );
  }

  Widget _buildPromptItem(Prompt prompt) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppTheme.borderNeutral,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prompt.prompt,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${prompt.id}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            color: AppTheme.neonCyan,
            onPressed: () => _showEditPromptDialog(prompt),
            tooltip: 'Editar',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.delete, size: 18),
            color: AppTheme.error,
            onPressed: () => _showDeletePromptDialog(prompt),
            tooltip: 'Remover',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddPromptDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _PromptDialog(
        title: 'Adicionar Prompt',
      ),
    );

    if (result != null && widget.promptManager != null) {
      final promptId = 'prompt-${DateTime.now().millisecondsSinceEpoch}';
      final prompt = Prompt(
        id: promptId,
        prompt: result['prompt'] as String,
        order: result['order'] as PromptOrder,
      );
      
      widget.promptManager!.addPrompt(prompt);
      await _savePrompts();
      setState(() {});
    }
  }

  Future<void> _showEditPromptDialog(Prompt prompt) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _PromptDialog(
        title: 'Editar Prompt',
        initialPrompt: prompt.prompt,
        initialOrder: prompt.order,
      ),
    );

    if (result != null && widget.promptManager != null) {
      final updatedPrompt = prompt.copyWith(
        prompt: result['prompt'] as String,
        order: result['order'] as PromptOrder,
      );
      
      widget.promptManager!.updatePrompt(prompt.id, updatedPrompt);
      await _savePrompts();
      setState(() {});
    }
  }

  Future<void> _showDeletePromptDialog(Prompt prompt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Prompt'),
        content: Text('Deseja remover este prompt?\n\n"${prompt.prompt.substring(0, prompt.prompt.length > 50 ? 50 : prompt.prompt.length)}${prompt.prompt.length > 50 ? '...' : ''}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.promptManager != null) {
      widget.promptManager!.removePrompt(prompt.id);
      await _savePrompts();
      setState(() {});
    }
  }
}

class _PromptDialog extends StatefulWidget {
  final String title;
  final String? initialPrompt;
  final PromptOrder? initialOrder;

  const _PromptDialog({
    required this.title,
    this.initialPrompt,
    this.initialOrder,
  });

  @override
  State<_PromptDialog> createState() => _PromptDialogState();
}

class _PromptDialogState extends State<_PromptDialog> {
  late TextEditingController _promptController;
  late PromptOrder _selectedOrder;

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController(text: widget.initialPrompt ?? '');
    _selectedOrder = widget.initialOrder ?? PromptOrder.start;
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _promptController,
              autofocus: true,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Texto do prompt',
                hintText: 'Digite o texto do prompt',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ordem:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...PromptOrder.values.map((order) => RadioListTile<PromptOrder>(
              title: Text(_getOrderLabel(order)),
              value: order,
              groupValue: _selectedOrder,
              onChanged: (value) {
                setState(() {
                  _selectedOrder = value!;
                });
              },
              contentPadding: EdgeInsets.zero,
            )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (_promptController.text.trim().isNotEmpty) {
              Navigator.of(context).pop({
                'prompt': _promptController.text.trim(),
                'order': _selectedOrder,
              });
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  String _getOrderLabel(PromptOrder order) {
    switch (order) {
      case PromptOrder.start:
        return 'Início (Start) - Antes do contexto dos nodes';
      case PromptOrder.after:
        return 'Após (After) - Depois do contexto dos nodes';
      case PromptOrder.end:
        return 'Fim (End) - No final do prompt';
    }
  }
}
