import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import '../models/node.dart';
import '../utils/preferences.dart';

class ProjectService {
  static const String projectFileName = 'project.json';

  /// Cria ou seleciona uma pasta de projeto
  /// Retorna o caminho da pasta selecionada, ou null se cancelado
  static Future<String?> createProjectFolder() async {
    try {
      // Tenta obter a última pasta usada
      String? initialDirectory = await Preferences.getLastProjectPath();
      
      // Se não tem última pasta, usa o diretório do usuário
      if (initialDirectory == null || !Directory(initialDirectory).existsSync()) {
        final userDocumentsPath = Platform.isWindows
            ? Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? ''
            : Platform.environment['HOME'] ?? '';
        if (userDocumentsPath.isNotEmpty) {
          initialDirectory = userDocumentsPath;
        }
      }

      // Abre diálogo para selecionar/criar pasta
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Selecione ou crie uma pasta para o projeto',
        initialDirectory: initialDirectory,
      );

      if (selectedDirectory == null) {
        return null;
      }

      // Salva a pasta selecionada nas preferências
      await Preferences.setLastProjectPath(selectedDirectory);

      return selectedDirectory;
    } catch (e) {
      print('Erro ao criar/selecionar pasta de projeto: $e');
      return null;
    }
  }

  /// Salva o projeto na pasta especificada
  /// Retorna true se salvou com sucesso, false caso contrário
  static Future<bool> saveProject(String projectPath, Node rootNode) async {
    try {
      final directory = Directory(projectPath);
      if (!directory.existsSync()) {
        // Tenta criar o diretório se não existir
        await directory.create(recursive: true);
      }

      final file = File('${directory.path}/$projectFileName');
      final jsonData = rootNode.toJson();
      final jsonString = jsonEncode(jsonData);

      await file.writeAsString(jsonString, encoding: utf8);

      // Salva o caminho do projeto nas preferências
      await Preferences.setLastProjectPath(projectPath);

      print('✅ Projeto salvo em: ${file.path}');
      return true;
    } catch (e) {
      print('❌ Erro ao salvar projeto: $e');
      return false;
    }
  }

  /// Carrega um projeto do caminho especificado
  /// Retorna o Node raiz ou null em caso de erro
  static Future<Node?> loadProject(String projectPath) async {
    try {
      final file = File('${projectPath}/$projectFileName');
      
      if (!file.existsSync()) {
        print('❌ Arquivo project.json não encontrado em: $projectPath');
        return null;
      }

      final jsonString = await file.readAsString(encoding: utf8);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      final rootNode = Node.fromJson(jsonData);

      // Salva o caminho do projeto nas preferências
      await Preferences.setLastProjectPath(projectPath);

      print('✅ Projeto carregado de: ${file.path}');
      return rootNode;
    } catch (e) {
      print('❌ Erro ao carregar projeto: $e');
      return null;
    }
  }

  /// Abre diálogo para selecionar arquivo project.json
  /// Retorna o caminho da pasta do projeto (diretório pai do arquivo), ou null se cancelado
  static Future<String?> pickProjectFile() async {
    try {
      // Tenta obter a última pasta usada
      String? initialDirectory = await Preferences.getLastProjectPath();
      
      // Se não tem última pasta, usa o diretório do usuário
      if (initialDirectory == null || !Directory(initialDirectory).existsSync()) {
        final userDocumentsPath = Platform.isWindows
            ? Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? ''
            : Platform.environment['HOME'] ?? '';
        if (userDocumentsPath.isNotEmpty) {
          initialDirectory = userDocumentsPath;
        }
      }

      // Abre diálogo para selecionar arquivo project.json
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Abrir Projeto',
        initialDirectory: initialDirectory,
      );

      if (result == null || result.files.single.path == null) {
        return null;
      }

      final filePath = result.files.single.path!;
      final file = File(filePath);

      // Verifica se o arquivo é project.json
      final fileName = filePath.split(Platform.pathSeparator).last;
      if (fileName != projectFileName) {
        print('⚠️ O arquivo selecionado não é $projectFileName');
        // Ainda assim, retorna o diretório pai
      }

      // Retorna o diretório pai do arquivo
      final projectPath = file.parent.path;

      // Salva o caminho nas preferências
      await Preferences.setLastProjectPath(projectPath);

      return projectPath;
    } catch (e) {
      print('Erro ao selecionar arquivo de projeto: $e');
      return null;
    }
  }
}

