import 'package:flutter/material.dart';
import '../models/llm_execution_history.dart';
import '../models/llm_provider.dart';
import '../services/llm_history_service.dart';
import '../theme/app_theme.dart';
import 'llm_result_dialog.dart';

/// Janela para visualizar histórico de execuções LLM
class LLMHistoryWindow extends StatefulWidget {
  final String? projectPath;

  const LLMHistoryWindow({
    super.key,
    this.projectPath,
  });

  @override
  State<LLMHistoryWindow> createState() => _LLMHistoryWindowState();
}

class _LLMHistoryWindowState extends State<LLMHistoryWindow> {
  List<LLMExecutionHistory> _history = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    // Registra listener para atualizações automáticas
    LLMHistoryService.onExecutionSaved = _handleNewExecution;
  }

  @override
  void dispose() {
    // Remove listener ao destruir widget
    LLMHistoryService.onExecutionSaved = null;
    super.dispose();
  }

  void _handleNewExecution(LLMExecutionHistory execution) {
    // Verifica se a execução pertence ao projeto atual
    // (compara projectPath ou verifica se é do mesmo projeto)
    setState(() {
      // Adiciona nova execução no início da lista
      _history.insert(0, execution);
      // Ordena por timestamp (mais recente primeiro)
      _history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final history = await LLMHistoryService.loadHistory(widget.projectPath);
      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar histórico: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteExecution(LLMExecutionHistory execution) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deletar execução?'),
        content: Text(
          'Tem certeza que deseja deletar esta execução?\n\n'
          '${execution.provider.displayName} - ${execution.model}\n'
          '${_formatDateTime(execution.timestamp)}',
        ),
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
            child: const Text('Deletar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await LLMHistoryService.deleteExecution(
        execution.id,
        widget.projectPath,
      );
      // Remove da lista local
      setState(() {
        _history.removeWhere((e) => e.id == execution.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Execução deletada com sucesso'),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao deletar execução: $e'),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceDark,
      child: Column(
        children: [
          // Header
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
                  Icons.history,
                  size: 20,
                  color: AppTheme.neonBlue,
                ),
                const SizedBox(width: 8),
                Text(
                  'Histórico de Smart Actions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: _loadHistory,
                  tooltip: 'Atualizar',
                  color: AppTheme.textSecondary,
                ),
                Text(
                  '${_history.length} execução${_history.length != 1 ? 'ões' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.neonBlue,
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: AppTheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: AppTheme.error,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: _loadHistory,
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      )
                    : _history.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 64,
                                  color: AppTheme.textTertiary.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Nenhuma execução encontrada',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Execute uma Smart Action para ver o histórico aqui',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _history.length,
                            itemBuilder: (context, index) {
                              final execution = _history[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: Icon(
                                    Icons.auto_awesome,
                                    color: _getProviderColor(execution.provider),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${execution.provider.displayName} - ${execution.model}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                      ),
                                      if (execution.tokensUsed != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.neonBlue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            _formatTokens(execution),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.neonBlue,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDateTime(execution.timestamp),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      if (execution.responseTimeMs != null)
                                        Text(
                                          'Tempo: ${execution.responseTimeMs}ms',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textTertiary,
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _truncatePrompt(execution.prompt),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textTertiary,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.visibility, size: 18),
                                        onPressed: () {
                                          LLMResultDialog.show(
                                            context: context,
                                            history: execution,
                                          );
                                        },
                                        tooltip: 'Ver detalhes',
                                        color: AppTheme.neonBlue,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, size: 18),
                                        onPressed: () => _deleteExecution(execution),
                                        tooltip: 'Deletar',
                                        color: AppTheme.error,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Color _getProviderColor(LLMProvider provider) {
    switch (provider) {
      case LLMProvider.openai:
        return AppTheme.neonBlue;
      case LLMProvider.grok:
        return AppTheme.neonPurple;
      case LLMProvider.gemini:
        return AppTheme.neonCyan;
    }
  }

  String _truncatePrompt(String prompt) {
    if (prompt.length <= 100) return prompt;
    return '${prompt.substring(0, 100)}...';
  }

  String _formatTokens(LLMExecutionHistory execution) {
    final total = execution.tokensUsed ?? 0;
    final promptTokens = execution.promptTokens;
    final completionTokens = execution.completionTokens;

    if (promptTokens != null && completionTokens != null) {
      return '$total (in - $promptTokens / out - $completionTokens)';
    } else if (promptTokens != null) {
      return '$total (in - $promptTokens)';
    } else if (completionTokens != null) {
      return '$total (out - $completionTokens)';
    } else {
      return '$total tokens';
    }
  }
}

