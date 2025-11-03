import 'package:flutter/material.dart';
import '../models/node.dart';

class TreeNodeTile extends StatelessWidget {
  final Node node;
  final int depth;
  final bool isExpanded;
  final bool hasChildren;
  final bool isSelected;
  final VoidCallback? onToggle;
  final VoidCallback? onTap;

  const TreeNodeTile({
    super.key,
    required this.node,
    this.depth = 0,
    this.isExpanded = false,
    this.hasChildren = false,
    this.isSelected = false,
    this.onToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final indent = depth * 24.0;

    return InkWell(
      onTap: () {
        // Se tem filhos, toggle expande/colapsa
        // Senão, ou além disso, seleciona o item
        if (hasChildren && onToggle != null) {
          onToggle?.call();
        }
        // Sempre seleciona o item quando clicar
        onTap?.call();
      },
      child: Container(
        color: isSelected 
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Row(
          children: [
            SizedBox(width: indent),
            // Ícone de expandir/colapsar (se tiver filhos) - clicável separadamente
            if (hasChildren)
              GestureDetector(
                onTap: () {
                  // Toggle apenas quando clicar na setinha
                  onToggle?.call();
                },
                child: AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                ),
              )
            else
              const SizedBox(width: 20),
            Icon(
              node.isLeaf ? Icons.insert_drive_file : Icons.folder,
              size: 20,
              color: node.isLeaf
                  ? Colors.blueGrey
                  : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                node.name,
                style: TextStyle(
                  fontSize: 16,
                  color: node.isLeaf ? Colors.grey[700] : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

