import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DraggableResizableWindow extends StatefulWidget {
  final Widget child;
  final String title;
  final double initialWidth;
  final double initialHeight;
  final double minWidth;
  final double minHeight;
  final Offset? initialPosition; // Posição inicial customizada
  final VoidCallback? onClose;
  final VoidCallback? onTap; // Callback quando a janela é clicada (para retornar foco)

  const DraggableResizableWindow({
    super.key,
    required this.child,
    required this.title,
    this.initialWidth = 300,
    this.initialHeight = 400,
    this.minWidth = 200,
    this.minHeight = 200,
    this.initialPosition,
    this.onClose,
    this.onTap,
  });

  @override
  State<DraggableResizableWindow> createState() =>
      _DraggableResizableWindowState();
}

class _DraggableResizableWindowState extends State<DraggableResizableWindow>
    with SingleTickerProviderStateMixin {
  late double _width;
  late double _height;
  late Offset _position;
  bool _isDragging = false;
  bool _isResizing = false;
  Offset? _resizeStartPosition;
  Size? _resizeStartSize;
  
  // Sistema de docking desativado
  Size? _screenSize;

  @override
  void initState() {
    super.initState();
    _width = widget.initialWidth;
    _height = widget.initialHeight;
    // Usa posição inicial customizada se fornecida, senão usa posição padrão
    _position = widget.initialPosition ?? const Offset(100, 100);
  }

  void _onDragStart(DragStartDetails details) {
    if (!_isResizing) {
      setState(() {
        _isDragging = true;
      });
    }
  }

  Size _getAvailableSize(Size screenSize) {
    // Obtém o tamanho disponível no body (considerando AppBar)
    // Como estamos dentro do body do Scaffold, o Positioned(0,0) já começa abaixo do AppBar
    // Então precisamos calcular o tamanho disponível considerando o AppBar
    final mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery != null) {
      final size = mediaQuery.size;
      final padding = mediaQuery.padding;
      
      // O AppBar padrão tem altura baseada no tema
      // Usamos a constante padrão do Material Design (56px)
      // Ou podemos usar AppBar.toolbarHeight se disponível
      final toolbarHeight = mediaQuery.orientation == Orientation.portrait ? 56.0 : 48.0;
      final appBarHeight = toolbarHeight + padding.top;
      
      // O tamanho disponível no body é:
      // - Largura: largura total menos padding horizontal
      // - Altura: altura total menos AppBar completo (toolbar + status bar) menos padding bottom
      final availableWidth = size.width - padding.left - padding.right;
      final availableHeight = size.height - appBarHeight - padding.bottom;
      
      return Size(availableWidth, availableHeight);
    }
    return screenSize;
  }


  void _onDragUpdate(DragUpdateDetails details) {
    if (_isDragging && !_isResizing) {
      // Calcula nova posição livremente (sempre permite movimento)
      final newPosition = Offset(
        _position.dx + details.delta.dx,
        _position.dy + details.delta.dy,
      );
      
      // Obtém tamanho da tela do contexto
      final mediaQuery = MediaQuery.maybeOf(context);
      if (mediaQuery != null) {
        _screenSize = mediaQuery.size;
        final availableSize = _getAvailableSize(_screenSize!);
        
        // Sistema de docking desativado - sempre aplica limites normais
        final clampedPosition = Offset(
          newPosition.dx.clamp(0, availableSize.width - _width),
          newPosition.dy.clamp(0, availableSize.height - _height),
        );
        
        setState(() {
          _position = clampedPosition;
        });
      } else {
        setState(() {
          _position = newPosition;
        });
      }
    }
  }

  void _finishDrag() {
    // Sistema de docking desativado - apenas finaliza o drag
      setState(() {
        _isDragging = false;
      });
  }

  void _onDragEnd(DragEndDetails details) {
    _finishDrag();
  }

  void _onDragCancel() {
    _finishDrag();
  }

  void _onResizeStart(DragStartDetails details) {
    setState(() {
      _isResizing = true;
      _isDragging = false;
      _resizeStartSize = Size(_width, _height);
      _resizeStartPosition = details.globalPosition;
    });
  }

  void _onResizeUpdate(DragUpdateDetails details) {
    if (_isResizing && _resizeStartSize != null && _resizeStartPosition != null) {
      final mediaQuery = MediaQuery.maybeOf(context);
      if (mediaQuery != null) {
        _screenSize = mediaQuery.size;
        
        final deltaX = details.globalPosition.dx - _resizeStartPosition!.dx;
        final deltaY = details.globalPosition.dy - _resizeStartPosition!.dy;
        
        // Sistema de docking desativado - sempre permite redimensionar livremente
        final newWidth = (_resizeStartSize!.width + deltaX)
            .clamp(widget.minWidth, double.infinity);
        final newHeight = (_resizeStartSize!.height + deltaY)
            .clamp(widget.minHeight, double.infinity);
        final newPosition = _position;
        
        setState(() {
          _width = newWidth;
          _height = newHeight;
          _position = newPosition;
        });
      } else {
        // Fallback se não tiver MediaQuery
        setState(() {
          final deltaX = details.globalPosition.dx - _resizeStartPosition!.dx;
          final deltaY = details.globalPosition.dy - _resizeStartPosition!.dy;
          
          _width = (_resizeStartSize!.width + deltaX)
              .clamp(widget.minWidth, double.infinity);
          _height = (_resizeStartSize!.height + deltaY)
              .clamp(widget.minHeight, double.infinity);
        });
      }
    }
  }

  void _onResizeEnd(DragEndDetails details) {
    setState(() {
      _isResizing = false;
      _resizeStartSize = null;
      _resizeStartPosition = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final currentScreenSize = mediaQuery.size;
    
    // Sistema de docking desativado - apenas atualiza tamanho da tela
    _screenSize = currentScreenSize;
    
    return Stack(
      children: [
        // Janela principal - SEMPRE PRIMEIRA para ter prioridade nos eventos
        Positioned(
          left: _position.dx,
          top: _position.dy,
          child: GestureDetector(
            // Captura cliques na janela (mas não interfere com o conteúdo)
            onTap: () {
              // Se não está arrastando nem redimensionando, retorna o foco
              if (!_isDragging && !_isResizing && widget.onTap != null) {
                print('🖱️ [DraggableResizableWindow] Janela "${widget.title}" clicada, retornando foco');
                widget.onTap!();
              }
            },
            behavior: HitTestBehavior.translucent,
            child: Container(
              width: _width,
              height: _height,
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated, // Mais claro para destacar janelas
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.borderNeutral, // Sistema de docking desativado
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Stack(
          children: [
            Column(
              children: [
                // Barra de título arrastável
                GestureDetector(
                  onPanStart: _onDragStart,
                  onPanUpdate: _onDragUpdate,
                  onPanEnd: _onDragEnd,
                  onPanCancel: _onDragCancel, // Garante que sempre chama quando cancela
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceNeutral, // Diferente da janela
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: AppTheme.borderNeutral,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: widget.onClose,
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
                // Conteúdo
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    child: Container(
                      color: AppTheme.surfaceElevated, // Mantém consistência
                      child: widget.child,
                    ),
                  ),
                ),
              ],
            ),
            // Área de redimensionamento (canto inferior direito)
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onPanStart: _onResizeStart,
                onPanUpdate: _onResizeUpdate,
                onPanEnd: _onResizeEnd,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 30,
                  height: 30,
                  color: Colors.transparent,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeDownRight,
                    child: Container(
                      margin: const EdgeInsets.only(right: 0, bottom: 0),
                      decoration: BoxDecoration(
                        color: AppTheme.borderNeutral.withOpacity(0.3),
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Icon(
                        Icons.drag_handle,
                        size: 18,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              ),
            ],
          ),
            ),
          ),
        ),
        // Sistema de docking desativado - indicador visual removido
      ],
    );
  }
}

