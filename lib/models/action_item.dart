import 'package:flutter/material.dart';

enum ActionCategory {
  keyboard,
  mouse,
  context,
}

class ActionItem {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final String? shortcut;
  final ActionCategory category;
  final bool available;
  final String? condition; // Ex: "Apenas quando editando" ou "Se node tem filhos"

  const ActionItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.shortcut,
    required this.category,
    required this.available,
    this.condition,
  });
}
