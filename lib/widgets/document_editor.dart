import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/node.dart';
import '../theme/app_theme.dart';

/// Widget para editar campos personalizados de um node
class DocumentEditor extends StatefulWidget {
  final Node? selectedNode;
  final Function(String nodeId, String fieldKey, dynamic fieldValue) onFieldChanged;
  final Function(String nodeId, String fieldKey) onFieldRemoved;
  final Function(String nodeId, String fieldKey, dynamic fieldValue) onFieldAdded;
  final FocusNode? mainAppFocusNode; // FocusNode principal da aplicação para devolver o foco

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
  final Map<String, String> _fieldTypes = {}; // Armazena tipo de cada campo
  final Map<String, FocusNode> _focusNodes = {}; // Rastreia nodes de foco para evitar atualizar durante edição
  String _newFieldType = 'String';
  final TextEditingController _newFieldKeyController = TextEditingController();
  final TextEditingController _newFieldValueController = TextEditingController();
  late final FocusNode _newFieldKeyFocusNode;
  late final FocusNode _newFieldValueFocusNode;

  @override
  void initState() {
    super.initState();
    _newFieldKeyFocusNode = FocusNode()..addListener(() {
      if (mounted) {
        final hasFocus = _newFieldKeyFocusNode.hasFocus;
        print('🔄 [DocumentEditor] Campo "Nome do campo" foco mudou: hasFocus=$hasFocus');
        
        if (!hasFocus) {
          // Se o campo de nome perdeu o foco, verifica se devolve para o widget principal
          print('   Campo "Nome do campo" perdeu foco');
          _returnFocusToMain();
        }
      }
    });
    _newFieldValueFocusNode = FocusNode()..addListener(() {
      if (mounted) {
        final hasFocus = _newFieldValueFocusNode.hasFocus;
        print('🔄 [DocumentEditor] Campo "Valor inicial" foco mudou: hasFocus=$hasFocus');
        
        setState(() {}); // Atualiza visual quando foco muda
        if (!hasFocus) {
          // Se o campo de valor inicial perdeu o foco, devolve para o widget principal
          print('   Campo "Valor inicial" perdeu foco');
          _returnFocusToMain();
        }
      }
    });
  }

