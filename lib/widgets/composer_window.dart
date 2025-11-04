import 'package:flutter/material.dart';
import '../models/node.dart';
import '../theme/app_theme.dart';

/// Janela Composer que exibe informações detalhadas do node selecionado
class ComposerWindow extends StatelessWidget {
  final Node? selectedNode;

  const ComposerWindow({
    Key? key,
    required this.selectedNode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (selectedNode == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum node selecionado',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: AppTheme.surfaceDark,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho com nome e ID
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.neonBlue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.description,
                        size: 20,
                        color: AppTheme.neonBlue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selectedNode!.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.tag,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'ID: ${selectedNode!.id}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Informações dos campos
            if (selectedNode!.fields.isNotEmpty) ...[
              Text(
                'Campos',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ...selectedNode!.fields.entries.map((entry) {
                return _buildFieldCard(entry.key, entry.value);
              }),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariantDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.borderNeutral,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppTheme.textTertiary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Nenhum campo adicionado',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Informações sobre filhos
            Row(
              children: [
                Icon(
                  Icons.account_tree,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Filhos: ${selectedNode!.children.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldCard(String key, dynamic value) {
    final valueType = _getValueType(value);
    final displayValue = _formatValue(value, valueType);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariantDark,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppTheme.borderNeutral,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getIconForType(valueType),
                size: 16,
                color: _getIconColorForType(valueType),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  key,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getTypeColor(valueType).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _getTypeColor(valueType).withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  valueType,
                  style: TextStyle(
                    fontSize: 10,
                    color: _getTypeColor(valueType),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.backgroundDark,
              borderRadius: BorderRadius.circular(4),
            ),
            child: SelectableText(
              displayValue,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getValueType(dynamic value) {
    if (value == null) return 'null';
    if (value is bool) return 'boolean';
    if (value is int) return 'number';
    if (value is double) return 'number';
    if (value is String) {
      // Verifica se é um caminho de imagem
      if (value.toString().contains('assets/images/') || 
          value.toString().contains('.png') ||
          value.toString().contains('.jpg') ||
          value.toString().contains('.jpeg') ||
          value.toString().contains('.gif')) {
        return 'image';
      }
      // Verifica se é um texto longo
      if (value.toString().length > 100) {
        return 'text';
      }
      return 'string';
    }
    if (value is List) return 'array';
    if (value is Map) return 'object';
    return 'unknown';
  }

  String _formatValue(dynamic value, String type) {
    if (value == null) return 'null';
    if (type == 'boolean') return value.toString();
    if (type == 'number') return value.toString();
    if (type == 'string' || type == 'text') {
      final str = value.toString();
      if (str.length > 200) {
        return '${str.substring(0, 200)}...';
      }
      return str;
    }
    if (type == 'image') return value.toString();
    if (type == 'array') return '[${(value as List).length} itens]';
    if (type == 'object') return '{${(value as Map).length} chaves}';
    return value.toString();
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'boolean':
        return Icons.toggle_on;
      case 'number':
        return Icons.numbers;
      case 'string':
        return Icons.text_fields;
      case 'text':
        return Icons.article;
      case 'image':
        return Icons.image;
      case 'array':
        return Icons.list;
      case 'object':
        return Icons.data_object;
      default:
        return Icons.help_outline;
    }
  }

  Color _getIconColorForType(String type) {
    switch (type) {
      case 'boolean':
        return AppTheme.neonBlue;
      case 'number':
        return AppTheme.neonCyan;
      case 'string':
        return AppTheme.textPrimary;
      case 'text':
        return AppTheme.neonCyan;
      case 'image':
        return AppTheme.neonBlue;
      case 'array':
        return AppTheme.neonPurple;
      case 'object':
        return AppTheme.neonIndigo;
      default:
        return AppTheme.textTertiary;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'boolean':
        return AppTheme.neonBlue;
      case 'number':
        return AppTheme.neonCyan;
      case 'string':
        return AppTheme.textPrimary;
      case 'text':
        return AppTheme.neonCyan;
      case 'image':
        return AppTheme.neonBlue;
      case 'array':
        return AppTheme.neonPurple;
      case 'object':
        return AppTheme.neonIndigo;
      default:
        return AppTheme.textTertiary;
    }
  }
}

