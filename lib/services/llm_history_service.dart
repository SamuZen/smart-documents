import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/llm_execution_history.dart';

/// Serviço para gerenciar histórico de execuções LLM
class LLMHistoryService {
  static const String _historyDirName = '.smart_actions';
  
  /// Callback chamado quando uma nova execução é salva
  static Function(LLMExecutionHistory)? onExecutionSaved;

  /// Retorna o caminho do diretório de histórico para um projeto
  static Future<String> _getHistoryDir(String? projectPath) async {
    if (projectPath == null || projectPath.isEmpty) {
      // Se não há projeto, usa diretório temporário
      final tempDir = await getTemporaryDirectory();
      return '${tempDir.path}/$_historyDirName';
    }
    return '$projectPath/$_historyDirName';
  }

  /// Retorna o caminho do arquivo de histórico para uma execução específica
  static Future<String> _getExecutionFilePath(
    String executionId,
    String? projectPath,
  ) async {
    final historyDir = await _getHistoryDir(projectPath);
    return '$historyDir/$executionId.json';
  }

  /// Garante que o diretório de histórico existe
  static Future<void> _ensureHistoryDir(String? projectPath) async {
    final historyDir = await _getHistoryDir(projectPath);
    final dir = Directory(historyDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  /// Salva uma execução no histórico (um arquivo JSON por execução)
  static Future<void> saveExecution(
    LLMExecutionHistory execution,
    String? projectPath,
  ) async {
    try {
      await _ensureHistoryDir(projectPath);
      final executionFilePath = await _getExecutionFilePath(
        execution.id,
        projectPath,
      );
      
      // Salva execução em arquivo próprio
      final file = File(executionFilePath);
      await file.writeAsString(jsonEncode(execution.toJson()));
      
      // Notifica listeners sobre nova execução
      onExecutionSaved?.call(execution);
    } catch (e) {
      print('Erro ao salvar histórico de execução: $e');
      rethrow;
    }
  }

  /// Carrega histórico de execuções (lê todos os arquivos JSON do diretório)
  static Future<List<LLMExecutionHistory>> loadHistory(String? projectPath) async {
    try {
      final historyDir = await _getHistoryDir(projectPath);
      final dir = Directory(historyDir);
      
      if (!await dir.exists()) {
        return [];
      }
      
      final files = dir.listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList();
      
      final history = <LLMExecutionHistory>[];
      
      for (final file in files) {
        try {
          final content = await file.readAsString();
          if (content.trim().isEmpty) continue;
          
          final json = jsonDecode(content) as Map<String, dynamic>;
          history.add(LLMExecutionHistory.fromJson(json));
        } catch (e) {
          print('Erro ao ler arquivo de histórico ${file.path}: $e');
          // Continua com próximo arquivo
        }
      }
      
      // Ordena por timestamp (mais recente primeiro)
      history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return history;
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
  
  /// Deleta uma execução do histórico
  static Future<void> deleteExecution(
    String executionId,
    String? projectPath,
  ) async {
    try {
      final executionFilePath = await _getExecutionFilePath(
        executionId,
        projectPath,
      );
      final file = File(executionFilePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Erro ao deletar execução do histórico: $e');
      rethrow;
    }
  }
}

