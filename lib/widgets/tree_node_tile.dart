import 'package:flutter/material.dart';
import '../models/node.dart';

class TreeNodeTile extends StatefulWidget {
  final Node node;
  final int depth;
  final bool isExpanded;
  final bool hasChildren;
  final bool isSelected;
  final bool isEditing;
  final VoidCallback? onToggle;
  final VoidCallback? onTap;
  final Function(String)? onNameChanged;
  final VoidCallback? onCancelEditing;

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
    this.onNameChanged,
    this.onCancelEditing,
  });

  @override
  State<TreeNodeTile> createState() => _TreeNodeTileState();
}

class _TreeNodeTileState extends State<TreeNodeTile> {
  late TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.node.name);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(TreeNodeTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Atualiza o controller quando o nome do node muda
    if (oldWidget.node.name != widget.node.name) {
      _textController.text = widget.node.name;
    }
    
    // Quando entra em modo de edição, foca e seleciona o texto
    if (!oldWidget.isEditing && widget.isEditing) {
      _textController.text = widget.node.name;
      _focusNode.requestFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _textController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _textController.text.length,
        );
      });
    }
    
    // Quando sai do modo de edição sem salvar, restaura o texto original
    if (oldWidget.isEditing && !widget.isEditing) {
      _textController.text = widget.node.name;
      _focusNode.unfocus();
    }
  }

  void _onFocusChanged() {
    // Se perder o foco durante edição e ainda está editando, cancela
    if (!_focusNode.hasFocus && widget.isEditing) {
      _textController.text = widget.node.name;
      widget.onCancelEditing?.call();
    }
  }

  void _handleSubmitted(String value) {
    final trimmedValue = value.trim();
    if (trimmedValue.isNotEmpty && trimmedValue != widget.node.name) {
      widget.onNameChanged?.call(trimmedValue);
    } else {
      widget.onCancelEditing?.call();
    }
  }


  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

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
                child: widget.isEditing
                    ? TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                          ),
                        ),
                        onSubmitted: _handleSubmitted,
                        textInputAction: TextInputAction.done,
                      )
                    : Text(
                        widget.node.name,
                        style: TextStyle(
                          fontSize: 16,
                          color: widget.node.isLeaf ? Colors.grey[700] : Colors.black87,
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

