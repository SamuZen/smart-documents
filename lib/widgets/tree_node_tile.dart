import 'package:flutter/material.dart';
import '../models/node.dart';

class TreeNodeTile extends StatefulWidget {
  final Node node;
  final int depth;
  final bool isExpanded;
  final bool hasChildren;
  final bool isSelected;
  final bool isEditing; // Mock: indica se está em modo de edição
  final VoidCallback? onToggle;
  final VoidCallback? onTap;

  const TreeNodeTile({
    super.key,
    required this.node,
    this.depth = 0,
    this.isExpanded = false,
    this.hasChildren = false,
    this.isSelected = false,
    this.isEditing = false,
    this.onToggle,
    this.onTap,
  });

  @override
  State<TreeNodeTile> createState() => _TreeNodeTileState();
}

class _TreeNodeTileState extends State<TreeNodeTile> {
  @override
  Widget build(BuildContext context) {
    final indent = widget.depth * 24.0;

    return InkWell(
        onTap: () {
          // Apenas seleciona o item quando clicar nele (não expande/colapsa)
          widget.onTap?.call();
        },
        child: Container(
          color: widget.isSelected 
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: Row(
            children: [
              SizedBox(width: indent),
              // Ícone de expandir/colapsar (se tiver filhos) - clicável separadamente
              if (widget.hasChildren)
                GestureDetector(
                  onTap: () {
                    // Toggle apenas quando clicar na setinha
                    widget.onToggle?.call();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedRotation(
                    turns: widget.isExpanded ? 0.25 : 0.0,
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
                widget.node.isLeaf ? Icons.insert_drive_file : Icons.folder,
                size: 20,
                color: widget.node.isLeaf
                    ? Colors.blueGrey
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.node.name,
                  style: TextStyle(
                    fontSize: 16,
                    // Mock: muda cor quando está editando
                    color: widget.isEditing
                        ? Colors.red // Cor diferente para indicar modo de edição (mock)
                        : (widget.node.isLeaf ? Colors.grey[700] : Colors.black87),
                    fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}

