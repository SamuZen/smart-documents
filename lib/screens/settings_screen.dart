import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onClose;

  const SettingsScreen({
    super.key,
    this.onClose,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _hasChanges = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadSettings();
  }

  void _initializeControllers() {
    _controllers['openai'] = TextEditingController();
    _controllers['anthropic'] = TextEditingController();
    _controllers['google'] = TextEditingController();
    
    // Adiciona listeners para detectar mudanças
    _controllers.forEach((key, controller) {
      controller.addListener(() {
        setState(() {
          _hasChanges[key] = true;
        });
      });
    });
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final openAIKey = await SettingsService.getOpenAIKey();
      final anthropicKey = await SettingsService.getAnthropicKey();
      final googleKey = await SettingsService.getGoogleKey();

      setState(() {
        _controllers['openai']!.text = openAIKey ?? '';
        _controllers['anthropic']!.text = anthropicKey ?? '';
        _controllers['google']!.text = googleKey ?? '';
        _hasChanges.clear();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar configurações: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await SettingsService.setOpenAIKey(_controllers['openai']!.text);
      await SettingsService.setAnthropicKey(_controllers['anthropic']!.text);
      await SettingsService.setGoogleKey(_controllers['google']!.text);

      setState(() {
        _hasChanges.clear();
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Configurações salvas com sucesso'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar configurações: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  bool _hasUnsavedChanges() {
    return _hasChanges.values.any((hasChange) => hasChange);
  }

  Future<void> _handleCancel() async {
    if (_hasUnsavedChanges()) {
      final shouldDiscard = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Descartar alterações?'),
          content: const Text(
            'Você tem alterações não salvas. Deseja descartá-las?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Descartar'),
            ),
          ],
        ),
      );

      if (shouldDiscard != true) {
        return;
      }
    }

    widget.onClose?.call();
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.borderNeutral,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.neonBlue.withOpacity(0.3),
                        AppTheme.neonCyan.withOpacity(0.2),
                      ],
                    ),
                    boxShadow: AppTheme.neonGlowBlue,
                  ),
                  child: const Icon(
                    Icons.settings,
                    size: 32,
                    color: AppTheme.neonBlue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configurações',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.neonBlue,
                              letterSpacing: 1.0,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gerencie suas chaves de API e configurações',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _handleCancel,
                  tooltip: 'Fechar',
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Seção Chaves de API
                            Text(
                              'Chaves de API',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Configure suas chaves de autenticação para serviços LLM',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                            const SizedBox(height: 24),
                            // Card OpenAI
                            _buildApiKeyCard(
                              serviceName: 'OpenAI',
                              controller: _controllers['openai']!,
                              icon: Icons.auto_awesome,
                              description: 'Chave de API da OpenAI (GPT-4, GPT-3.5, etc.)',
                            ),
                            const SizedBox(height: 16),
                            // Card Anthropic
                            _buildApiKeyCard(
                              serviceName: 'Anthropic',
                              controller: _controllers['anthropic']!,
                              icon: Icons.psychology,
                              description: 'Chave de API da Anthropic (Claude)',
                            ),
                            const SizedBox(height: 16),
                            // Card Google
                            _buildApiKeyCard(
                              serviceName: 'Google',
                              controller: _controllers['google']!,
                              icon: Icons.cloud,
                              description: 'Chave de API do Google (Gemini)',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          // Footer com botões
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              border: Border(
                top: BorderSide(
                  color: AppTheme.borderNeutral,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isSaving ? null : _handleCancel,
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: _isSaving ? null : _saveSettings,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.backgroundDark),
                          ),
                        )
                      : const Text('Salvar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyCard({
    required String serviceName,
    required TextEditingController controller,
    required IconData icon,
    required String description,
  }) {
    final hasKey = controller.text.isNotEmpty;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: AppTheme.neonBlue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            serviceName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                          ),
                          const SizedBox(width: 8),
                          if (hasKey)
                            Icon(
                              Icons.check_circle,
                              size: 18,
                              color: AppTheme.success,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Chave de API',
                hintText: 'Digite sua chave de API',
                suffixIcon: hasKey
                    ? IconButton(
                        icon: const Icon(Icons.visibility_off),
                        onPressed: () {
                          // Opcional: botão para mostrar/ocultar chave
                        },
                        tooltip: 'Chave salva',
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

