import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DraggableResizableWindow extends StatefulWidget {
  final Widget child;
  final String title;
  final double initialWidth;
  final double initialHeight;
  final double minWidth;
  final double minHeight;
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
  
  // Sistema de docking
  static const double _dockThreshold = 30.0; // Distância para ativar dock (reduzido)
  static const double _undockThreshold = 30.0; // Distância mínima para sair do dock (reduzido para facilitar)
  String? _currentDockZone; // 'left', 'right', 'top', 'bottom', null
  String? _lastDetectedDockZone; // Última zona detectada durante o drag
  String? _dockedZone; // Zona onde a janela está dockada (null se não dockada)
  String? _justUndockedZone; // Zona da qual acabou de sair (para evitar redock imediato)
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
        // Limpa a flag de "just undocked" quando começa novo drag
        _justUndockedZone = null;
      });
    }
  }

  void _updateDockZone(Offset position, Size screenSize) {
    String? newZone;
    
    // Se estiver dockado, verifica se deve sair do dock
    if (_dockedZone != null) {
      final availableSize = _getAvailableSize(screenSize);
      bool shouldUndock = false;
      
      // Verifica se está suficientemente longe da borda para sair do dock
      // Usa a borda da janela (não o centro) para detectar se saiu da zona de dock
      switch (_dockedZone) {
        case 'left':
          // Se a borda esquerda da janela se afastou da borda esquerda da tela
          shouldUndock = position.dx > _undockThreshold;
          break;
        case 'right':
          // Se a borda direita da janela se afastou da borda direita da tela
          shouldUndock = (availableSize.width - position.dx - _width) > _undockThreshold;
          break;
        case 'top':
          // Se a borda superior da janela se afastou da borda superior da tela
          shouldUndock = position.dy > _undockThreshold;
          break;
        case 'bottom':
          // Se a borda inferior da janela se afastou da borda inferior da tela
          shouldUndock = (availableSize.height - position.dy - _height) > _undockThreshold;
          break;
      }
      
      if (shouldUndock) {
        // Sai do dock - marca a zona da qual saiu para evitar redock imediato
        _justUndockedZone = _dockedZone;
        _dockedZone = null;
        _currentDockZone = null;
        _lastDetectedDockZone = null;
        return;
      } else {
        // Ainda está próximo, mantém dockado
        _currentDockZone = _dockedZone;
        return;
      }
    }
    
    // Se não estiver dockado, detecta nova zona de docking
    final availableSize = _getAvailableSize(screenSize);
    final leftDistance = position.dx;
    final rightDistance = availableSize.width - position.dx - _width;
    final topDistance = position.dy;
    final bottomDistance = availableSize.height - position.dy - _height;
    
    // Verifica qual borda está mais próxima (threshold reduzido)
    // Mas ignora se acabou de sair dessa zona (evita redock imediato)
    if (leftDistance < _dockThreshold && 
        (leftDistance < rightDistance || rightDistance >= _dockThreshold) &&
        _justUndockedZone != 'left') {
      newZone = 'left';
    } else if (rightDistance < _dockThreshold && _justUndockedZone != 'right') {
      newZone = 'right';
    } else if (topDistance < _dockThreshold && 
               (topDistance < bottomDistance || bottomDistance >= _dockThreshold) &&
               _justUndockedZone != 'top') {
      newZone = 'top';
    } else if (bottomDistance < _dockThreshold && _justUndockedZone != 'bottom') {
      newZone = 'bottom';
    } else {
      newZone = null;
    }
    
    // Se está longe o suficiente de todas as bordas, limpa a flag de "just undocked"
    if (leftDistance > _undockThreshold && 
        rightDistance > _undockThreshold && 
        topDistance > _undockThreshold && 
        bottomDistance > _undockThreshold) {
      _justUndockedZone = null;
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
        // Mas usa altura menor (padrão reduzido para top/bottom)
        final maxHeight = availableSize.height * 0.4; // Máximo 40% da altura
        // Garante que maxHeight seja pelo menos widget.minHeight para evitar erro no clamp
        // Se a tela for muito pequena, usa minHeight como máximo também
        final clampedMaxHeight = maxHeight < widget.minHeight ? widget.minHeight : maxHeight;
        // Limita a altura atual entre minHeight e o máximo permitido
        final defaultHeight = _height.clamp(widget.minHeight, clampedMaxHeight);
        return Size(availableSize.width, defaultHeight);
      default:
        return Size(_width, _height);
    }
  }
  
  void _adjustDockedSize() {
    // Ajusta tamanho e posição se estiver dockado
    // MAS não durante drag ou resize (permite que o usuário arraste para sair do dock)
    if (_dockedZone != null && _screenSize != null && !_isDragging && !_isResizing) {
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
        final availableSize = _getAvailableSize(_screenSize!);
        
        // IMPORTANTE: Detecta zona de dock ANTES de aplicar qualquer clamp
        // Usa a posição "livre" para detectar se estamos próximos da borda
        final previousDockedZone = _dockedZone;
        _updateDockZone(newPosition, _screenSize!);
        
        // Se saiu do dock durante o drag, aplica limites normais e restaura tamanho se necessário
        if (previousDockedZone != null && _dockedZone == null) {
          // Saiu do dock, aplica limites normais e permite movimento livre
          // Se a janela estava com tamanho de dock (altura/largura cheia), restaura tamanho razoável
          double? newWidth;
          double? newHeight;
          
          // Se estava dockado lateralmente (left/right), a altura pode estar cheia
          if (previousDockedZone == 'left' || previousDockedZone == 'right') {
            if (_height > availableSize.height * 0.8) {
              // Altura muito grande, restaura para um tamanho razoável
              newHeight = widget.initialHeight.clamp(widget.minHeight, availableSize.height * 0.7);
            }
          }
          
          // Se estava dockado verticalmente (top/bottom), a largura pode estar cheia
          if (previousDockedZone == 'top' || previousDockedZone == 'bottom') {
            if (_width > availableSize.width * 0.8) {
              // Largura muito grande, restaura para um tamanho razoável
              newWidth = widget.initialWidth.clamp(widget.minWidth, availableSize.width * 0.7);
            }
          }
          
          final clampedPosition = Offset(
            newPosition.dx.clamp(0, availableSize.width - (newWidth ?? _width)),
            newPosition.dy.clamp(0, availableSize.height - (newHeight ?? _height)),
          );
          
          setState(() {
            _position = clampedPosition;
            if (newWidth != null) _width = newWidth;
            if (newHeight != null) _height = newHeight;
          });
        } else if (_dockedZone != null) {
          // Está dockado, permite movimento livre para facilitar saída do dock
          // A lógica de undock será verificada no _updateDockZone
          setState(() {
            _position = newPosition;
          });
        } else if (_currentDockZone != null && _dockedZone == null) {
          // Está entrando em zona de dock (mas ainda não dockado), permite movimento livre
          setState(() {
            _position = newPosition;
          });
        } else {
          // Não está dockado nem próximo de dock, aplica limites normais
          final clampedPosition = Offset(
            newPosition.dx.clamp(0, availableSize.width - _width),
            newPosition.dy.clamp(0, availableSize.height - _height),
          );
          
          setState(() {
            _position = clampedPosition;
          });
        }
      } else {
        setState(() {
          _position = newPosition;
        });
      }
    }
  }

  void _finishDrag() {
    // Se estava dockado e saiu do dock, não tenta fazer dock novamente
    if (_dockedZone == null && _currentDockZone == null && _lastDetectedDockZone == null) {
      // Não está em nenhuma zona, apenas finaliza o drag
      setState(() {
        _isDragging = false;
        _currentDockZone = null;
        _lastDetectedDockZone = null;
      });
      return;
    }
    
    // Usa a última zona detectada OU a zona atual (preferência para atual)
    final zoneToDock = _currentDockZone ?? _lastDetectedDockZone;
    
    // Verifica se temos zona e tamanho da tela
    if (_screenSize == null) {
      final mediaQuery = MediaQuery.maybeOf(context);
      if (mediaQuery != null) {
        _screenSize = mediaQuery.size;
      }
    }
    
    // Só faz dock se realmente estiver próximo da borda E não estava dockado antes
    // (evita fazer dock novamente imediatamente após sair)
    if (_screenSize != null && zoneToDock != null && _currentDockZone != null && _dockedZone == null) {
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
      // Não está próximo o suficiente para fazer dock, apenas finaliza
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
    return AppTheme.neonBlue.withOpacity(0.2);
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
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _currentDockZone != null
                      ? AppTheme.neonBlue.withOpacity(0.5)
                      : AppTheme.neonBlue.withOpacity(0.15),
                  width: _currentDockZone != null ? 1.5 : 1,
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
                      color: AppTheme.surfaceVariantDark,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: AppTheme.neonBlue.withOpacity(0.1),
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
                      color: AppTheme.surfaceDark,
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
                        color: AppTheme.surfaceVariantDark.withOpacity(0.5),
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
                          color: AppTheme.neonBlue.withOpacity(0.5),
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

