import 'package:flutter/material.dart';
import '../services/checkpoint_manager.dart';

/// Dialog para visualizar e restaurar checkpoints
class CheckpointDialog extends StatelessWidget {
  final CheckpointManager checkpointManager;
  final Function(String checkpointId) onRestoreCheckpoint;
  final Function(String checkpointId) onDeleteCheckpoint;

  const CheckpointDialog({
    super.key,
    required this.checkpointManager,
    required this.onRestoreCheckpoint,
    required this.onDeleteCheckpoint,
  });

  @override
  Widget build(BuildContext context) {
    final checkpoints = checkpointManager.getAllCheckpoints();

    return AlertDialog(
      title: const Text('Checkpoints Disponíveis'),
      content: SizedBox(
        width: 500,
        child: checkpoints.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'Nenhum checkpoint disponível.\n\nCrie um checkpoint usando "Criar Checkpoint..." no menu Editar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: checkpoints.length,
                itemBuilder: (context, index) {
                  final checkpoint = checkpoints[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    child: ListTile(
                      title: Text(
                        checkpoint.name ?? 'Checkpoint sem nome',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Criado: ${_formatDateTime(checkpoint.timestamp)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (checkpoint.metadata.isNotEmpty)
                            Text(
                              'Metadados: ${checkpoint.metadata.length} item(s)',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.restore, color: Colors.blue),
                            tooltip: 'Restaurar checkpoint',
                            onPressed: () {
                              Navigator.of(context).pop();
                              onRestoreCheckpoint(checkpoint.id);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Deletar checkpoint',
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('Confirmar exclusão'),
                                  content: Text(
                                    'Tem certeza que deseja deletar o checkpoint "${checkpoint.name ?? 'sem nome'}"?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(dialogContext).pop(false),
                                      child: const Text('Cancelar'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.of(dialogContext).pop(true),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      child: const Text('Deletar'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed == true) {
                                Navigator.of(context).pop();
                                onDeleteCheckpoint(checkpoint.id);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Agora mesmo';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minuto(s) atrás';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hora(s) atrás';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dia(s) atrás';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}

