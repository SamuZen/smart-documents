import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/llm_execution_history.dart';

/// Serviço para gerenciar histórico de execuções LLM
class LLMHistoryService {
  static const String _historyDirName = '.smart_actions';
  static const String _historyFileName = 'history.json';

  /// Retorna o caminho do diretório de histórico para um projeto
  static Future<String> _getHistoryDir(String? projectPath) async {
    if (projectPath == null || projectPath.isEmpty) {
      // Se não há projeto, usa diretório temporário
      final tempDir = await getTemporaryDirectory();
      return '${tempDir.path}/$_historyDirName';
    }
    return '$projectPath/$_historyDirName';
  }

  /// Retorna o caminho do arquivo de histórico
  static Future<String> _getHistoryFilePath(String? projectPath) async {
    final historyDir = await _getHistoryDir(projectPath);
    return '$historyDir/$_historyFileName';
  }

  /// Garante que o diretório de histórico existe
  static Future<void> _ensureHistoryDir(String? projectPath) async {
    final historyDir = await _getHistoryDir(projectPath);
    final dir = Directory(historyDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  /// Salva uma execução no histórico
  static Future<void> saveExecution(
    LLMExecutionHistory execution,
    String? projectPath,
  ) async {
    try {
      await _ensureHistoryDir(projectPath);
      final historyFilePath = await _getHistoryFilePath(projectPath);
      
      // Carrega histórico existente
      final history = await loadHistory(projectPath);
      
      // Adiciona nova execução no início
      history.insert(0, execution);
      
      // Limita a 100 execuções mais recentes
      if (history.length > 100) {
        history.removeRange(100, history.length);
      }
      
      // Salva no arquivo
      final file = File(historyFilePath);
      final jsonList = history.map((e) => e.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      print('Erro ao salvar histórico de execução: $e');
      rethrow;
    }
  }

  /// Carrega histórico de execuções
  static Future<List<LLMExecutionHistory>> loadHistory(String? projectPath) async {
    try {
      final historyFilePath = await _getHistoryFilePath(projectPath);
      final file = File(historyFilePath);
      
      if (!await file.exists()) {
        return [];
      }
      
      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        return [];
      }
      
      final jsonList = jsonDecode(content) as List;
      return jsonList
          .map((json) => LLMExecutionHistory.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erro ao carregar histórico de execução: $e');
      return [];
    }
  }

  /// Retorna as execuções mais recentes
  static Future<List<LLMExecutionHistory>> getRecentExecutions(
    String? projectPath, {
    int limit = 10,
  }) async {
    final history = await loadHistory(projectPath);
    if (history.length <= limit) {
      return history;
    }
    return history.sublist(0, limit);
  }
}

