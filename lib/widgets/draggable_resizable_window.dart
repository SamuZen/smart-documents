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

class _DraggableResizableWindowState extends State<DraggableResizableWindow> {
  late double _width;
  late double _height;
  late Offset _position;
  bool _isDragging = false;
  bool _isResizing = false;
  Offset? _resizeStartPosition;
  Size? _resizeStartSize;

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
      });
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isDragging && !_isResizing) {
      setState(() {
        // Usa delta incremental - mais confiável para drag
        _position = Offset(
          (_position.dx + details.delta.dx).clamp(0, double.infinity),
          (_position.dy + details.delta.dy).clamp(0, double.infinity),
        );
      });
    }
  }

  void _onDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
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

  @override
  Widget build(BuildContext context) {
    return Positioned(
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
            color: Theme.of(context).dividerColor,
            width: 1,
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
    );
  }
}

