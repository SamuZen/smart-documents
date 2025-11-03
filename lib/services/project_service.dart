import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import '../models/node.dart';
import '../utils/preferences.dart';

class ProjectService {
  static const String projectFileName = 'project.json';

  /// Seleciona a pasta pai onde será criada a pasta do projeto
  /// Retorna o caminho da pasta selecionada, ou null se cancelado
  static Future<String?> selectParentFolder() async {
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

      // Abre diálogo para selecionar pasta pai
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Selecione onde criar a pasta do projeto',
        initialDirectory: initialDirectory,
      );

      if (selectedDirectory == null) {
        return null;
      }

      return selectedDirectory;
    } catch (e) {
      print('Erro ao selecionar pasta pai: $e');
      return null;
    }
  }

  /// Cria uma pasta de projeto com o nome especificado dentro da pasta pai
  /// Retorna o caminho completo da pasta criada, ou null se houve erro
  static Future<String?> createProjectFolder(String projectName, String parentFolder) async {
    try {
      // Sanitiza o nome do projeto (remove caracteres inválidos para nome de pasta)
      final sanitizedName = _sanitizeFolderName(projectName);
      
      if (sanitizedName.isEmpty) {
        print('❌ Nome do projeto inválido após sanitização');
        return null;
      }

      // Cria o caminho completo da pasta do projeto
      final projectFolderPath = '${parentFolder}${Platform.pathSeparator}$sanitizedName';
      final projectFolder = Directory(projectFolderPath);

      // Verifica se a pasta já existe
      if (projectFolder.existsSync()) {
        print('⚠️ A pasta "$sanitizedName" já existe em: $parentFolder');
        return null; // Ou podemos retornar o caminho mesmo assim, dependendo do comportamento desejado
      }

      // Cria a pasta do projeto
      await projectFolder.create(recursive: true);

      // Salva o caminho nas preferências
      await Preferences.setLastProjectPath(projectFolderPath);

      print('✅ Pasta do projeto criada: $projectFolderPath');
      return projectFolderPath;
    } catch (e) {
      print('❌ Erro ao criar pasta do projeto: $e');
      return null;
    }
  }

  /// Remove caracteres inválidos do nome para usar como nome de pasta
  static String _sanitizeFolderName(String name) {
    // Remove caracteres inválidos para nome de pasta
    final invalidChars = Platform.isWindows
        ? RegExp(r'[<>:"/\\|?*]')
        : RegExp(r'[/\\]');
    
    // Remove caracteres inválidos e trim
    var sanitized = name.replaceAll(invalidChars, '_').trim();
    
    // Remove espaços no início e fim, e substitui espaços múltiplos por um único espaço
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');
    
    // Remove pontos finais (podem causar problemas no Windows)
    if (Platform.isWindows) {
      sanitized = sanitized.replaceAll(RegExp(r'\.$'), '');
    }
    
    return sanitized;
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

  /// Abre diálogo para selecionar a pasta do projeto
  /// Retorna o caminho da pasta do projeto, ou null se cancelado
  static Future<String?> pickProjectFolder() async {
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

      // Abre diálogo para selecionar pasta do projeto
      String? selectedFolder = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Abrir Projeto - Selecione a pasta do projeto',
        initialDirectory: initialDirectory,
      );

      if (selectedFolder == null) {
        return null;
      }

      // Verifica se o arquivo project.json existe na pasta selecionada
      final projectFile = File('$selectedFolder/$projectFileName');
      if (!projectFile.existsSync()) {
        print('⚠️ Arquivo $projectFileName não encontrado na pasta selecionada: $selectedFolder');
        // Retorna null - o main.dart mostrará uma mensagem de erro ao usuário
        return null;
      }

      // Salva o caminho nas preferências
      await Preferences.setLastProjectPath(selectedFolder);

      return selectedFolder;
    } catch (e) {
      print('Erro ao selecionar pasta de projeto: $e');
      return null;
    }
  }
}

