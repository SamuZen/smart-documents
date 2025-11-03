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
  String? _dockedZone; // Zona onde a janela está dockada (null se não dockada)
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
      // Se estava dockado, remove o dock ao começar a arrastar
      if (_dockedZone != null) {
        // Salva o tamanho atual antes de des-dockar
        final previousWidth = _width;
        final previousHeight = _height;
        _dockedZone = null;
        // Restaura tamanho original se necessário
        _width = previousWidth;
        _height = previousHeight;
      }
      
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

  Offset _applyDock(Offset position, Size screenSize, String dockZone) {
    // Usa o tamanho disponível (MediaQuery já considera AppBar no build)
    final availableSize = _getAvailableSize(screenSize);
    
    switch (dockZone) {
      case 'left':
        return Offset(0, 0);
      case 'right':
        return Offset(availableSize.width - _width, 0);
      case 'top':
        return Offset(0, 0);
      case 'bottom':
        return Offset(0, availableSize.height - _height);
      default:
        return position;
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

  Size _applyDockSize(Size screenSize, String dockZone) {
    // Usa o tamanho disponível (já considera AppBar automaticamente no build)
    final availableSize = _getAvailableSize(screenSize);
    
    switch (dockZone) {
      case 'left':
      case 'right':
        // Para dock lateral, ajusta altura para ocupar toda área disponível
        return Size(_width, availableSize.height);
      case 'top':
      case 'bottom':
        // Para dock vertical, ajusta largura para ocupar toda área disponível
        return Size(availableSize.width, _height);
      default:
        return Size(_width, _height);
    }
  }
  
  void _adjustDockedSize() {
    // Ajusta tamanho e posição se estiver dockado
    if (_dockedZone != null && _screenSize != null) {
      final mediaQuery = MediaQuery.maybeOf(context);
      if (mediaQuery != null) {
        final newScreenSize = mediaQuery.size;
        if (newScreenSize != _screenSize) {
          _screenSize = newScreenSize;
          final dockedPosition = _applyDock(_position, _screenSize!, _dockedZone!);
          final dockedSize = _applyDockSize(_screenSize!, _dockedZone!);
          
          setState(() {
            _position = dockedPosition;
            _width = dockedSize.width;
            _height = dockedSize.height;
          });
        }
      }
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
        
        // IMPORTANTE: Detecta zona de dock ANTES de aplicar qualquer clamp
        // Usa a posição "livre" para detectar se estamos próximos da borda
        _updateDockZone(newPosition, _screenSize!);
        
        // Se estiver em zona de dock, permite movimento mais livre para facilitar
        // Caso contrário, aplica limites suaves
        final clampedPosition = _currentDockZone != null
            ? newPosition // Em zona de dock, permite movimento mais livre
            : Offset(
                newPosition.dx.clamp(0, _screenSize!.width - _width),
                newPosition.dy.clamp(0, _screenSize!.height - _height),
              );
        
        // Um único setState para tudo
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
    // Usa a última zona detectada OU a zona atual (preferência para atual)
    final zoneToDock = _currentDockZone ?? _lastDetectedDockZone;
    
    // Debug: verifica se temos zona e tamanho da tela
    if (_screenSize == null) {
      final mediaQuery = MediaQuery.maybeOf(context);
      if (mediaQuery != null) {
        _screenSize = mediaQuery.size;
      }
    }
    
    if (_screenSize != null && zoneToDock != null) {
      // Marca como dockado
      _dockedZone = zoneToDock;
      
      // Aplica o dock na posição e no tamanho
      final dockedPosition = _applyDock(_position, _screenSize!, zoneToDock);
      final dockedSize = _applyDockSize(_screenSize!, zoneToDock);
      
      // Atualiza posição e tamanho imediatamente
      setState(() {
        _position = dockedPosition;
        _width = dockedSize.width;
        _height = dockedSize.height;
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
      final mediaQuery = MediaQuery.maybeOf(context);
      if (mediaQuery != null) {
        _screenSize = mediaQuery.size;
        final availableSize = _getAvailableSize(_screenSize!);
        
        final deltaX = details.globalPosition.dx - _resizeStartPosition!.dx;
        final deltaY = details.globalPosition.dy - _resizeStartPosition!.dy;
        
        double newWidth = _width;
        double newHeight = _height;
        Offset newPosition = _position;
        
        if (_dockedZone != null) {
          // Quando dockado, só permite redimensionar a dimensão "livre"
          switch (_dockedZone) {
            case 'left':
              // Dock à esquerda: redimensiona largura normalmente (da direita para fora)
              newWidth = (_resizeStartSize!.width + deltaX)
                  .clamp(widget.minWidth, availableSize.width);
              newHeight = availableSize.height;
              newPosition = Offset(0, 0);
              break;
              
            case 'right':
              // Dock à direita: redimensiona largura invertendo delta (da esquerda para dentro)
              newWidth = (_resizeStartSize!.width - deltaX)
                  .clamp(widget.minWidth, availableSize.width);
              newHeight = availableSize.height;
              newPosition = Offset(availableSize.width - newWidth, 0);
              break;
              
            case 'top':
              // Dock no topo: redimensiona altura normalmente (de baixo para fora)
              newWidth = availableSize.width;
              newHeight = (_resizeStartSize!.height + deltaY)
                  .clamp(widget.minHeight, availableSize.height);
              newPosition = Offset(0, 0);
              break;
              
            case 'bottom':
              // Dock inferior: redimensiona altura invertendo delta (de cima para dentro)
              newWidth = availableSize.width;
              newHeight = (_resizeStartSize!.height - deltaY)
                  .clamp(widget.minHeight, availableSize.height);
              newPosition = Offset(0, availableSize.height - newHeight);
              break;
          }
        } else {
          // Quando não dockado, permite redimensionar livremente
          newWidth = (_resizeStartSize!.width + deltaX)
              .clamp(widget.minWidth, double.infinity);
          newHeight = (_resizeStartSize!.height + deltaY)
              .clamp(widget.minHeight, double.infinity);
        }
        
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

  Color _getDockIndicatorColor() {
    if (_currentDockZone == null) return Colors.transparent;
    return Theme.of(context).colorScheme.primary.withOpacity(0.3);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final currentScreenSize = mediaQuery.size;
    
    // Ajusta tamanho se dockado e a tela mudou
    if (_screenSize != null && currentScreenSize != _screenSize) {
      _adjustDockedSize();
    } else {
      _screenSize = currentScreenSize;
    }
    
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

