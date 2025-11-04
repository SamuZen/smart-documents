import 'package:flutter/material.dart';
import '../utils/preferences.dart';
import '../theme/app_theme.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback? onNewProject;
  final VoidCallback? onOpenProject;
  final Function(String projectPath)? onOpenRecentProject;

  const WelcomeScreen({
    super.key,
    this.onNewProject,
    this.onOpenProject,
    this.onOpenRecentProject,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  List<RecentProject> _recentProjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentProjects();
  }

  // Método público para recarregar a lista (pode ser chamado pelo parent)
  void reloadRecentProjects() {
    _loadRecentProjects();
  }

  Future<void> _loadRecentProjects() async {
    setState(() {
      _isLoading = true;
    });

    final projects = await Preferences.getRecentProjects();
    
    setState(() {
      _recentProjects = projects;
      _isLoading = false;
    });
  }

  Future<void> _removeProject(RecentProject project) async {
    await Preferences.removeRecentProject(project.path);
    await _loadRecentProjects();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.neonBlue.withOpacity(0.3),
                    AppTheme.neonCyan.withOpacity(0.2),
                  ],
                ),
                boxShadow: AppTheme.neonGlowBlue,
              ),
              child: Icon(
                Icons.description,
                size: 64,
                color: AppTheme.neonBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Smart Document',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neonBlue,
                    letterSpacing: 1.0,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gerencie seus projetos de documentos hierárquicos',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: widget.onNewProject,
                  icon: const Icon(Icons.add),
                  label: const Text('Novo Projeto'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: widget.onOpenProject,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Abrir Projeto'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
            if (_recentProjects.isNotEmpty) ...[
              const SizedBox(height: 48),
              Divider(),
              const SizedBox(height: 16),
              Text(
                'Projetos Recentes',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ..._recentProjects.map((project) => _buildRecentProjectCard(project)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentProjectCard(RecentProject project) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: const Icon(Icons.folder, size: 32),
        title: Text(
          project.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          project.path,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _removeProject(project),
          tooltip: 'Remover da lista',
        ),
        onTap: () {
          if (widget.onOpenRecentProject != null) {
            widget.onOpenRecentProject!(project.path);
          }
        },
      ),
    );
  }
}

