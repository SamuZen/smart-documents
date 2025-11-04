import 'package:flutter/material.dart';
import '../models/node.dart';
import '../theme/app_theme.dart';

class PromptComposerTreeNodeTile extends StatelessWidget {
  final Node node;
  final int depth;
  final bool isExpanded;
  final bool hasChildren;
  final bool isSelected;
  final VoidCallback? onToggle;
  final Function(bool?)? onCheckboxChanged;

  const PromptComposerTreeNodeTile({
    super.key,
    required this.node,
    this.depth = 0,
    this.isExpanded = false,
    this.hasChildren = false,
    this.isSelected = false,
    this.onToggle,
    this.onCheckboxChanged,
  });

  @override
  Widget build(BuildContext context) {
    final indent = depth * 24.0;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.neonBlue.withOpacity(0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: isSelected
            ? Border.all(
                color: AppTheme.neonBlue.withOpacity(0.25),
                width: 1,
              )
            : null,
      ),
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(width: indent),
          // Ícone de expandir/colapsar (se tiver filhos)
          if (hasChildren)
            GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: AnimatedRotation(
                turns: isExpanded ? 0.25 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppTheme.neonBlue,
                ),
              ),
            )
          else
            const SizedBox(width: 20),
          // Checkbox
          Checkbox(
            value: isSelected,
            onChanged: onCheckboxChanged,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 8),
          // Ícone do tipo de node
          Icon(
            node.isLeaf ? Icons.insert_drive_file : Icons.folder,
            size: 20,
            color: node.isLeaf
                ? AppTheme.textSecondary
                : AppTheme.neonBlue,
          ),
          const SizedBox(width: 8),
          // Nome do node
          Expanded(
            child: Text(
              node.name,
              style: TextStyle(
                fontSize: 16,
                color: node.isLeaf
                    ? AppTheme.textSecondary
                    : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

