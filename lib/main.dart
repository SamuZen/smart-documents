import 'package:flutter/material.dart';
import 'models/node.dart';
import 'services/node_service.dart';
import 'widgets/tree_view.dart';
import 'widgets/draggable_resizable_window.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Document',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 118, 206, 47)),
      ),
      home: const MyHomePage(title: 'Smart Document'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Node _rootNode;
  bool _showWindow = true;

  @override
  void initState() {
    super.initState();
    _rootNode = NodeService.createExampleStructure();
  }

  void _updateRootNode(String nodeId, String newName) {
    setState(() {
      _rootNode = _updateNodeInTree(_rootNode, nodeId, newName);
    });
  }

  Node _updateNodeInTree(Node node, String nodeId, String newName) {
    if (node.id == nodeId) {
      return node.copyWith(name: newName);
    }
    
    final updatedChildren = node.children.map((child) {
      return _updateNodeInTree(child, nodeId, newName);
    }).toList();
    
    return node.copyWith(children: updatedChildren);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(_showWindow ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _showWindow = !_showWindow;
              });
            },
            tooltip: _showWindow ? 'Ocultar janela' : 'Mostrar janela',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Área principal
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.description,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Área de trabalho principal',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          // Janela flutuante com TreeView
          if (_showWindow)
            DraggableResizableWindow(
              title: 'Navegação',
              initialWidth: 300,
              initialHeight: 500,
              minWidth: 250,
              minHeight: 300,
              onClose: () {
                setState(() {
                  _showWindow = false;
                });
              },
              child: TreeView(
                rootNode: _rootNode,
                onNodeNameChanged: _updateRootNode,
              ),
            ),
        ],
      ),
    );
  }
}
