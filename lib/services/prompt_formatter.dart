import 'dart:convert';
import '../models/node.dart';

/// Serviço para formatar nodes em JSON otimizado para LLM
class PromptFormatter {
  /// Formata uma lista de nodes para JSON otimizado para LLM
  /// 
  /// [nodes] - Lista de nodes a serem formatados
  /// [selectedNodeIds] - Set com IDs dos nodes selecionados (para verificar quais filhos incluir)
  /// [includeChildren] - Se true, inclui filhos recursivamente na estrutura children
  /// [indentSize] - Tamanho da indentação (padrão: 2 espaços)
  static String formatNodesForLLM(
    List<Node> nodes, {
    required Set<String> selectedNodeIds,
    bool includeChildren = false,
    int indentSize = 2,
  }) {
    if (nodes.isEmpty) {
      return '[]';
    }

    final List<Map<String, dynamic>> jsonNodes = [];

    for (final node in nodes) {
      jsonNodes.add(_nodeToJson(node, selectedNodeIds, includeChildren));
    }

    final encoder = JsonEncoder.withIndent(' ' * indentSize);
    return encoder.convert(jsonNodes);
  }

  /// Converte um node para JSON
  /// [selectedNodeIds] - Set com IDs dos nodes selecionados
  /// [includeChildren] - Se true, inclui filhos recursivamente. Se false, apenas filhos que estão selecionados
  static Map<String, dynamic> _nodeToJson(
    Node node,
    Set<String> selectedNodeIds,
    bool includeChildren,
  ) {
    final json = <String, dynamic>{
      'id': node.id,
      'name': node.name,
    };

    // Adiciona campos apenas se não estiverem vazios
    if (node.fields.isNotEmpty) {
      // Remove campos null antes de adicionar
      final cleanedFields = Map<String, dynamic>.fromEntries(
        node.fields.entries.where((entry) => entry.value != null),
      );
      if (cleanedFields.isNotEmpty) {
        json['fields'] = cleanedFields;
      }
    }

    // Inclui children apenas se o node tiver filhos e:
    // - includeChildren=true (inclui todos recursivamente), OU
    // - includeChildren=false mas algum filho está selecionado
    if (node.children.isNotEmpty) {
      if (includeChildren) {
        // Inclui filhos recursivamente (simula como se todos estivessem selecionados)
        json['children'] = node.children
            .map((child) => _nodeToJson(child, selectedNodeIds, includeChildren))
            .toList();
      } else {
        // Inclui apenas filhos que estão selecionados
        final selectedChildren = node.children
            .where((child) => selectedNodeIds.contains(child.id))
            .map((child) => _nodeToJson(child, selectedNodeIds, includeChildren))
            .toList();
        
        // Só adiciona children se houver pelo menos um filho selecionado
        if (selectedChildren.isNotEmpty) {
          json['children'] = selectedChildren;
        }
      }
    }

    return json;
  }

  /// Formata nodes em formato "flat" (sem hierarquia de children)
  /// Útil quando se quer apenas os dados dos nodes selecionados, sem estrutura de filhos
  static String formatNodesFlat(List<Node> nodes, {int indentSize = 2}) {
    if (nodes.isEmpty) {
      return '[]';
    }

    final List<Map<String, dynamic>> jsonNodes = [];

    for (final node in nodes) {
      final json = <String, dynamic>{
        'id': node.id,
        'name': node.name,
      };

      // Adiciona campos apenas se não estiverem vazios
      if (node.fields.isNotEmpty) {
        final cleanedFields = Map<String, dynamic>.fromEntries(
          node.fields.entries.where((entry) => entry.value != null),
        );
        if (cleanedFields.isNotEmpty) {
          json['fields'] = cleanedFields;
        }
      }

      // Em formato flat, não inclui children
      jsonNodes.add(json);
    }

    final encoder = JsonEncoder.withIndent(' ' * indentSize);
    return encoder.convert(jsonNodes);
  }
}

