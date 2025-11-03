import 'package:flutter/material.dart';

class DraggableResizableWindow extends StatefulWidget {
  final Widget child;
  final String title;
  final double initialWidth;
  final double initialHeight;
  final double minWidth;
  final double minHeight;
  final VoidCallback? onClose;

  const DraggableResizableWindow({
    super.key,
    required this.child,
    required this.title,
    this.initialWidth = 300,
    this.initialHeight = 400,
    this.minWidth = 200,
    this.minHeight = 200,
    this.onClose,
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
  
  // Sistema de docking
  static const double _dockThreshold = 80.0; // Distância para ativar dock (aumentado)
  String? _currentDockZone; // 'left', 'right', 'top', 'bottom', null
  String? _lastDetectedDockZone; // Última zona detectada durante o drag
  Size? _screenSize;

  @override
  void initState() {
    super.initState();
    _width = widget.initialWidth;
    _height = widget.initialHeight;
    _position = const Offset(100, 100);
  }

  void _onDragStart(DragStartDetails details) {
    if (!_isResizing) {
      setState(() {
        _isDragging = true;
        _currentDockZone = null;
        _lastDetectedDockZone = null;
      });
    }
  }

  void _updateDockZone(Offset position, Size screenSize) {
    String? newZone;
    
    // Detecta zona de docking baseado na posição
    final leftDistance = position.dx;
    final rightDistance = screenSize.width - position.dx - _width;
    final topDistance = position.dy;
    final bottomDistance = screenSize.height - position.dy - _height;
    
    // Verifica qual borda está mais próxima
    if (leftDistance < _dockThreshold && (leftDistance < rightDistance || rightDistance >= _dockThreshold)) {
      newZone = 'left';
    } else if (rightDistance < _dockThreshold) {
      newZone = 'right';
    } else if (topDistance < _dockThreshold && (topDistance < bottomDistance || bottomDistance >= _dockThreshold)) {
      newZone = 'top';
    } else if (bottomDistance < _dockThreshold) {
      newZone = 'bottom';
    } else {
      newZone = null;
    }
    
    // Mantém a última zona detectada
    if (newZone != null) {
      _lastDetectedDockZone = newZone;
    }
    
    // Atualiza apenas se mudou (sem setState separado)
    _currentDockZone = newZone;
  }

  Offset _applyDock(Offset position, Size screenSize) {
    if (_currentDockZone == null) return position;
    
    switch (_currentDockZone) {
      case 'left':
        return Offset(0, position.dy);
      case 'right':
        return Offset(screenSize.width - _width, position.dy);
      case 'top':
        return Offset(position.dx, 0);
      case 'bottom':
        return Offset(position.dx, screenSize.height - _height);
      default:
        return position;
    }
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
        
        // Aplica limites suaves (permite pequeno overflow para facilitar dock)
        // Mas garante que não saia completamente da tela
        final minX = -_width * 0.2; // Permite 20% de overflow
        final maxX = _screenSize!.width - _width * 0.8;
        final minY = -_height * 0.2;
        final maxY = _screenSize!.height - _height * 0.8;
        
        final clampedPosition = Offset(
          newPosition.dx.clamp(minX, maxX),
          newPosition.dy.clamp(minY, maxY),
        );
        
        // Atualiza zona de dock ANTES do setState (sem setState separado)
        final oldZone = _currentDockZone;
        _updateDockZone(clampedPosition, _screenSize!);
        final zoneChanged = oldZone != _currentDockZone;
        
        // Um único setState para tudo
        setState(() {
          _position = clampedPosition;
          // Força rebuild se a zona mudou (para mostrar/esconder indicador)
          if (zoneChanged) {
            // Já atualizado em _updateDockZone
          }
        });
      } else {
        setState(() {
          _position = newPosition;
        });
      }
    }
  }

  void _finishDrag() {
    // Usa a última zona detectada OU a zona atual
    final zoneToDock = _currentDockZone ?? _lastDetectedDockZone;
    
    if (_screenSize != null && zoneToDock != null) {
      // Temporariamente define a zona para calcular o dock corretamente
      _currentDockZone = zoneToDock;
      
      // Aplica o dock imediatamente
      final dockedPosition = _applyDock(_position, _screenSize!);
      
      // Atualiza posição imediatamente
      setState(() {
        _position = dockedPosition;
        _isDragging = false;
        _currentDockZone = null;
        _lastDetectedDockZone = null;
      });
    } else {
      setState(() {
        _isDragging = false;
        _currentDockZone = null;
        _lastDetectedDockZone = null;
      });
    }
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

  void _onResizeEnd(DragEndDetails details) {
    setState(() {
      _isResizing = false;
      _resizeStartSize = null;
      _resizeStartPosition = null;
    });
  }

  Color _getDockIndicatorColor() {
    if (_currentDockZone == null) return Colors.transparent;
    return Theme.of(context).colorScheme.primary.withOpacity(0.3);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    _screenSize ??= mediaQuery.size;
    
    return Stack(
      children: [
        // Janela principal - SEMPRE PRIMEIRA para ter prioridade nos eventos
        Positioned(
          left: _position.dx,
          top: _position.dy,
          child: Container(
            width: _width,
            height: _height,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(
                color: _currentDockZone != null
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor,
                width: _currentDockZone != null ? 2 : 1,
              ),
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
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: widget.onClose,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          iconSize: 20,
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
                    child: widget.child,
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
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Icon(
                        Icons.drag_handle,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurface,
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
        // Indicador visual de zona de dock - DEPOIS da janela para não interferir
        if (_currentDockZone != null && _screenSize != null)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: Stack(
                children: [
                  Positioned(
                    left: _currentDockZone == 'left' ? 0 : null,
                    right: _currentDockZone == 'right' ? 0 : null,
                    top: _currentDockZone == 'top' ? 0 : null,
                    bottom: _currentDockZone == 'bottom' ? 0 : null,
                    width: _currentDockZone == 'left' || _currentDockZone == 'right'
                        ? _width
                        : _screenSize!.width,
                    height: _currentDockZone == 'top' || _currentDockZone == 'bottom'
                        ? _height
                        : _screenSize!.height,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getDockIndicatorColor(),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

