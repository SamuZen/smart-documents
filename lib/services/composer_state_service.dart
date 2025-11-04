import 'dart:io';
import 'dart:convert';

/// Estado do Prompt Composer
class ComposerState {
  final Set<String> selectedNodeIds;
  final Set<String> selectedPromptIds;
  final bool includeChildren;
  final int selectedTab;

  ComposerState({
    required this.selectedNodeIds,
    required this.selectedPromptIds,
    required this.includeChildren,
    required this.selectedTab,
  });

  Map<String, dynamic> toJson() {
    return {
      'selectedNodeIds': selectedNodeIds.toList(),
      'selectedPromptIds': selectedPromptIds.toList(),
      'includeChildren': includeChildren,
      'selectedTab': selectedTab,
    };
  }

  factory ComposerState.fromJson(Map<String, dynamic> json) {
    return ComposerState(
      selectedNodeIds: (json['selectedNodeIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          {},
      selectedPromptIds: (json['selectedPromptIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          {},
      includeChildren: json['includeChildren'] as bool? ?? false,
      selectedTab: json['selectedTab'] as int? ?? 0,
    );
  }

  /// Estado vazio (padrão)
  factory ComposerState.empty() {
    return ComposerState(
      selectedNodeIds: {},
      selectedPromptIds: {},
      includeChildren: false,
      selectedTab: 0,
    );
  }
}

/// Serviço para persistência do estado do Prompt Composer
class ComposerStateService {
  static const String composerStateFileName = 'composer_state.json';

  /// Salva o estado do composer em composer_state.json na pasta do projeto
  static Future<bool> saveState(String projectPath, ComposerState state) async {
    try {
      final directory = Directory(projectPath);
      if (!directory.existsSync()) {
        await directory.create(recursive: true);
      }

      final file = File('${directory.path}/$composerStateFileName');
      final jsonData = state.toJson();

      const encoder = JsonEncoder.withIndent('  ');
      final jsonString = encoder.convert(jsonData);

      await file.writeAsString(jsonString, encoding: utf8);

      print('✅ Estado do composer salvo em: ${file.path}');
      return true;
    } catch (e) {
      print('❌ Erro ao salvar estado do composer: $e');
      return false;
    }
  }

  /// Carrega o estado do composer de composer_state.json na pasta do projeto
  static Future<ComposerState> loadState(String projectPath) async {
    try {
      final file = File('$projectPath/$composerStateFileName');

      if (!file.existsSync()) {
        print('ℹ️ Arquivo composer_state.json não encontrado em: $projectPath (usando estado vazio)');
        return ComposerState.empty();
      }

      final jsonString = await file.readAsString(encoding: utf8);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      final state = ComposerState.fromJson(jsonData);
      print('✅ Estado do composer carregado de: ${file.path}');
      return state;
    } catch (e) {
      print('❌ Erro ao carregar estado do composer: $e');
      return ComposerState.empty();
    }
  }
}

