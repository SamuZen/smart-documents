import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RecentProject {
  final String path;
  final String name;

  RecentProject({
    required this.path,
    required this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'name': name,
    };
  }

  factory RecentProject.fromJson(Map<String, dynamic> json) {
    return RecentProject(
      path: json['path'] as String,
      name: json['name'] as String,
    );
  }
}

class Preferences {
  static const String _keyLastProjectPath = 'last_project_path';
  static const String _keyRecentProjects = 'recent_projects';
  static const int _maxRecentProjects = 10;

  /// Lê a última pasta de projeto usada
  static Future<String?> getLastProjectPath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyLastProjectPath);
    } catch (e) {
      print('Erro ao ler última pasta de projeto: $e');
      return null;
    }
  }

  /// Salva a última pasta de projeto usada
  static Future<void> setLastProjectPath(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastProjectPath, path);
    } catch (e) {
      print('Erro ao salvar última pasta de projeto: $e');
    }
  }

  /// Lê a lista de projetos recentes
  static Future<List<RecentProject>> getRecentProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyRecentProjects);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => RecentProject.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erro ao ler projetos recentes: $e');
      return [];
    }
  }

  /// Adiciona um projeto à lista de projetos recentes
  /// Remove duplicatas e mantém apenas os últimos _maxRecentProjects
  static Future<void> addRecentProject(String path, String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentProjects = await getRecentProjects();

      // Remove o projeto se já existe (para movê-lo para o topo)
      recentProjects.removeWhere((project) => project.path == path);

      // Adiciona o novo projeto no início
      recentProjects.insert(0, RecentProject(path: path, name: name));

      // Limita ao número máximo de projetos
      if (recentProjects.length > _maxRecentProjects) {
        recentProjects.removeRange(_maxRecentProjects, recentProjects.length);
      }

      // Salva a lista atualizada
      final jsonList = recentProjects.map((project) => project.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_keyRecentProjects, jsonString);
    } catch (e) {
      print('Erro ao adicionar projeto recente: $e');
    }
  }

  /// Remove um projeto da lista de projetos recentes
  static Future<void> removeRecentProject(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentProjects = await getRecentProjects();

      recentProjects.removeWhere((project) => project.path == path);

      final jsonList = recentProjects.map((project) => project.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_keyRecentProjects, jsonString);
    } catch (e) {
      print('Erro ao remover projeto recente: $e');
    }
  }
}

