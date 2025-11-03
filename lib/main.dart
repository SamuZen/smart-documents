import 'package:flutter/material.dart';
import 'models/node.dart';
import 'services/node_service.dart';
import 'widgets/tree_view.dart';

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
  late final Node _rootNode;

  @override
  void initState() {
    super.initState();
    _rootNode = NodeService.createExampleStructure();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: TreeView(rootNode: _rootNode),
    );
  }
}
