import 'package:flutter/material.dart';
import 'dart:developer' as developer;
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
  final Function(VoidCallback)? onConfirmEditing; // Recebe uma função que será chamada quando Enter for pressionado
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;

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
    this.onConfirmEditing,
    this.onDragStart,
    this.onDragEnd,
  });

  @override
  State<TreeNodeTile> createState() => _TreeNodeTileState();
}

class _TreeNodeTileState extends State<TreeNodeTile> {
  late TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();

  
  void confirmEditing() {
    final trimmedValue = _textController.text.trim();
    print('📝 [TreeNodeTile] confirmEditing() chamado - valor: "$trimmedValue"');
    print('   onNameChanged existe: ${widget.onNameChanged != null}');
    if (trimmedValue.isNotEmpty && widget.onNameChanged != null) {
      print('✅ [TreeNodeTile] Salvando via confirmEditing: "$trimmedValue"');
      widget.onNameChanged!(trimmedValue);
    } else if (trimmedValue.isEmpty) {
      print('❌ [TreeNodeTile] Valor vazio, cancelando');
      widget.onCancelEditing?.call();
    } else if (widget.onNameChanged == null) {
      print('❌ [TreeNodeTile] onNameChanged é NULL! Não é possível salvar');
    }
  }
  
  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.node.name);
  }

  @override
  void didUpdateWidget(TreeNodeTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Quando entra em modo de edição, foca e seleciona o texto
    if (!oldWidget.isEditing && widget.isEditing) {
      print('🔵 [TreeNodeTile] INICIANDO EDIÇÃO - Node: ${widget.node.id} | Nome: "${widget.node.name}"');
      developer.log('TreeNodeTile: Entrando em modo de edição para node ${widget.node.id} (${widget.node.name})');
      _textController.text = widget.node.name;
      // Usa post frame callback para garantir que o widget está totalmente construído
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
          _textController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _textController.text.length,
          );
          // Registra a função confirmEditing no TreeView para ser chamada quando Enter for pressionado
          if (widget.onConfirmEditing != null) {
            widget.onConfirmEditing!(confirmEditing);
          }
        }
      });
    }
    
    // Quando sai do modo de edição sem salvar, restaura o texto original
    if (oldWidget.isEditing && !widget.isEditing) {
      print('🔴 [TreeNodeTile] CANCELANDO EDIÇÃO - Node: ${widget.node.id} | Nome final: "${widget.node.name}"');
      developer.log('TreeNodeTile: Saindo do modo de edição para node ${widget.node.id} (nome final: ${widget.node.name})');
      _textController.text = widget.node.name;
      _focusNode.unfocus();
    }
    
    // Atualiza o controller quando o nome do node muda (apenas quando não está editando)
    if (oldWidget.node.name != widget.node.name && !widget.isEditing) {
      developer.log('TreeNodeTile: Nome do node ${widget.node.id} mudou de "${oldWidget.node.name}" para "${widget.node.name}"');
      _textController.text = widget.node.name;
    }
  }


  void _handleSubmitted(String value) {
    final trimmedValue = value.trim();
    print('🟢 [TreeNodeTile] SUBMETENDO EDIÇÃO - Node: ${widget.node.id}');
    print('   Valor digitado: "$value"');
    print('   Valor trimmed: "$trimmedValue"');
    print('   Nome atual: "${widget.node.name}"');
    print('   trimmedValue.isEmpty: ${trimmedValue.isEmpty}');
    print('   trimmedValue != widget.node.name: ${trimmedValue != widget.node.name}');
    print('   onNameChanged existe: ${widget.onNameChanged != null}');
    developer.log('TreeNodeTile: _handleSubmitted chamado para node ${widget.node.id}. Valor: "$value", Trimmed: "$trimmedValue", Nome atual: "${widget.node.name}", onNameChanged: ${widget.onNameChanged != null}');
    
    if (trimmedValue.isEmpty) {
      print('❌ [TreeNodeTile] Valor vazio, cancelando edição');
      developer.log('TreeNodeTile: Valor vazio, cancelando edição');
      widget.onCancelEditing?.call();
      return;
    }
    
    if (trimmedValue == widget.node.name) {
      print('⚠️ [TreeNodeTile] Valor igual ao nome atual, mas salvando mesmo assim');
      developer.log('TreeNodeTile: Valor igual ao nome atual, mas salvando mesmo assim');
    }
    
    // Sempre tenta salvar se o callback existe, mesmo que seja igual (pode ter mudanças de formatação)
    if (widget.onNameChanged != null) {
      print('✅ [TreeNodeTile] CHAMANDO onNameChanged com "$trimmedValue"');
      developer.log('TreeNodeTile: Chamando onNameChanged com "$trimmedValue"');
      widget.onNameChanged!(trimmedValue);
    } else {
      print('❌ [TreeNodeTile] onNameChanged é NULL! Cancelando edição');
      developer.log('TreeNodeTile: onNameChanged é NULL, cancelando edição');
      widget.onCancelEditing?.call();
    }
  }


  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Widget _buildTileContent() {
    final indent = widget.depth * 24.0;
    
    return Container(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final tileContent = InkWell(
      onTap: () {
        // Apenas seleciona o item quando clicar nele (não expande/colapsa)
        widget.onTap?.call();
      },
      child: _buildTileContent(),
    );

    // Se estiver em modo de edição, não permite drag
    if (widget.isEditing) {
      return tileContent;
    }

    // Permite drag apenas quando não está editando
    return LongPressDraggable<String>(
      data: widget.node.id,
      delay: const Duration(milliseconds: 200),
      onDragStarted: () {
        widget.onDragStart?.call();
      },
      onDragEnd: (_) {
        widget.onDragEnd?.call();
      },
      feedback: Material(
        elevation: 6,
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.8,
          child: Container(
            width: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: _buildTileContent(),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: tileContent,
      ),
      child: tileContent,
    );
  }
}

