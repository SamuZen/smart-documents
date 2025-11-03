import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  static const String _keyLastProjectPath = 'last_project_path';

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
}

