import 'dart:io';
import 'dart:convert';
import '../models/node.dart';
import '../models/prompt.dart';
import 'prompt_node_service.dart';

/// Serviço para persistência de prompts em arquivo JSON
/// Agora salva como estrutura de nodes (similar ao project.json)
class PromptStorageService {
  static const String promptsFileName = 'prompts.json';

  /// Salva a estrutura de nodes de prompts em prompts.json na pasta do projeto
  /// Retorna true se salvou com sucesso, false caso contrário
  static Future<bool> savePrompts(String projectPath, Node promptsRootNode) async {
    try {
      final directory = Directory(projectPath);
      if (!directory.existsSync()) {
        // Tenta criar o diretório se não existir
        await directory.create(recursive: true);
      }

      final file = File('${directory.path}/$promptsFileName');
      final jsonData = promptsRootNode.toJson();

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
  /// Retorna Node raiz ou node vazio em caso de erro ou arquivo inexistente
  static Future<Node> loadPrompts(String projectPath) async {
    try {
      final file = File('$projectPath/$promptsFileName');

      if (!file.existsSync()) {
        print('ℹ️ Arquivo prompts.json não encontrado em: $projectPath (criando estrutura vazia)');
        // Retorna estrutura vazia
        return Node(
          id: 'prompts-root',
          name: 'Prompts',
        );
      }

      final jsonString = await file.readAsString(encoding: utf8);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Tenta carregar como estrutura de nodes
      try {
        final rootNode = Node.fromJson(jsonData);
        print('✅ Prompts carregados de: ${file.path}');
        return rootNode;
      } catch (e) {
        // Se falhar, tenta migrar do formato antigo (lista de prompts)
        print('⚠️ Tentando migrar formato antigo de prompts...');
        final promptsJson = jsonData['prompts'] as List<dynamic>? ?? [];
        if (promptsJson.isNotEmpty) {
          final prompts = promptsJson
              .map((promptJson) => Prompt.fromJson(promptJson as Map<String, dynamic>))
              .toList();
          final rootNode = PromptNodeService.promptsToNode(prompts);
          // Salva no novo formato
          await savePrompts(projectPath, rootNode);
          print('✅ Prompts migrados para novo formato');
          return rootNode;
        }
        // Se não conseguiu migrar, retorna estrutura vazia
        return Node(
          id: 'prompts-root',
          name: 'Prompts',
        );
      }
    } catch (e) {
      print('❌ Erro ao carregar prompts: $e');
      return Node(
        id: 'prompts-root',
        name: 'Prompts',
      );
    }
  }

  /// Método de compatibilidade: converte lista de prompts para node e salva
  static Future<bool> savePromptsList(String projectPath, List<Prompt> prompts) async {
    final rootNode = PromptNodeService.promptsToNode(prompts);
    return await savePrompts(projectPath, rootNode);
  }

  /// Método de compatibilidade: carrega node e converte para lista de prompts
  static Future<List<Prompt>> loadPromptsList(String projectPath) async {
    final rootNode = await loadPrompts(projectPath);
    return PromptNodeService.nodesToPrompts(rootNode);
  }
}