  /// Devolve o foco para o widget principal quando nenhum campo está focado
  void _returnFocusToMain() {
    print('🔄 [DocumentEditor] _returnFocusToMain chamado');
    
    // Verifica se algum campo ainda está focado
    final hasExistingFieldFocused = _focusNodes.values.any((node) => node.hasFocus);
    final hasNewKeyFocused = _newFieldKeyFocusNode.hasFocus;
    final hasNewValueFocused = _newFieldValueFocusNode.hasFocus;
    final hasAnyFieldFocused = hasExistingFieldFocused || hasNewKeyFocused || hasNewValueFocused;
    
    print('   Campos existentes focados: $hasExistingFieldFocused');
    print('   Campo "Nome" focado: $hasNewKeyFocused');
    print('   Campo "Valor inicial" focado: $hasNewValueFocused');
    print('   Algum campo focado: $hasAnyFieldFocused');
    
    if (!hasAnyFieldFocused && mounted) {
      print('✅ [DocumentEditor] Nenhum campo focado, devolvendo foco ao widget principal');
      
      // Nenhum campo está focado, devolve o foco para o widget principal
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          print('🔄 [DocumentEditor] Executando unfocus no próximo frame');
          
          // Primeiro, remove o foco de todos os campos explicitamente
          for (final focusNode in _focusNodes.values) {
            if (focusNode.hasFocus) {
              focusNode.unfocus();
            }
          }
          if (_newFieldKeyFocusNode.hasFocus) {
            _newFieldKeyFocusNode.unfocus();
          }
          if (_newFieldValueFocusNode.hasFocus) {
            _newFieldValueFocusNode.unfocus();
          }
          
          // Usa FocusScope para unfocus todos os campos
          FocusScope.of(context).unfocus();
          
          // Verifica o estado atual antes de solicitar foco no principal
          final focusScope = FocusScope.of(context);
          final focusedBefore = focusScope.focusedChild;
          final primaryFocus = FocusManager.instance.primaryFocus;
          print('   Foco antes: ${focusedBefore?.runtimeType}, primaryFocus: ${primaryFocus?.runtimeType}');
          
          // Solicita explicitamente o foco no FocusNode principal da aplicação
          if (widget.mainAppFocusNode != null && !widget.mainAppFocusNode!.hasFocus) {
            print('✅ [DocumentEditor] Solicitando foco explicitamente no mainAppFocusNode');
            widget.mainAppFocusNode!.requestFocus();
            
            // Verifica após solicitar foco
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                final focusedAfter = focusScope.focusedChild;
                final primaryFocusAfter = FocusManager.instance.primaryFocus;
                print('   Foco após solicitar: ${focusedAfter?.runtimeType}, primaryFocus: ${primaryFocusAfter?.runtimeType}');
                print('   mainAppFocusNode.hasFocus: ${widget.mainAppFocusNode?.hasFocus}');
                if (widget.mainAppFocusNode?.hasFocus == true) {
                  print('✅ [DocumentEditor] Foco devolvido com sucesso ao mainAppFocusNode');
                } else {
                  print('⚠️ [DocumentEditor] mainAppFocusNode ainda não tem foco');
                }
              }
            });
          } else if (widget.mainAppFocusNode == null) {
            print('⚠️ [DocumentEditor] mainAppFocusNode não fornecido, usando apenas unfocus');
          } else {
            print('✅ [DocumentEditor] mainAppFocusNode já tem foco');
          }
        }
      });
    } else {
      print('⏸️ [DocumentEditor] Ainda há campos focados, não devolvendo foco');
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    _newFieldKeyController.dispose();
    _newFieldValueController.dispose();
    _newFieldKeyFocusNode.dispose();
    _newFieldValueFocusNode.dispose();
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
  }

  @override
  void didUpdateWidget(DocumentEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Atualiza se o node mudou (ID diferente) ou se os campos mudaram
    final oldNode = oldWidget.selectedNode;
    final newNode = widget.selectedNode;
    
    if (oldNode?.id != newNode?.id) {
      // Node diferente, atualiza controllers
      _updateControllers();
    } else if (oldNode != null && newNode != null) {
      // Mesmo node, mas pode ter mudado os campos (undo/redo)
      if (_fieldsChanged(oldNode.fields, newNode.fields)) {
        _updateControllers();
      }
    } else if (oldNode == null && newNode != null) {
      // Node foi selecionado
      _updateControllers();
    } else if (oldNode != null && newNode == null) {
      // Node foi deselecionado
      _disposeControllers();
      _fieldTypes.clear();
    }
  }

  /// Verifica se os campos mudaram entre dois maps
  bool _fieldsChanged(Map<String, dynamic> oldFields, Map<String, dynamic> newFields) {
    // Se o número de campos mudou, claramente mudou
    if (oldFields.length != newFields.length) {
      return true;
    }
    
    // Verifica se algum campo foi removido ou adicionado
    if (oldFields.keys.toSet() != newFields.keys.toSet()) {
      return true;
    }
    
    // Verifica se algum valor mudou
    for (final key in oldFields.keys) {
      if (oldFields[key] != newFields[key]) {
        return true;
      }
    }
    
    return false;
  }

  void _updateControllers() {
    if (widget.selectedNode == null) {
      _disposeControllers();
      _fieldTypes.clear();
      return;
    }

    final node = widget.selectedNode!;
    final newFields = node.fields;
    
    // Remove controllers de campos que não existem mais
    final keysToRemove = _controllers.keys.where((key) => !newFields.containsKey(key)).toList();
    for (final key in keysToRemove) {
      _controllers[key]?.dispose();
      _controllers.remove(key);
      _focusNodes[key]?.removeListener(() {});
      _focusNodes[key]?.dispose();
      _focusNodes.remove(key);
      _fieldTypes.remove(key);
    }
    
    // Atualiza ou cria controllers para campos existentes
    newFields.forEach((key, value) {
      final isEditing = _focusNodes[key]?.hasFocus ?? false;
      
      if (_controllers.containsKey(key)) {
        // Campo já existe
        if (!isEditing) {
          // Só atualiza se não está sendo editado
          final currentValue = _valueToString(value);
          if (_controllers[key]!.text != currentValue) {
            _controllers[key]!.text = currentValue;
          }
          _fieldTypes[key] = _getValueType(value);
        }
        // Se está editando, mantém o valor atual do controller
        // O listener já foi adicionado quando o FocusNode foi criado
      } else {
        // Novo campo, cria controller e focus node
        _controllers[key] = TextEditingController(text: _valueToString(value));
        _fieldTypes[key] = _getValueType(value);
        _focusNodes[key] = FocusNode();
        
        // Adiciona listener para salvar quando perder foco e atualizar visual
        _focusNodes[key]!.addListener(() {
          if (mounted) {
            final hasFocus = _focusNodes[key]!.hasFocus;
            print('🔄 [DocumentEditor] Campo "$key" foco mudou: hasFocus=$hasFocus');
            
            setState(() {}); // Atualiza visual quando foco muda
            if (!hasFocus) {
              // Perdeu foco, confirma a edição
              print('   Campo "$key" perdeu foco, confirmando edição');
              _confirmFieldEdit(key);
              // Se nenhum campo está focado, devolve o foco para o widget principal
              _returnFocusToMain();
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


  void _confirmFieldEdit(String key) {
    if (widget.selectedNode == null) return;
    
    final controller = _controllers[key];
    if (controller == null) return;
    
    final valueStr = controller.text;
    final type = _fieldTypes[key] ?? 'String';
    final value = _parseValue(valueStr, type);
    
    // Verifica se o valor realmente mudou
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
    _fieldTypes.remove(key);
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
              Icon(Icons.description_outlined, size: 64, color: AppTheme.textTertiary),
              const SizedBox(height: 16),
              Text(
                'Nenhum node selecionado',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Selecione um node para editar seus campos',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textTertiary,
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
                      Icon(Icons.folder, size: 20, color: AppTheme.neonBlue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          node.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
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
                      color: AppTheme.textSecondary,
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Nenhum campo adicionado',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          else
            ...fields.entries.map((entry) {
              final key = entry.key;
              final value = entry.value;
              
              // Garante que temos controller e focusNode para este campo
              if (!_controllers.containsKey(key)) {
                _controllers[key] = TextEditingController(text: _valueToString(value));
                _fieldTypes[key] = _getValueType(value);
                _focusNodes[key] = FocusNode();
                
                // Adiciona listener para salvar quando perder foco
                _focusNodes[key]!.addListener(() {
                  if (mounted) {
                    final hasFocus = _focusNodes[key]!.hasFocus;
                    print('🔄 [DocumentEditor] Campo "$key" (build) foco mudou: hasFocus=$hasFocus');
                    
                    if (!hasFocus) {
                      // Perdeu foco, confirma a edição
                      print('   Campo "$key" perdeu foco, confirmando edição');
                      _confirmFieldEdit(key);
                      // Se nenhum campo está focado, devolve o foco para o widget principal
                      _returnFocusToMain();
                    }
                  }
                });
              }
              
              final controller = _controllers[key]!;
              final focusNode = _focusNodes[key]!;

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
                            icon: Icon(Icons.delete, size: 20, color: AppTheme.error),
                            tooltip: 'Remover campo',
                            onPressed: () => _removeField(key),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Se for bool, mostra checkbox; senão mostra TextField
                      _fieldTypes[key] == 'bool'
                          ? Row(
                              children: [
                                Checkbox(
                                  value: value is bool ? value : false,
                                  onChanged: (bool? newValue) {
                                    if (newValue != null) {
                                      widget.onFieldChanged(widget.selectedNode!.id, key, newValue);
                                    }
                                  },
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    value is bool && value ? 'Verdadeiro' : 'Falso',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textSecondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : _buildEditableTextField(
                              controller: controller,
                              focusNode: focusNode,
                              labelText: 'Valor',
                              onSubmitted: (_) => _confirmFieldEdit(key),
                              onEditingComplete: () => _confirmFieldEdit(key),
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
            focusNode: _newFieldKeyFocusNode,
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
                // Limpa o valor quando muda o tipo
                if (value == 'bool') {
                  _newFieldValueController.text = 'false';
                } else {
                  _newFieldValueController.clear();
                }
              });
            },
          ),
          const SizedBox(height: 12),

          // Valor inicial - se for bool, mostra checkbox; senão mostra TextField
          _newFieldType == 'bool'
              ? Row(
                  children: [
                    Checkbox(
                      value: _newFieldValueController.text.toLowerCase() == 'true',
                      onChanged: (bool? newValue) {
                        setState(() {
                          _newFieldValueController.text = newValue == true ? 'true' : 'false';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _newFieldValueController.text.toLowerCase() == 'true' ? 'Verdadeiro' : 'Falso',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                )
              : _buildEditableTextField(
                  controller: _newFieldValueController,
                  focusNode: _newFieldValueFocusNode,
                  labelText: 'Valor inicial',
                  hintText: _getHintForType(_newFieldType),
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

  /// Constrói um TextField com visual destacado quando em edição
  Widget _buildEditableTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String labelText,
    String? hintText,
    VoidCallback? onEditingComplete,
    ValueChanged<String>? onSubmitted,
  }) {
    return Builder(
      builder: (context) {
        final isEditing = focusNode.hasFocus;
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: isEditing 
                    ? Theme.of(context).colorScheme.primary 
                    : Colors.grey,
                width: isEditing ? 2 : 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: isEditing 
                    ? Theme.of(context).colorScheme.primary 
                    : Colors.grey,
                width: isEditing ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            filled: isEditing,
            fillColor: isEditing 
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : null,
            isDense: true,
          ),
          style: TextStyle(
            fontWeight: isEditing ? FontWeight.w500 : FontWeight.normal,
          ),
          onSubmitted: onSubmitted,
          onEditingComplete: onEditingComplete,
        );
      },
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

