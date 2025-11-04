import 'dart:io';

/// Serviço para verificar status do Git e obter informações da branch atual
class GitService {
  /// Verifica se o diretório tem um repositório Git configurado
  static Future<bool> hasGitRepository(String? projectPath) async {
    if (projectPath == null) {
      return false;
    }

    try {
      final gitDir = Directory('$projectPath/.git');
      return gitDir.existsSync();
    } catch (e) {
      print('❌ Erro ao verificar repositório Git: $e');
      return false;
    }
  }

  /// Obtém o nome da branch atual do Git
  /// Retorna null se não houver repositório Git ou se houver erro
  static Future<String?> getCurrentBranch(String? projectPath) async {
    if (projectPath == null) {
      return null;
    }

    try {
      // Verifica se há repositório Git
      if (!await hasGitRepository(projectPath)) {
        return null;
      }

      // Executa 'git branch --show-current' para obter a branch atual
      final result = await Process.run(
        'git',
        ['branch', '--show-current'],
        workingDirectory: projectPath,
      );

      if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
        return result.stdout.toString().trim();
      }

      // Se o comando acima não funcionar, tenta 'git rev-parse --abbrev-ref HEAD'
      final result2 = await Process.run(
        'git',
        ['rev-parse', '--abbrev-ref', 'HEAD'],
        workingDirectory: projectPath,
      );

      if (result2.exitCode == 0 && result2.stdout.toString().trim().isNotEmpty) {
        return result2.stdout.toString().trim();
      }

      return null;
    } catch (e) {
      print('❌ Erro ao obter branch do Git: $e');
      return null;
    }
  }
}

