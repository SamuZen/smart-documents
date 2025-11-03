import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/node.dart';

/// Widget para editar campos personalizados de um node
class DocumentEditor extends StatefulWidget {
  final Node? selectedNode;
  final Function(String nodeId, String fieldKey, dynamic fieldValue) onFieldChanged;
  final Function(String nodeId, String fieldKey) onFieldRemoved;
  final Function(String nodeId, String fieldKey, dynamic fieldValue) onFieldAdded;

  const DocumentEditor({
    super.key,
    this.selectedNode,
    required this.onFieldChanged,
    required this.onFieldRemoved,
    required this.onFieldAdded,
  });

  @override
  State<DocumentEditor> createState() => _DocumentEditorState();
}

class _DocumentEditorState extends State<DocumentEditor> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _fieldTypes = {}; // Armazena tipo de cada campo
  String _newFieldType = 'String';
  final TextEditingController _newFieldKeyController = TextEditingController();
  final TextEditingController _newFieldValueController = TextEditingController();

  @override
  void dispose() {
    _disposeControllers();
    _newFieldKeyController.dispose();
    _newFieldValueController.dispose();
    super.dispose();
  }

  void _disposeControllers() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }

  @override
  void didUpdateWidget(DocumentEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedNode?.id != widget.selectedNode?.id) {
      _updateControllers();
    }
  }

  void _updateControllers() {
    _disposeControllers();
    _fieldTypes.clear();

    if (widget.selectedNode == null) {
      return;
    }

    // Cria controllers para cada campo existente
    widget.selectedNode!.fields.forEach((key, value) {
      _controllers[key] = TextEditingController(text: _valueToString(value));
      _fieldTypes[key] = _getValueType(value);
    });
  }

  String _valueToString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  String _getValueType(dynamic value) {
    if (value is String) return 'String';
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is bool) return 'bool';
    return 'String';
  }

  dynamic _parseValue(String value, String type) {
    switch (type) {
      case 'int':
        return int.tryParse(value);
      case 'double':
        return double.tryParse(value);
      case 'bool':
        return value.toLowerCase() == 'true';
      case 'String':
      default:
        return value;
    }
  }

  void _addNewField() {
    if (widget.selectedNode == null) return;

    final key = _newFieldKeyController.text.trim();
    final type = _newFieldType;
    final valueStr = _newFieldValueController.text.trim();

    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nome do campo não pode estar vazio')),
      );
      return;
    }

    if (widget.selectedNode!.fields.containsKey(key)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campo com este nome já existe')),
      );
      return;
    }

    final value = _parseValue(valueStr, type);
    widget.onFieldAdded(widget.selectedNode!.id, key, value);

    // Limpa campos
    _newFieldKeyController.clear();
    _newFieldValueController.clear();
    setState(() {
      _newFieldType = 'String';
    });

    // Atualiza controllers
    _updateControllers();
  }

  void _updateField(String key, String valueStr) {
    if (widget.selectedNode == null) return;

    final type = _fieldTypes[key] ?? 'String';
    final value = _parseValue(valueStr, type);
    widget.onFieldChanged(widget.selectedNode!.id, key, value);
  }

  void _removeField(String key) {
    if (widget.selectedNode == null) return;

    widget.onFieldRemoved(widget.selectedNode!.id, key);
    _controllers[key]?.dispose();
    _controllers.remove(key);
    _fieldTypes.remove(key);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedNode == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.description_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Nenhum node selecionado',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Selecione um node para editar seus campos',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final node = widget.selectedNode!;
    final fields = node.fields;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho com informações do node
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.folder, size: 20, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          node.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ID: ${node.id}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Lista de campos existentes
          const Text(
            'Campos',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          if (fields.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Nenhum campo adicionado',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...fields.entries.map((entry) {
              final key = entry.key;
              final value = entry.value;
              final controller = _controllers[key] ?? TextEditingController(text: _valueToString(value));
              if (_controllers[key] == null) {
                _controllers[key] = controller;
                _fieldTypes[key] = _getValueType(value);
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              key,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Chip(
                            label: Text(
                              _fieldTypes[key] ?? 'String',
                              style: const TextStyle(fontSize: 11),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                            tooltip: 'Remover campo',
                            onPressed: () => _removeField(key),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: 'Valor',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (value) => _updateField(key, value),
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 24),

          // Seção para adicionar novo campo
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Adicionar Novo Campo',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Nome do campo
          TextField(
            controller: _newFieldKeyController,
            decoration: const InputDecoration(
              labelText: 'Nome do campo',
              hintText: 'Ex: descrição, autor, data',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            textCapitalization: TextCapitalization.none,
          ),
          const SizedBox(height: 12),

          // Tipo do campo
          DropdownButtonFormField<String>(
            value: _newFieldType,
            decoration: const InputDecoration(
              labelText: 'Tipo',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: 'String', child: Text('Texto (String)')),
              DropdownMenuItem(value: 'int', child: Text('Número Inteiro (int)')),
              DropdownMenuItem(value: 'double', child: Text('Número Decimal (double)')),
              DropdownMenuItem(value: 'bool', child: Text('Verdadeiro/Falso (bool)')),
            ],
            onChanged: (value) {
              setState(() {
                _newFieldType = value ?? 'String';
              });
            },
          ),
          const SizedBox(height: 12),

          // Valor inicial
          TextField(
            controller: _newFieldValueController,
            decoration: InputDecoration(
              labelText: 'Valor inicial',
              hintText: _getHintForType(_newFieldType),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),

          // Botão para adicionar
          FilledButton.icon(
            onPressed: _addNewField,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Adicionar Campo'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
        ],
      ),
    );
  }

  String _getHintForType(String type) {
    switch (type) {
      case 'int':
        return 'Ex: 42';
      case 'double':
        return 'Ex: 3.14';
      case 'bool':
        return 'true ou false';
      case 'String':
      default:
        return 'Ex: Meu texto';
    }
  }
}

