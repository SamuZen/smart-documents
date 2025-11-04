import 'package:flutter/material.dart';
import '../services/git_service.dart';
import '../theme/app_theme.dart';

/// Widget que exibe o status do Git no canto da tela
class GitStatusIndicator extends StatefulWidget {
  final String? projectPath;

  const GitStatusIndicator({
    Key? key,
    required this.projectPath,
  }) : super(key: key);

  @override
  State<GitStatusIndicator> createState() => _GitStatusIndicatorState();
}

class _GitStatusIndicatorState extends State<GitStatusIndicator> {
  String? _currentBranch;
  bool _hasGit = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkGitStatus();
  }

  @override
  void didUpdateWidget(GitStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Se o projectPath mudou, verifica novamente
    if (oldWidget.projectPath != widget.projectPath) {
      _checkGitStatus();
    }
  }

  Future<void> _checkGitStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final hasGit = await GitService.hasGitRepository(widget.projectPath);
      String? branch;

      if (hasGit) {
        branch = await GitService.getCurrentBranch(widget.projectPath);
      }

      if (mounted) {
        setState(() {
          _hasGit = hasGit;
          _currentBranch = branch;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erro ao verificar status do Git: $e');
      if (mounted) {
        setState(() {
          _hasGit = false;
          _currentBranch = null;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Não mostra nada se estiver carregando
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    // Se não houver projeto aberto, não mostra nada
    if (widget.projectPath == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          border: Border.all(
            color: _hasGit && _currentBranch != null
                ? AppTheme.neonBlue.withOpacity(0.3)
                : AppTheme.textTertiary.withOpacity(0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _hasGit && _currentBranch != null
                  ? Icons.account_tree
                  : Icons.cancel_outlined,
              size: 14,
              color: _hasGit && _currentBranch != null
                  ? AppTheme.neonBlue
                  : AppTheme.textTertiary,
            ),
            const SizedBox(width: 6),
            Text(
              _hasGit && _currentBranch != null
                  ? _currentBranch!
                  : 'no git',
              style: TextStyle(
                fontSize: 12,
                color: _hasGit && _currentBranch != null
                    ? AppTheme.textPrimary
                    : AppTheme.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

