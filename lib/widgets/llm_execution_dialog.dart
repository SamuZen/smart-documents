import 'package:flutter/material.dart';
import '../models/llm_provider.dart';
import '../models/llm_model.dart';
import '../services/llm_service.dart';
import '../services/settings_service.dart';
import '../services/llm_history_service.dart';
import '../services/llm_pricing_service.dart';
import '../models/llm_execution_history.dart';
import '../theme/app_theme.dart';
import 'llm_result_dialog.dart';

/// Dialog para executar chamada LLM
class LLMExecutionDialog extends StatefulWidget {
  final String prompt;
  final String? projectPath;

  const LLMExecutionDialog({
    super.key,
    required this.prompt,
    this.projectPath,
  });

  /// Mostra o dialog e retorna o resultado
  static Future<void> show({
    required BuildContext context,
    required String prompt,
    String? projectPath,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LLMExecutionDialog(
        prompt: prompt,
        projectPath: projectPath,
      ),
    );
  }

  @override
  State<LLMExecutionDialog> createState() => _LLMExecutionDialogState();
}

class _LLMExecutionDialogState extends State<LLMExecutionDialog> {
  LLMProvider? _selectedProvider;
  LLMModel? _selectedModel;
  bool _isExecuting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLastConfiguration();
  }

  Future<void> _loadLastConfiguration() async {
    // Tenta carregar última configuração
    final lastProviderStr = await SettingsService.getLastLLMProvider();
    final lastModelStr = await SettingsService.getLastLLMModel();
    
    LLMProvider? provider;
    if (lastProviderStr != null) {
      try {
        provider = LLMProvider.fromJson(lastProviderStr);
      } catch (e) {
        // Se falhar, usa OpenAI como padrão
        provider = LLMProvider.openai;
      }
    } else {
      provider = LLMProvider.openai;
    }
    
    setState(() {
      _selectedProvider = provider;
    });
    
    // Tenta encontrar o último modelo usado
    LLMModel? model;
    if (lastModelStr != null) {
      final models = LLMModel.getAvailableModels(provider);
      try {
        model = models.firstWhere(
          (m) => m.fullName == lastModelStr,
        );
      } catch (e) {
        // Se não encontrar, usa o primeiro disponível
        if (models.isNotEmpty) {
          model = models.first;
        }
      }
    } else {
      final models = LLMModel.getAvailableModels(provider);
      if (models.isNotEmpty) {
        model = models.first;
      }
    }
    
    setState(() {
      _selectedModel = model;
    });
  }

  void _onProviderChanged(LLMProvider? provider) {
    if (provider == null) return;
    
    setState(() {
      _selectedProvider = provider;
      final models = LLMModel.getAvailableModels(provider);
      if (models.isNotEmpty) {
        _selectedModel = models.first;
      } else {
        _selectedModel = null;
      }
      _errorMessage = null;
    });
  }

  Future<void> _execute() async {
    if (_selectedProvider == null || _selectedModel == null) {
      setState(() {
        _errorMessage = 'Selecione um provedor e modelo';
      });
      return;
    }

    // Valida chave de API
    String? apiKey;
    switch (_selectedProvider!) {
      case LLMProvider.openai:
        apiKey = await SettingsService.getOpenAIKey();
        break;
      case LLMProvider.grok:
        apiKey = await SettingsService.getGrokKey();
        break;
      case LLMProvider.gemini:
        apiKey = await SettingsService.getGoogleKey();
        break;
    }

    if (apiKey == null || apiKey.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Chave de API não configurada. Configure nas Configurações.';
      });
      return;
    }

    setState(() {
      _isExecuting = true;
      _errorMessage = null;
    });

    try {
      final response = await LLMService.callLLM(
        prompt: widget.prompt,
        model: _selectedModel!,
        apiKey: apiKey,
      );

      // Calcula custo baseado nos tokens
      final promptTokens = response.metadata['prompt_tokens'] as int?;
      final completionTokens = response.metadata['completion_tokens'] as int?;
      final calculatedCost = LLMPricingService.calculateCost(
        _selectedModel!.fullName,
        promptTokens,
        completionTokens,
      );

      // Salva no histórico
      final history = LLMExecutionHistory.create(
        provider: _selectedProvider!,
        model: _selectedModel!.fullName,
        prompt: widget.prompt,
        response: response.content,
        metadata: {
          ...response.metadata,
          'provider': _selectedProvider!.toJson(),
          if (calculatedCost != null) 'cost': calculatedCost,
        },
      );

      await LLMHistoryService.saveExecution(history, widget.projectPath);

      // Salva última configuração usada
      await SettingsService.setLastLLMProvider(_selectedProvider!.toJson());
      await SettingsService.setLastLLMModel(_selectedModel!.fullName);

      // Fecha este dialog e abre o dialog de resultado
      if (mounted) {
        Navigator.of(context).pop();
        await LLMResultDialog.show(
          context: context,
          history: history,
        );
      }
    } catch (e) {
      setState(() {
        _isExecuting = false;
        _errorMessage = 'Erro ao executar: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: AppTheme.neonBlue,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Call Prompt Composer',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _isExecuting ? null : () => Navigator.of(context).pop(),
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Seleção de provedor
            Text(
              'Provedor',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<LLMProvider>(
              value: _selectedProvider,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: LLMProvider.values.map((provider) {
                return DropdownMenuItem(
                  value: provider,
                  child: Text(provider.displayName),
                );
              }).toList(),
              onChanged: _isExecuting ? null : _onProviderChanged,
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 20),
            // Seleção de modelo
            Text(
              'Modelo',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<LLMModel>(
              value: _selectedModel,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: _selectedProvider != null
                  ? LLMModel.getAvailableModels(_selectedProvider!)
                      .map((model) {
                        return DropdownMenuItem(
                          value: model,
                          child: Text(model.displayName),
                        );
                      })
                      .toList()
                  : [],
              onChanged: _isExecuting
                  ? null
                  : (model) {
                      setState(() {
                        _selectedModel = model;
                        _errorMessage = null;
                      });
                    },
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.error.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppTheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: AppTheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Botões
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isExecuting ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _isExecuting ? null : _execute,
                  child: _isExecuting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.backgroundDark),
                          ),
                        )
                      : const Text('Executar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

