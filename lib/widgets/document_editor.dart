import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/node.dart';
import '../theme/app_theme.dart';
import 'confirmation_dialog.dart';

/// Intent para Tab com indentação
class _TabIndentIntent extends Intent {
  const _TabIndentIntent();
}

/// Widget para editar campos personalizados de um node (inspector-style)
class DocumentEditor extends StatefulWidget {
  final Node? selectedNode;
  final Function(String nodeId, String fieldKey, dynamic fieldValue) onFieldChanged;
  final Function(String nodeId, String fieldKey) onFieldRemoved;
  final Function(String nodeId, String fieldKey, dynamic fieldValue) onFieldAdded;
  final FocusNode? mainAppFocusNode;

  const DocumentEditor({
    super.key,
    this.selectedNode,
    required this.onFieldChanged,
    required this.onFieldRemoved,
    required this.onFieldAdded,
    this.mainAppFocusNode,
  });

  @override
  State<DocumentEditor> createState() => _DocumentEditorState();
}

class _DocumentEditorState extends State<DocumentEditor> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _fieldTypes = {};
  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, TextEditingController> _descriptionControllers = {}; // Para campos de texto longo
  String _newFieldType = 'String';
  final TextEditingController _newFieldKeyController = TextEditingController();
  final TextEditingController _newFieldValueController = TextEditingController();
  late final FocusNode _newFieldKeyFocusNode;
  late final FocusNode _newFieldValueFocusNode;
  bool _showAddField = false;

  // Chave especial para armazenar metadados de tipos de campos
  static const String _fieldTypesKey = '__fieldTypes__';

  /// Carrega os tipos de campos dos metadados do node
  Map<String, String> _loadFieldTypes() {
    if (widget.selectedNode == null) return {};
    final fields = widget.selectedNode!.fields;
    final typesData = fields[_fieldTypesKey];
    if (typesData is Map) {
      return Map<String, String>.from(typesData.map((k, v) => MapEntry(k.toString(), v.toString())));
    }
    return {};
  }

  /// Salva o tipo de um campo específico nos metadados
  void _saveFieldType(String key, String type) {
    if (widget.selectedNode == null) return;
    
    // Atualiza o tipo localmente
    _fieldTypes[key] = type;
    
    // Salva nos metadados do node através de um campo especial
    final currentFields = Map<String, dynamic>.from(widget.selectedNode!.fields);
    final typesData = currentFields[_fieldTypesKey];
    final typesMap = typesData is Map 
        ? Map<String, dynamic>.from(typesData)
        : <String, dynamic>{};
    typesMap[key] = type;
    
    // Salva os metadados usando onFieldChanged para que sejam persistidos
    widget.onFieldChanged(widget.selectedNode!.id, _fieldTypesKey, typesMap);
  }

  @override
  void initState() {
    super.initState();
    _newFieldKeyFocusNode = FocusNode();
    _newFieldValueFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _disposeControllers();
    _newFieldKeyController.dispose();
    _newFieldValueController.dispose();
    _newFieldKeyFocusNode.dispose();
    _newFieldValueFocusNode.dispose();
    for (final controller in _descriptionControllers.values) {
      controller.dispose();
    }
    _descriptionControllers.clear();
    super.dispose();
  }

  void _disposeControllers() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    _focusNodes.clear();
    
    for (final controller in _descriptionControllers.values) {
      controller.dispose();
    }
    _descriptionControllers.clear();
    
    _fieldTypes.clear();
  }

  @override
  void didUpdateWidget(DocumentEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    final oldNode = oldWidget.selectedNode;
    final newNode = widget.selectedNode;
    
    if (oldNode?.id != newNode?.id) {
      _updateControllers();
    } else if (oldNode != null && newNode != null) {
      if (_fieldsChanged(oldNode.fields, newNode.fields)) {
        _updateControllers();
      }
    } else if (oldNode == null && newNode != null) {
      _updateControllers();
    } else if (oldNode != null && newNode == null) {
      _disposeControllers();
    }
  }

  bool _fieldsChanged(Map<String, dynamic> oldFields, Map<String, dynamic> newFields) {
    if (oldFields.length != newFields.length) return true;
    if (oldFields.keys.toSet() != newFields.keys.toSet()) return true;
    for (final key in oldFields.keys) {
      if (oldFields[key] != newFields[key]) return true;
    }
    return false;
  }

  void _updateControllers() {
    if (widget.selectedNode == null) {
      _disposeControllers();
      return;
    }

    final node = widget.selectedNode!;
    final newFields = node.fields;
    
    // IMPORTANTE: Carrega os tipos persistidos dos metadados do node
    // Os tipos dos metadados têm prioridade sobre os tipos em memória
    final persistedTypes = _loadFieldTypes();
    for (final entry in persistedTypes.entries) {
      _fieldTypes[entry.key] = entry.value;
    }
    
    // Remove controllers de campos que não existem mais
    final keysToRemove = _controllers.keys.where((key) => !newFields.containsKey(key) || key == _fieldTypesKey).toList();
    for (final key in keysToRemove) {
      _controllers[key]?.dispose();
      _controllers.remove(key);
      _focusNodes[key]?.dispose();
      _focusNodes.remove(key);
      _fieldTypes.remove(key);
      _descriptionControllers[key]?.dispose();
      _descriptionControllers.remove(key);
    }
    
    // Atualiza ou cria controllers para campos existentes
    newFields.forEach((key, value) {
      // Ignora o campo de metadados
      if (key == _fieldTypesKey) return;
      
      final isEditing = _focusNodes[key]?.hasFocus ?? false;
      
      if (_controllers.containsKey(key)) {
        if (!isEditing) {
          final currentValue = _valueToString(value);
          if (_controllers[key]!.text != currentValue) {
            _controllers[key]!.text = currentValue;
          }
          if (_descriptionControllers.containsKey(key) && _descriptionControllers[key]!.text != currentValue) {
            _descriptionControllers[key]!.text = currentValue;
          }
          // Preserva o tipo se já existe (dos metadados ou memória), senão detecta
          if (!_fieldTypes.containsKey(key)) {
            _fieldTypes[key] = _getValueType(value);
          }
        }
      } else {
        _controllers[key] = TextEditingController(text: _valueToString(value));
        // IMPORTANTE: Carrega o tipo dos metadados persistidos primeiro
        // Se não existe em metadados, usa o tipo detectado
        if (!_fieldTypes.containsKey(key)) {
          _fieldTypes[key] = _getValueType(value);
        }
        final savedType = _fieldTypes[key]!;
        _focusNodes[key] = FocusNode();
        
        // IMPORTANTE: Se for tipo "text", SEMPRE cria descriptionController, independente do tamanho
        // Se for "String" longo (>50 chars), também cria
        if (savedType == 'text') {
          // Tipo "text" sempre usa textarea
          _descriptionControllers[key] = TextEditingController(text: _valueToString(value));
        } else if (savedType == 'String' && _valueToString(value).length > 50) {
          // String longo também usa textarea
          _descriptionControllers[key] = TextEditingController(text: _valueToString(value));
        }
        
        _focusNodes[key]!.addListener(() {
          if (mounted) {
            final hasFocus = _focusNodes[key]!.hasFocus;
            setState(() {});
            if (!hasFocus) {
              _confirmFieldEdit(key);
            }
          }
        });
      }
    });
  }

  String _valueToString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  String _getValueType(dynamic value) {
    if (value is String) return 'String';
    if (value is int || value is double) return 'number';
    if (value is bool) return 'bool';
    return 'String';
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'number':
        return Icons.tag;
      case 'bool':
        return Icons.toggle_on;
      case 'text':
        return Icons.article;
      case 'String':
      default:
        return Icons.text_fields;
    }
  }

  Color _getIconColorForType(String type) {
    switch (type) {
      case 'number':
        return AppTheme.neonBlue;
      case 'bool':
        return AppTheme.neonCyan;
      case 'text':
        return AppTheme.neonCyan;
      case 'String':
      default:
        return AppTheme.textSecondary;
    }
  }

  dynamic _parseValue(String value, String type) {
    switch (type) {
      case 'number':
        // Tenta primeiro como double, depois como int
        final doubleValue = double.tryParse(value);
        if (doubleValue != null) {
          // Se é um número inteiro, retorna int; senão retorna double
          if (doubleValue == doubleValue.truncateToDouble()) {
            return doubleValue.toInt();
          }
          return doubleValue;
        }
        return 0;
      case 'bool':
        return value.toLowerCase() == 'true';
      case 'text':
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
    
    // IMPORTANTE: Salva o tipo do campo em _fieldTypes ANTES de atualizar controllers
    // Isso garante que campos "text" sejam reconhecidos corretamente
    _fieldTypes[key] = type;
    
    // IMPORTANTE: Persiste o tipo nos metadados do node para que seja preservado ao fechar/abrir
    _saveFieldType(key, type);

    _newFieldKeyController.clear();
    _newFieldValueController.clear();
    setState(() {
      _newFieldType = 'String';
      _showAddField = false;
    });

    _updateControllers();
  }

  void _confirmFieldEdit(String key) {
    if (widget.selectedNode == null) return;
    
    final controller = _descriptionControllers.containsKey(key) 
        ? _descriptionControllers[key] 
        : _controllers[key];
    if (controller == null) return;
    
    final valueStr = controller.text;
    final type = _fieldTypes[key] ?? 'String';
    final value = _parseValue(valueStr, type);
    
    final currentValue = widget.selectedNode!.fields[key];
    if (currentValue != value) {
      widget.onFieldChanged(widget.selectedNode!.id, key, value);
    }
  }

  void _removeField(String key) {
    if (widget.selectedNode == null) return;

    widget.onFieldRemoved(widget.selectedNode!.id, key);
    _controllers[key]?.dispose();
    _controllers.remove(key);
    _focusNodes[key]?.dispose();
    _focusNodes.remove(key);
    _fieldTypes.remove(key);
    _descriptionControllers[key]?.dispose();
    _descriptionControllers.remove(key);
  }

  /// Pergunta se quer cancelar a criação do campo
  Future<void> _askToCancelFieldCreation() async {
    await ConfirmationDialog.show(
      context: context,
      title: 'Cancelar criação de campo?',
      message: 'Deseja cancelar a criação deste campo?',
      confirmText: 'Sim, cancelar',
      cancelText: 'Continuar editando',
      isDestructive: false,
      onConfirm: () {
        setState(() {
          _showAddField = false;
          _newFieldKeyController.clear();
          _newFieldValueController.clear();
          _newFieldType = 'String';
        });
      },
    );
  }

  /// Abre um dialog para editar texto longo em um campo maior
  Future<void> _openTextEditorDialog(String key, TextEditingController controller) async {
    final editedText = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        final textController = TextEditingController(text: controller.text);
        
        return Dialog(
          backgroundColor: AppTheme.surfaceElevated,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.article, size: 20, color: AppTheme.neonBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Editar: $key',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 20, color: AppTheme.textSecondary),
                      onPressed: () => Navigator.of(dialogContext).pop(null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Campo de texto grande
                Expanded(
                  child: Shortcuts(
                    shortcuts: {
                      LogicalKeySet(LogicalKeyboardKey.tab): const _TabIndentIntent(),
                    },
                    child: Actions(
                      actions: {
                        _TabIndentIntent: CallbackAction<_TabIndentIntent>(
                          onInvoke: (_) {
                            final text = textController.text;
                            final selection = textController.selection;
                            
                            if (selection.isValid) {
                              final start = selection.start;
                              final end = selection.end;
                              
                              final indent = '  ';
                              final textBefore = text.substring(0, start);
                              final textAfter = text.substring(end);
                              
                              final newText = textBefore + indent + textAfter;
                              final newCursorPosition = start + indent.length;
                              
                              textController.value = TextEditingValue(
                                text: newText,
                                selection: TextSelection.collapsed(offset: newCursorPosition),
                              );
                            }
                            return null;
                          },
                        ),
                      },
                      child: TextField(
                        controller: textController,
                        autofocus: true,
                        maxLines: null,
                        expands: true,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                          height: 1.5,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Digite o texto...',
                          contentPadding: const EdgeInsets.all(16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppTheme.borderNeutral),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppTheme.borderNeutral),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppTheme.neonBlue, width: 2),
                          ),
                          filled: true,
                          fillColor: AppTheme.surfaceVariantDark,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Botões
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(null),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.of(dialogContext).pop(textController.text),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.neonBlue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Salvar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    // Se o usuário salvou (não cancelou), atualiza o campo
    if (editedText != null && widget.selectedNode != null) {
      controller.text = editedText;
      _confirmFieldEdit(key);
    }
  }

  /// Abre um dialog para editar texto longo enquanto está criando um novo campo
  Future<void> _openNewFieldTextEditorDialog() async {
    final editedText = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        final textController = TextEditingController(text: _newFieldValueController.text);
        
        return Dialog(
          backgroundColor: AppTheme.surfaceElevated,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.article, size: 20, color: AppTheme.neonBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Editar Valor',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 20, color: AppTheme.textSecondary),
                      onPressed: () => Navigator.of(dialogContext).pop(null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Campo de texto grande
                Expanded(
                  child: Shortcuts(
                    shortcuts: {
                      LogicalKeySet(LogicalKeyboardKey.tab): const _TabIndentIntent(),
                    },
                    child: Actions(
                      actions: {
                        _TabIndentIntent: CallbackAction<_TabIndentIntent>(
                          onInvoke: (_) {
                            final text = textController.text;
                            final selection = textController.selection;
                            
                            if (selection.isValid) {
                              final start = selection.start;
                              final end = selection.end;
                              
                              final indent = '  ';
                              final textBefore = text.substring(0, start);
                              final textAfter = text.substring(end);
                              
                              final newText = textBefore + indent + textAfter;
                              final newCursorPosition = start + indent.length;
                              
                              textController.value = TextEditingValue(
                                text: newText,
                                selection: TextSelection.collapsed(offset: newCursorPosition),
                              );
                            }
                            return null;
                          },
                        ),
                      },
                      child: TextField(
                        controller: textController,
                        autofocus: true,
                        maxLines: null,
                        expands: true,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                          height: 1.5,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Digite o texto...',
                          contentPadding: const EdgeInsets.all(16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppTheme.borderNeutral),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppTheme.borderNeutral),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppTheme.neonBlue, width: 2),
                          ),
                          filled: true,
                          fillColor: AppTheme.surfaceVariantDark,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Botões
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(null),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.of(dialogContext).pop(textController.text),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.neonBlue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Salvar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    // Se o usuário salvou (não cancelou), atualiza o campo de valor
    if (editedText != null) {
      setState(() {
        _newFieldValueController.text = editedText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedNode == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.textTertiary),
              const SizedBox(height: 16),
              Text(
                'Nenhum node selecionado',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final node = widget.selectedNode!;
    final fields = node.fields;

    return Container(
      color: AppTheme.surfaceDark,
      child: Column(
        children: [
          // Header compacto
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceNeutral,
              border: Border(
                bottom: BorderSide(color: AppTheme.borderNeutral, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.inventory_2, size: 16, color: AppTheme.neonBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${node.name} (${_getNodeType(node)})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _showAddField ? Icons.close : Icons.add,
                    size: 18,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _showAddField = !_showAddField;
                    });
                  },
                  tooltip: _showAddField ? 'Fechar' : 'Adicionar campo',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
              ],
            ),
          ),
          
          // Lista de propriedades
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // Propriedades existentes
                  if (fields.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Nenhum campo adicionado',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    )
                  else
                    ...fields.entries.where((entry) => entry.key != _fieldTypesKey).map((entry) {
                      final key = entry.key;
                      final value = entry.value;
                      // IMPORTANTE: Preserva o tipo se já existe, senão tenta detectar
                      // Se não existe em _fieldTypes, usa _getValueType que pode retornar "String" por padrão
                      // Mas se o campo foi criado como "text", precisa estar em _fieldTypes
                      final type = _fieldTypes[key] ?? _getValueType(value);
                      
                      if (!_controllers.containsKey(key)) {
                        _controllers[key] = TextEditingController(text: _valueToString(value));
                        // PRIORIDADE: Garante que o tipo seja salvo em _fieldTypes
                        // Se não existe, usa o tipo detectado
                        final currentType = _fieldTypes[key] ?? type;
                        if (!_fieldTypes.containsKey(key)) {
                          _fieldTypes[key] = currentType;
                        }
                        _focusNodes[key] = FocusNode();
                        
                        // IMPORTANTE: Se for tipo "text", SEMPRE cria descriptionController
                        // Se for "String" longo (>50 chars), também cria
                        final savedType = _fieldTypes[key] ?? currentType;
                        if (savedType == 'text') {
                          // Tipo "text" sempre usa textarea, independente do tamanho
                          _descriptionControllers[key] = TextEditingController(text: _valueToString(value));
                        } else if (savedType == 'String' && _valueToString(value).length > 50) {
                          // String longo também usa textarea
                          _descriptionControllers[key] = TextEditingController(text: _valueToString(value));
                        }
                        
                        _focusNodes[key]!.addListener(() {
                          if (mounted) {
                            setState(() {});
                            if (!_focusNodes[key]!.hasFocus) {
                              _confirmFieldEdit(key);
                            }
                          }
                        });
                      }
                      
                      final controller = _descriptionControllers.containsKey(key)
                          ? _descriptionControllers[key]!
                          : _controllers[key]!;
                      final focusNode = _focusNodes[key]!;
                      
                      // PRIORIDADE: Usa o tipo salvo em _fieldTypes
                      // Se não existe em _fieldTypes, tenta detectar:
                      // - Se tem _descriptionControllers E não é string longo (>50), provavelmente é "text"
                      // - Senão, usa o tipo detectado pelo valor (que será "String" para strings)
                      final savedType = _fieldTypes[key];
                      final hasDescriptionController = _descriptionControllers.containsKey(key);
                      final isLongStringAuto = type == 'String' && _valueToString(value).length > 50;
                      
                      String finalType;
                      if (savedType != null) {
                        // Se tem tipo salvo, usa ele (garante que campos "text" sejam sempre reconhecidos)
                        finalType = savedType;
                      } else if (hasDescriptionController && !isLongStringAuto) {
                        // Se tem descriptionController mas não foi criado automaticamente por ser longo,
                        // provavelmente é "text"
                        finalType = 'text';
                        _fieldTypes[key] = 'text'; // Salva para próxima vez
                      } else {
                        // Senão, usa o tipo detectado (pode ser "String" para strings normais)
                        finalType = type;
                      }
                      
                      final isString = finalType == 'String';
                      final isText = finalType == 'text'; // SEMPRE mostra botão se tipo for "text"
                      final isLongString = hasDescriptionController || isText;
                      final isBool = finalType == 'bool';
                      
                      // Debug para verificar se o tipo está correto
                      if (isText) {
                        print('🔵 [DocumentEditor] Campo "$key" é do tipo "text", isText=$isText, finalType=$finalType, savedType=$savedType');
                      }
                      
                      return _buildPropertyRow(
                        key: key,
                        type: finalType, // Usa o tipo salvo, não o detectado
                        value: value,
                        controller: controller,
                        focusNode: focusNode,
                        isString: isString,
                        isText: isText,
                        isLongString: isLongString,
                        isBool: isBool,
                      );
                    }),
                  
                  // Seção para adicionar novo campo
                  if (_showAddField)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariantDark.withOpacity(0.5),
                        border: Border(
                          top: BorderSide(color: AppTheme.borderNeutral, width: 1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Adicionar Campo',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Nome do campo
                          Focus(
                            onKeyEvent: (node, event) {
                              // Intercepta Backspace/Delete quando o campo está vazio
                              if (event is KeyDownEvent && 
                                  _newFieldKeyController.text.isEmpty &&
                                  (event.logicalKey == LogicalKeyboardKey.backspace ||
                                   event.logicalKey == LogicalKeyboardKey.delete)) {
                                // Pergunta se quer cancelar a criação do campo
                                _askToCancelFieldCreation();
                                return KeyEventResult.handled;
                              }
                              return KeyEventResult.ignored;
                            },
                            child: _buildCompactTextField(
                              controller: _newFieldKeyController,
                              focusNode: _newFieldKeyFocusNode,
                              label: 'Nome',
                              hintText: 'Ex: description, cost',
                              icon: Icons.label_outline,
                            ),
                          ),
                          const SizedBox(height: 6),
                          
                          // Tipo e valor
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  value: _newFieldType,
                                  decoration: InputDecoration(
                                    labelText: 'Tipo',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(color: AppTheme.borderNeutral),
                                    ),
                                    filled: true,
                                    fillColor: AppTheme.surfaceVariantDark,
                                  ),
                                  style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                                    items: const [
                                      DropdownMenuItem(value: 'String', child: Text('String')),
                                      DropdownMenuItem(value: 'text', child: Text('text')),
                                      DropdownMenuItem(value: 'number', child: Text('number')),
                                      DropdownMenuItem(value: 'bool', child: Text('bool')),
                                    ],
                                  onChanged: (value) {
                                    setState(() {
                                      _newFieldType = value ?? 'String';
                                      if (value == 'bool') {
                                        _newFieldValueController.text = 'false';
                                      } else {
                                        _newFieldValueController.clear();
                                      }
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 3,
                                child: _newFieldType == 'bool'
                                    ? Row(
                                        children: [
                                          Checkbox(
                                            value: _newFieldValueController.text.toLowerCase() == 'true',
                                            onChanged: (bool? newValue) {
                                              setState(() {
                                                _newFieldValueController.text = newValue == true ? 'true' : 'false';
                                              });
                                            },
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          Expanded(
                                            child: Text(
                                              _newFieldValueController.text.toLowerCase() == 'true' ? 'Verdadeiro' : 'Falso',
                                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                            ),
                                          ),
                                        ],
                                      )
                                    : _newFieldType == 'text'
                                        ? Row(
                                            children: [
                                              Expanded(
                                                child: Shortcuts(
                                                  shortcuts: {
                                                    LogicalKeySet(LogicalKeyboardKey.tab): const _TabIndentIntent(),
                                                  },
                                                  child: Actions(
                                                    actions: {
                                                      _TabIndentIntent: CallbackAction<_TabIndentIntent>(
                                                        onInvoke: (_) {
                                                          final text = _newFieldValueController.text;
                                                          final selection = _newFieldValueController.selection;
                                                          
                                                          if (selection.isValid) {
                                                            final start = selection.start;
                                                            final end = selection.end;
                                                            
                                                            final indent = '  ';
                                                            final textBefore = text.substring(0, start);
                                                            final textAfter = text.substring(end);
                                                            
                                                            final newText = textBefore + indent + textAfter;
                                                            final newCursorPosition = start + indent.length;
                                                            
                                                            _newFieldValueController.value = TextEditingValue(
                                                              text: newText,
                                                              selection: TextSelection.collapsed(offset: newCursorPosition),
                                                            );
                                                          }
                                                          return null;
                                                        },
                                                      ),
                                                    },
                                                    child: TextField(
                                                      controller: _newFieldValueController,
                                                      focusNode: _newFieldValueFocusNode,
                                                      maxLines: null,
                                                      minLines: 4,
                                                      style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                                                      decoration: InputDecoration(
                                                        hintText: 'Digite o texto longo...',
                                                        isDense: true,
                                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                        border: OutlineInputBorder(
                                                          borderSide: BorderSide(color: AppTheme.borderNeutral),
                                                        ),
                                                        enabledBorder: OutlineInputBorder(
                                                          borderSide: BorderSide(color: AppTheme.borderNeutral),
                                                        ),
                                                        focusedBorder: OutlineInputBorder(
                                                          borderSide: BorderSide(color: AppTheme.neonBlue, width: 1.5),
                                                        ),
                                                        filled: true,
                                                        fillColor: _newFieldValueFocusNode.hasFocus
                                                            ? AppTheme.neonBlue.withOpacity(0.1)
                                                            : AppTheme.surfaceVariantDark,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // Botão para abrir popup de edição maior (enquanto está criando)
                                              Padding(
                                                padding: const EdgeInsets.only(left: 4),
                                                child: IconButton(
                                                  icon: Icon(Icons.open_in_full, size: 16, color: AppTheme.neonBlue),
                                                  onPressed: () => _openNewFieldTextEditorDialog(),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                                  tooltip: 'Abrir editor maior',
                                                ),
                                              ),
                                            ],
                                          )
                                        : _buildCompactTextField(
                                            controller: _newFieldValueController,
                                            focusNode: _newFieldValueFocusNode,
                                            label: 'Valor',
                                            hintText: _getHintForType(_newFieldType),
                                            fieldType: _newFieldType,
                                          ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          // Botão adicionar
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              onPressed: _addNewField,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Adicionar'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                backgroundColor: AppTheme.neonBlue.withOpacity(0.1),
                                foregroundColor: AppTheme.neonBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getNodeType(Node node) => 'Node';

  Widget _buildPropertyRow({
    required String key,
    required String type,
    required dynamic value,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isString,
    required bool isText,
    required bool isLongString,
    required bool isBool,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.borderNeutral.withOpacity(0.3), width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: isLongString ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          // Label à esquerda
          SizedBox(
            width: 100,
            child: Text(
              key,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Valor à direita
          Expanded(
            child: isBool
                ? Row(
                    children: [
                      Checkbox(
                        value: value is bool ? value : false,
                        onChanged: (bool? newValue) {
                          if (newValue != null) {
                            widget.onFieldChanged(widget.selectedNode!.id, key, newValue);
                          }
                        },
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          value is bool && value ? 'Verdadeiro' : 'Falso',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 16, color: AppTheme.textTertiary),
                        onPressed: () => _removeField(key),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        tooltip: 'Remover',
                      ),
                    ],
                  )
                : Row(
                    children: [
                      // Ícone do tipo
                      Icon(
                        _getIconForType(type),
                        size: 14,
                        color: _getIconColorForType(type),
                      ),
                      const SizedBox(width: 6),
                      
                      // Campo de texto
                      Expanded(
                        child: isLongString
                            ? Row(
                                children: [
                                  Expanded(
                                    child: isText
                                        ? Shortcuts(
                                            shortcuts: {
                                              LogicalKeySet(LogicalKeyboardKey.tab): const _TabIndentIntent(),
                                            },
                                            child: Actions(
                                              actions: {
                                                _TabIndentIntent: CallbackAction<_TabIndentIntent>(
                                                  onInvoke: (_) {
                                                    final text = controller.text;
                                                    final selection = controller.selection;
                                                    
                                                    if (selection.isValid) {
                                                      final start = selection.start;
                                                      final end = selection.end;
                                                      
                                                      final indent = '  ';
                                                      final textBefore = text.substring(0, start);
                                                      final textAfter = text.substring(end);
                                                      
                                                      final newText = textBefore + indent + textAfter;
                                                      final newCursorPosition = start + indent.length;
                                                      
                                                      controller.value = TextEditingValue(
                                                        text: newText,
                                                        selection: TextSelection.collapsed(offset: newCursorPosition),
                                                      );
                                                    }
                                                    return null;
                                                  },
                                                ),
                                              },
                                              child: TextField(
                                                controller: controller,
                                                focusNode: focusNode,
                                                maxLines: null,
                                                minLines: 4,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme.textPrimary,
                                                ),
                                                decoration: InputDecoration(
                                                  hintText: 'Digite o texto...',
                                                  isDense: true,
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                  border: OutlineInputBorder(
                                                    borderSide: BorderSide(color: AppTheme.borderNeutral),
                                                  ),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderSide: BorderSide(color: AppTheme.borderNeutral),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderSide: BorderSide(color: AppTheme.neonBlue, width: 1.5),
                                                  ),
                                                  filled: true,
                                                  fillColor: focusNode.hasFocus
                                                      ? AppTheme.neonBlue.withOpacity(0.1)
                                                      : AppTheme.surfaceVariantDark,
                                                ),
                                              ),
                                            ),
                                          )
                                        : TextField(
                                            controller: controller,
                                            focusNode: focusNode,
                                            maxLines: 3,
                                            minLines: 2,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textPrimary,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'Digite o texto...',
                                              isDense: true,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                              border: OutlineInputBorder(
                                                borderSide: BorderSide(color: AppTheme.borderNeutral),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(color: AppTheme.borderNeutral),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(color: AppTheme.neonBlue, width: 1.5),
                                              ),
                                              filled: true,
                                              fillColor: focusNode.hasFocus
                                                  ? AppTheme.neonBlue.withOpacity(0.1)
                                                  : AppTheme.surfaceVariantDark,
                                            ),
                                          ),
                                  ),
                                  // Botão para abrir popup de edição maior (SEMPRE para tipo "text")
                                  // Aparece sempre que o tipo for "text", independente do tamanho
                                  if (isText)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: IconButton(
                                        icon: Icon(Icons.open_in_full, size: 16, color: AppTheme.neonBlue),
                                        onPressed: () => _openTextEditorDialog(key, controller),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                        tooltip: 'Abrir editor maior',
                                      ),
                                    ),
                                ],
                              )
                            : TextField(
                                controller: controller,
                                focusNode: focusNode,
                                inputFormatters: type == 'number' ? [_getNumberFormatter()] : null,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(color: AppTheme.borderNeutral),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: AppTheme.borderNeutral),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: AppTheme.neonBlue, width: 1.5),
                                  ),
                                  filled: true,
                                  fillColor: focusNode.hasFocus
                                      ? AppTheme.neonBlue.withOpacity(0.1)
                                      : AppTheme.surfaceVariantDark,
                                ),
                              ),
                      ),
                      
                      // Botão remover
                      IconButton(
                        icon: Icon(Icons.close, size: 16, color: AppTheme.textTertiary),
                        onPressed: () => _removeField(key),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        tooltip: 'Remover',
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    String? hintText,
    IconData? icon,
    String? fieldType, // Tipo do campo para aplicar formatter de número
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      inputFormatters: fieldType == 'number' ? [_getNumberFormatter()] : null,
      style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: icon != null ? Icon(icon, size: 16, color: AppTheme.textTertiary) : null,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: AppTheme.borderNeutral),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppTheme.borderNeutral),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppTheme.neonBlue, width: 1.5),
        ),
        filled: true,
        fillColor: focusNode.hasFocus
            ? AppTheme.neonBlue.withOpacity(0.1)
            : AppTheme.surfaceVariantDark,
      ),
    );
  }

  String _getHintForType(String type) {
    switch (type) {
      case 'number':
        return 'Ex: 100 ou 3.14';
      case 'bool':
        return 'true ou false';
      case 'text':
        return 'Texto longo (múltiplas linhas)';
      case 'String':
      default:
        return 'Ex: Meu texto';
    }
  }


  /// Input formatter que substitui vírgulas por pontos em números
  TextInputFormatter _getNumberFormatter() {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      // Se a mudança foi apenas adicionar uma vírgula, substitui por ponto
      if (newValue.text.length > oldValue.text.length) {
        final addedText = newValue.text.substring(oldValue.text.length);
        if (addedText == ',') {
          final newText = newValue.text.replaceAll(',', '.');
          final cursorOffset = newValue.selection.baseOffset;
          return TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: cursorOffset),
          );
        }
      }
      // Substitui todas as vírgulas existentes por pontos
      final newText = newValue.text.replaceAll(',', '.');
      if (newText != newValue.text) {
        // Mantém a posição do cursor relativa
        final offset = newValue.selection.baseOffset;
        return TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: offset),
        );
      }
      return newValue;
    });
  }
}
