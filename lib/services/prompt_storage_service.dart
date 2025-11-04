import 'dart:io';
import 'dart:convert';
import '../models/prompt.dart';

/// Serviço para persistência de prompts em arquivo JSON
class PromptStorageService {
  static const String promptsFileName = 'prompts.json';

  /// Salva uma lista de prompts em prompts.json na pasta do projeto
  /// Retorna true se salvou com sucesso, false caso contrário
  static Future<bool> savePrompts(String projectPath, List<Prompt> prompts) async {
    try {
      final directory = Directory(projectPath);
      if (!directory.existsSync()) {
        // Tenta criar o diretório se não existir
        await directory.create(recursive: true);
      }

      final file = File('${directory.path}/$promptsFileName');
      final jsonData = {
        'prompts': prompts.map((prompt) => prompt.toJson()).toList(),
      };

      // Usa JsonEncoder com indentação para facilitar edição e visualização no git
      const encoder = JsonEncoder.withIndent('  '); // 2 espaços de indentação
      final jsonString = encoder.convert(jsonData);

      await file.writeAsString(jsonString, encoding: utf8);

      print('✅ Prompts salvos em: ${file.path}');
      return true;
    } catch (e) {
      print('❌ Erro ao salvar prompts: $e');
      return false;
    }
  }

  /// Carrega prompts de prompts.json na pasta do projeto
  /// Retorna lista de prompts ou lista vazia em caso de erro ou arquivo inexistente
  static Future<List<Prompt>> loadPrompts(String projectPath) async {
    try {
      final file = File('$projectPath/$promptsFileName');

      if (!file.existsSync()) {
        print('ℹ️ Arquivo prompts.json não encontrado em: $projectPath (retornando lista vazia)');
        return [];
      }

      final jsonString = await file.readAsString(encoding: utf8);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      final promptsJson = jsonData['prompts'] as List<dynamic>? ?? [];
      final prompts = promptsJson
          .map((promptJson) => Prompt.fromJson(promptJson as Map<String, dynamic>))
          .toList();

      print('✅ Prompts carregados de: ${file.path} (${prompts.length} prompts)');
      return prompts;
    } catch (e) {
      print('❌ Erro ao carregar prompts: $e');
      return [];
    }
  }
}

